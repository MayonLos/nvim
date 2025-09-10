---@class CodeRunner
local M = {}

-- ========================
-- Constants & Types
-- ========================
local LOG_LEVELS = vim.log.levels
local COMPILE_MODES = { DEBUG = "debug", RELEASE = "release" }
local DEFAULT_ICONS = {
	INFO = "ℹ",
	SUCCESS = "✓",
	ERROR = "✗",
	RUN = "▶",
	SAVE = "💾",
	CONFIG = "⚙",
	LIST = "📋",
}

---@class FileInfo
---@field path string Absolute file path
---@field name string File name with extension
---@field base string File name without extension
---@field ext string File extension (lowercase)
---@field dir string Directory path

---@class Session
---@field win number Window handle
---@field buf number Buffer handle
---@field job_id number Job ID
---@field start_time table Start time
---@field runner_name string Runner name

---@class Runner
---@field name string Display name
---@field cmd fun(file: FileInfo): string Command generator
---@field setup? fun(): boolean Optional setup function

-- ========================
-- Configuration
-- ========================
M.config = {
	terminal = {
		width_ratio = 0.8,
		height_ratio = 0.6,
		border = "rounded",
		focus_on_open = true,
		clear_before_run = true,
		auto_close_on_success = false,
		auto_close_delay = 1500,
		close_keys = { "q", "<Esc>", "<C-c>" },
	},
	behavior = {
		auto_save = true,
		show_notifications = true,
		confirm_unsaved = false,
	},
	compilation = {
		mode = COMPILE_MODES.DEBUG,
		flags = {
			[COMPILE_MODES.DEBUG] = { "-g", "-Wall", "-Wextra", "-O0" },
			[COMPILE_MODES.RELEASE] = { "-O2", "-DNDEBUG" },
		},
	},
	ui = {
		icons = DEFAULT_ICONS,
		title_format = " %s ",
	},
}

-- Session storage
M._sessions = {}

-- ========================
-- Utilities
-- ========================

---Validate configuration
---@param config table
---@return boolean
local function validate_config(config)
	local required_ratios = { "width_ratio", "height_ratio" }
	for _, key in ipairs(required_ratios) do
		local value = config.terminal[key]
		if value and (type(value) ~= "number" or value <= 0 or value > 1) then
			vim.notify(("Invalid %s: must be between 0 and 1"):format(key), LOG_LEVELS.ERROR)
			return false
		end
	end
	return true
end

---Send notification with consistent formatting
---@param msg string
---@param level number
---@param icon? string
local function notify(msg, level, icon)
	if not M.config.behavior.show_notifications then
		return
	end
	icon = icon or M.config.ui.icons.INFO
	local message = ("%s %s"):format(icon, msg)
	local ok, notify_fn = pcall(require, "notify")
	if ok then
		notify_fn(message, level, { title = "CodeRunner" })
	else
		vim.notify(message, level)
	end
end

---Get file information from current buffer
---@return FileInfo|nil, string|nil
local function get_file_info()
	local path = vim.api.nvim_buf_get_name(0)
	if path == "" then
		return nil, "Buffer not associated with file"
	end
	local file = {
		path = vim.fn.fnamemodify(path, ":p"),
		name = vim.fn.fnamemodify(path, ":t"),
		base = vim.fn.fnamemodify(path, ":t:r"),
		ext = vim.fn.fnamemodify(path, ":e"):lower(),
		dir = vim.fn.fnamemodify(path, ":p:h"),
	}
	if vim.fn.filereadable(file.path) ~= 1 then
		return nil, ("File not readable: %s"):format(file.path)
	end
	if file.name == "" then
		return nil, "Invalid file name"
	end
	return file
end

---Calculate terminal dimensions
---@return table
local function get_terminal_size()
	local cfg = M.config.terminal
	local width = math.floor(vim.o.columns * cfg.width_ratio)
	local height = math.floor(vim.o.lines * cfg.height_ratio)
	width = math.max(width, 40)
	height = math.max(height, 10)
	return {
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
	}
end

---Check if buffer is modified and handle accordingly
---@return boolean success
local function handle_buffer_save()
	if not vim.bo.modified then
		return true
	end
	if M.config.behavior.auto_save then
		local ok, err = pcall(vim.cmd.write)
		if ok then
			notify("File auto-saved", LOG_LEVELS.INFO, M.config.ui.icons.SAVE)
			return true
		else
			notify(
				("Failed to auto-save: %s"):format(err or "unknown"),
				LOG_LEVELS.ERROR,
				M.config.ui.icons.ERROR
			)
			return false
		end
	elseif M.config.behavior.confirm_unsaved then
		local choice = vim.fn.confirm(
			"File has unsaved changes. Save before running?",
			"&Yes\n&No\n&Cancel",
			1
		)
		if choice == 1 then -- Yes
			local ok, err = pcall(vim.cmd.write)
			if not ok then
				notify(
					("Failed to save: %s"):format(err or "unknown"),
					LOG_LEVELS.ERROR,
					M.config.ui.icons.ERROR
				)
				return false
			end
			return true
		elseif choice == 3 then -- Cancel
			return false
		end
		-- choice == 2 (No) continues without saving
	end
	return true
end

-- ========================
-- Terminal Management
-- ========================

---Close a terminal session
---@param session Session
local function close_session(session)
	if not session then
		return
	end
	if session.win and vim.api.nvim_win_is_valid(session.win) then
		vim.api.nvim_win_close(session.win, true)
	end
	if session.job_id then
		M._sessions[session.job_id] = nil
	end
end

---Setup terminal buffer keymaps
---@param buf number
---@param session Session
local function setup_terminal_keymaps(buf, session)
	local close_term = function()
		close_session(session)
	end
	for _, key in ipairs(M.config.terminal.close_keys) do
		vim.keymap.set({ "n", "t" }, key, close_term, {
			buffer = buf,
			silent = true,
			nowait = true,
			desc = "Close CodeRunner terminal",
		})
	end
end

---Create and configure terminal window
---@param cmd string
---@param runner_name string
---@return Session|nil
local function create_terminal(cmd, runner_name)
	local size = get_terminal_size()
	local cfg = M.config.terminal

	local buf = vim.api.nvim_create_buf(false, true)
	if buf == 0 then
		notify("Failed to create buffer", LOG_LEVELS.ERROR, M.config.ui.icons.ERROR)
		return nil
	end

	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "coderunner"
	vim.bo[buf].swapfile = false

	local title = M.config.ui.title_format:format(runner_name)
	local win_opts = {
		relative = "editor",
		style = "minimal",
		border = cfg.border,
		width = size.width,
		height = size.height,
		col = size.col,
		row = size.row,
		title = title,
		title_pos = "center",
		zindex = 100,
	}

	local win = vim.api.nvim_open_win(buf, cfg.focus_on_open, win_opts)
	if win == 0 then
		vim.api.nvim_buf_delete(buf, { force = true })
		notify("Failed to create terminal window", LOG_LEVELS.ERROR, M.config.ui.icons.ERROR)
		return nil
	end

	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"
	vim.wo[win].spell = false
	vim.wo[win].wrap = true

	local session = {
		win = win,
		buf = buf,
		job_id = -1,
		start_time = vim.fn.reltime(),
		runner_name = runner_name,
	}

	setup_terminal_keymaps(buf, session)

	local full_cmd = cfg.clear_before_run and ("clear && %s"):format(cmd) or cmd

	session.job_id = vim.fn.termopen(full_cmd, {
		cwd = vim.fn.getcwd(),
		on_exit = function(job_id, exit_code)
			vim.schedule(function()
				local elapsed = tonumber(vim.fn.reltimestr(vim.fn.reltime(session.start_time)))
				M._sessions[job_id] = nil
				local icon = M.config.ui.icons
				if exit_code == 0 then
					notify(
						("%s completed in %.2fs"):format(runner_name, elapsed),
						LOG_LEVELS.INFO,
						icon.SUCCESS
					)
					if cfg.auto_close_on_success then
						vim.defer_fn(function()
							close_session(session)
						end, cfg.auto_close_delay)
					end
				else
					notify(
						("%s failed (exit %d) in %.2fs"):format(runner_name, exit_code, elapsed),
						LOG_LEVELS.ERROR,
						icon.ERROR
					)
				end
			end)
		end,
	})

	if session.job_id <= 0 then
		close_session(session)
		notify("Failed to start terminal process", LOG_LEVELS.ERROR, M.config.ui.icons.ERROR)
		return nil
	end

	M._sessions[session.job_id] = session

	if cfg.focus_on_open then
		vim.cmd.startinsert()
	end

	return session
end

-- ========================
-- Language Runners
-- ========================

---Get compilation flags for current mode
---@return table
local function get_compile_flags()
	return M.config.compilation.flags[M.config.compilation.mode] or {}
end

---Escape shell argument
---@param arg string
---@return string
local function shell_escape(arg)
	return vim.fn.shellescape(arg)
end

M.runners = {
	c = {
		name = "C",
		cmd = function(file)
			local flags = table.concat(get_compile_flags(), " ")
			local output = file.base
			local compile_cmd = ("gcc %s %s -o %s"):format(
				flags,
				shell_escape(file.name),
				shell_escape(output)
			)
			return ("%s && ./%s"):format(compile_cmd, output)
		end,
	},
	cpp = {
		name = "C++",
		cmd = function(file)
			local flags = table.concat(get_compile_flags(), " ")
			local output = file.base
			local compile_cmd = ("g++ -std=c++20 %s %s -o %s"):format(
				flags,
				shell_escape(file.name),
				shell_escape(output)
			)
			return ("%s && ./%s"):format(compile_cmd, output)
		end,
	},
	rs = {
		name = "Rust",
		cmd = function(file)
			local opt_flag = M.config.compilation.mode == COMPILE_MODES.RELEASE and "-O" or ""
			local output = file.base
			local compile_cmd = ("rustc %s %s -o %s"):format(
				opt_flag,
				shell_escape(file.name),
				shell_escape(output)
			)
			return ("%s && ./%s"):format(compile_cmd, output)
		end,
	},
	go = {
		name = "Go",
		cmd = function(file)
			return ("go run %s"):format(shell_escape(file.name))
		end,
	},
	py = {
		name = "Python",
		cmd = function(file)
			local python = vim.fn.executable("python3") == 1 and "python3" or "python"
			return ("%s %s"):format(python, shell_escape(file.name))
		end,
	},
	js = {
		name = "JavaScript",
		cmd = function(file)
			return ("node %s"):format(shell_escape(file.name))
		end,
		setup = function()
			return vim.fn.executable("node") == 1
		end,
	},
	ts = {
		name = "TypeScript",
		cmd = function(file)
			return ("ts-node %s"):format(shell_escape(file.name))
		end,
		setup = function()
			return vim.fn.executable("ts-node") == 1
		end,
	},
	lua = {
		name = "Lua",
		cmd = function(file)
			return ("lua %s"):format(shell_escape(file.name))
		end,
	},
	java = {
		name = "Java",
		cmd = function(file)
			local compile_cmd = ("javac %s"):format(shell_escape(file.name))
			local run_cmd = ("java %s"):format(shell_escape(file.base))
			return ("%s && %s"):format(compile_cmd, run_cmd)
		end,
	},
	sh = {
		name = "Shell Script",
		cmd = function(file)
			return ("bash %s"):format(shell_escape(file.name))
		end,
	},
	zsh = {
		name = "Zsh Script",
		cmd = function(file)
			return ("zsh %s"):format(shell_escape(file.name))
		end,
	},
	rb = {
		name = "Ruby",
		cmd = function(file)
			return ("ruby %s"):format(shell_escape(file.name))
		end,
		setup = function()
			return vim.fn.executable("ruby") == 1
		end,
	},
	php = {
		name = "PHP",
		cmd = function(file)
			return ("php %s"):format(shell_escape(file.name))
		end,
		setup = function()
			return vim.fn.executable("php") == 1
		end,
	},
}

-- ========================
-- Core Functions
-- ========================

---Run code for current buffer
---@return boolean success
function M.run_code()
	if not handle_buffer_save() then
		return false
	end

	local file, err = get_file_info()
	if not file then
		notify(err, LOG_LEVELS.ERROR, M.config.ui.icons.ERROR)
		return false
	end

	local runner = M.runners[file.ext]
	if not runner then
		notify(
			("Unsupported file type: .%s"):format(file.ext),
			LOG_LEVELS.ERROR,
			M.config.ui.icons.ERROR
		)
		M.show_supported_languages()
		return false
	end

	if runner.setup and not runner.setup() then
		notify(
			("%s environment not properly set up"):format(runner.name),
			LOG_LEVELS.ERROR,
			M.config.ui.icons.ERROR
		)
		return false
	end

	local ok, cmd = pcall(runner.cmd, file)
	if not ok then
		notify(
			("Failed to build command for %s: %s"):format(runner.name, cmd),
			LOG_LEVELS.ERROR,
			M.config.ui.icons.ERROR
		)
		return false
	end

	local full_cmd = ("cd %s && %s"):format(shell_escape(file.dir), cmd)

	local mode_icon = M.config.compilation.mode == COMPILE_MODES.DEBUG and "🐛" or "🚀"
	notify(
		("Running %s [%s %s]"):format(file.name, mode_icon, M.config.compilation.mode),
		LOG_LEVELS.INFO,
		M.config.ui.icons.RUN
	)

	return create_terminal(full_cmd, runner.name) ~= nil
end

---Toggle compilation mode between debug and release
function M.toggle_mode()
	local new_mode = M.config.compilation.mode == COMPILE_MODES.DEBUG and COMPILE_MODES.RELEASE
		or COMPILE_MODES.DEBUG
	M.config.compilation.mode = new_mode
	local icon = new_mode == COMPILE_MODES.DEBUG and "🐛" or "🚀"
	notify(
		("Compilation mode: %s %s"):format(icon, new_mode),
		LOG_LEVELS.INFO,
		M.config.ui.icons.CONFIG
	)
end

---Show supported programming languages
function M.show_supported_languages()
	local languages = {}
	for ext, runner in pairs(M.runners) do
		local status = runner.setup and not runner.setup() and " (not available)" or ""
		table.insert(languages, (".%s → %s%s"):format(ext, runner.name, status))
	end
	table.sort(languages)
	local message = "Supported languages:\n" .. table.concat(languages, "\n")
	notify(message, LOG_LEVELS.INFO, M.config.ui.icons.LIST)
end

---Add or update a language runner
---@param ext string File extension
---@param runner Runner Runner configuration
function M.add_runner(ext, runner)
	if type(ext) ~= "string" or type(runner) ~= "table" then
		notify("Invalid runner configuration", LOG_LEVELS.ERROR, M.config.ui.icons.ERROR)
		return false
	end
	if not runner.name or not runner.cmd or type(runner.cmd) ~= "function" then
		notify("Runner must have name and cmd function", LOG_LEVELS.ERROR, M.config.ui.icons.ERROR)
		return false
	end
	M.runners[ext] = runner
	notify(
		("Added runner for .%s (%s)"):format(ext, runner.name),
		LOG_LEVELS.INFO,
		M.config.ui.icons.SUCCESS
	)
	return true
end

---Close all active terminal sessions
function M.close_all_terminals()
	local count = 0
	for _, session in pairs(M._sessions) do
		close_session(session)
		count = count + 1
	end
	if count > 0 then
		notify(("Closed %d terminal(s)"):format(count), LOG_LEVELS.INFO, M.config.ui.icons.SUCCESS)
	end
end

---Get current status information
---@return table
function M.get_status()
	return {
		mode = M.config.compilation.mode,
		active_sessions = vim.tbl_count(M._sessions),
		supported_languages = vim.tbl_count(M.runners),
	}
end

-- ========================
-- Setup & Commands
-- ========================

---Setup the CodeRunner plugin
---@param opts? table Optional configuration
function M.setup(opts)
	if opts then
		if not validate_config(opts) then
			return
		end
		M.config = vim.tbl_deep_extend("force", M.config, opts)
	end

	local commands = {
		{ "RunCode", M.run_code, { desc = "Run code in current buffer" } },
		{ "RunCodeToggle", M.toggle_mode, { desc = "Toggle compilation mode (debug/release)" } },
		{
			"RunCodeLanguages",
			M.show_supported_languages,
			{ desc = "Show supported programming languages" },
		},
		{ "RunCodeClose", M.close_all_terminals, { desc = "Close all CodeRunner terminals" } },
		{
			"RunCodeStatus",
			function()
				local status = M.get_status()
				notify(
					("Mode: %s | Active: %d | Languages: %d"):format(
						status.mode,
						status.active_sessions,
						status.supported_languages
					),
					LOG_LEVELS.INFO,
					M.config.ui.icons.INFO
				)
			end,
			{ desc = "Show CodeRunner status" },
		},
	}

	for _, cmd in ipairs(commands) do
		vim.api.nvim_create_user_command(cmd[1], cmd[2], cmd[3])
	end

	if opts and opts.keymap then
		local keymap_opts = { desc = "Run current file", silent = true, noremap = true }
		if type(opts.keymap) == "string" then
			vim.keymap.set("n", opts.keymap, M.run_code, keymap_opts)
		elseif type(opts.keymap) == "table" then
			for _, key in ipairs(opts.keymap) do
				vim.keymap.set("n", key, M.run_code, keymap_opts)
			end
		end
	end

	local augroup = vim.api.nvim_create_augroup("CodeRunner", { clear = true })

	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = augroup,
		callback = M.close_all_terminals,
		desc = "Clean up CodeRunner sessions on exit",
	})

	vim.api.nvim_create_autocmd("BufDelete", {
		group = augroup,
		callback = function()
			for job_id, session in pairs(M._sessions) do
				if not vim.api.nvim_win_is_valid(session.win) then
					M._sessions[job_id] = nil
				end
			end
		end,
		desc = "Clean up orphaned CodeRunner sessions",
	})
end

return M
