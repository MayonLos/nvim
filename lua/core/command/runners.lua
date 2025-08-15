---@class CodeRunner
local M = {}

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
	},
	behavior = {
		auto_save = true,
		show_notifications = true,
	},
	compilation = {
		mode = "debug", -- debug | release
		flags = {
			debug = { "-g", "-Wall", "-Wextra", "-O0" },
			release = { "-O2", "-DNDEBUG" },
		},
	},
}

M._sessions = {}

-- ========================
-- Utilities
-- ========================

local function notify(msg, level, icon)
	if not M.config.behavior.show_notifications then
		return
	end

	icon = icon or "ℹ"
	local message = string.format("%s %s", icon, msg)

	local ok, notify_fn = pcall(require, "notify")
	if ok then
		notify_fn(message, level, { title = "CodeRunner" })
	else
		vim.notify(message, level)
	end
end

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
		return nil, "File not readable"
	end

	return file
end

local function get_terminal_size()
	local cfg = M.config.terminal
	local width = math.floor(vim.o.columns * cfg.width_ratio)
	local height = math.floor(vim.o.lines * cfg.height_ratio)

	return {
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
	}
end

-- ========================
-- Terminal Management
-- ========================

local function close_session(session)
	if session and vim.api.nvim_win_is_valid(session.win) then
		vim.api.nvim_win_close(session.win, true)
	end
	M._sessions[session.job_id] = nil
end

local function create_terminal(cmd, runner_name)
	local size = get_terminal_size()
	local cfg = M.config.terminal

	-- Create buffer and window
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "coderunner"

	local win = vim.api.nvim_open_win(buf, cfg.focus_on_open, {
		relative = "editor",
		style = "minimal",
		border = cfg.border,
		width = size.width,
		height = size.height,
		col = size.col,
		row = size.row,
		title = " " .. runner_name .. " ",
		title_pos = "center",
	})

	-- Window options
	vim.wo[win].number = false
	vim.wo[win].relativenumber = false
	vim.wo[win].signcolumn = "no"

	-- Session
	local session = {
		win = win,
		buf = buf,
		job_id = -1,
		start_time = vim.fn.reltime(),
	}

	-- Key mappings to close terminal
	local function close_term()
		close_session(session)
	end

	for _, key in ipairs { "q", "<Esc>", "<C-c>" } do
		vim.keymap.set({ "n", "t" }, key, close_term, {
			buffer = buf,
			silent = true,
			nowait = true,
		})
	end

	-- Prepare command
	local full_cmd = cfg.clear_before_run and ("clear; " .. cmd) or cmd

	-- Start job
	session.job_id = vim.fn.termopen(full_cmd, {
		on_exit = function(_, exit_code)
			vim.schedule(function()
				local elapsed = vim.fn.reltimestr(vim.fn.reltime(session.start_time))
				M._sessions[session.job_id] = nil

				if exit_code == 0 then
					notify(string.format("%s completed in %ss", runner_name, elapsed), vim.log.levels.INFO, "✓")
					if cfg.auto_close_on_success then
						vim.defer_fn(function()
							close_session(session)
						end, 1500)
					end
				else
					notify(string.format("%s failed (exit: %d)", runner_name, exit_code), vim.log.levels.ERROR, "✗")
				end
			end)
		end,
	})

	if session.job_id <= 0 then
		vim.api.nvim_win_close(win, true)
		notify("Failed to start terminal", vim.log.levels.ERROR, "✗")
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

local function get_compile_flags()
	return M.config.compilation.flags[M.config.compilation.mode] or {}
end

M.runners = {
	c = {
		name = "C",
		cmd = function(file)
			local flags = get_compile_flags()
			local compile_cmd = string.format("gcc %s %s -o %s", table.concat(flags, " "), file.name, file.base)
			return string.format("%s && ./%s", compile_cmd, file.base)
		end,
	},

	cpp = {
		name = "C++",
		cmd = function(file)
			local flags = get_compile_flags()
			local compile_cmd =
				string.format("g++ -std=c++20 %s %s -o %s", table.concat(flags, " "), file.name, file.base)
			return string.format("%s && ./%s", compile_cmd, file.base)
		end,
	},

	rs = {
		name = "Rust",
		cmd = function(file)
			local opt_flag = M.config.compilation.mode == "release" and "-O" or ""
			local compile_cmd = string.format("rustc %s %s -o %s", opt_flag, file.name, file.base)
			return string.format("%s && ./%s", compile_cmd, file.base)
		end,
	},

	go = {
		name = "Go",
		cmd = function(file)
			return string.format("go run %s", file.name)
		end,
	},

	py = {
		name = "Python",
		cmd = function(file)
			return string.format("python3 %s", file.name)
		end,
	},

	js = {
		name = "JavaScript",
		cmd = function(file)
			return string.format("node %s", file.name)
		end,
	},

	ts = {
		name = "TypeScript",
		cmd = function(file)
			return string.format("ts-node %s", file.name)
		end,
	},

	lua = {
		name = "Lua",
		cmd = function(file)
			return string.format("lua %s", file.name)
		end,
	},

	java = {
		name = "Java",
		cmd = function(file)
			local compile_cmd = string.format("javac %s", file.name)
			local run_cmd = string.format("java %s", file.base)
			return string.format("%s && %s", compile_cmd, run_cmd)
		end,
	},

	sh = {
		name = "Shell",
		cmd = function(file)
			return string.format("bash %s", file.name)
		end,
	},
}

-- ========================
-- Core Functions
-- ========================

function M.run_code()
	-- Auto save
	if M.config.behavior.auto_save and vim.bo.modified then
		vim.cmd.write()
		notify("File auto-saved", vim.log.levels.INFO, "💾")
	end

	-- Get file info
	local file, err = get_file_info()
	if not file then
		notify(err, vim.log.levels.ERROR, "✗")
		return false
	end

	-- Find runner
	local runner = M.runners[file.ext]
	if not runner then
		notify(string.format("Unsupported file type: .%s", file.ext), vim.log.levels.ERROR, "✗")
		M.show_supported_languages()
		return false
	end

	-- Build command
	local cmd = string.format("cd %s && %s", vim.fn.shellescape(file.dir), runner.cmd(file))

	-- Show info
	local mode_icon = M.config.compilation.mode == "debug" and "🐛" or "🚀"
	notify(
		string.format("Running %s [%s %s]", file.name, mode_icon, M.config.compilation.mode),
		vim.log.levels.INFO,
		"▶"
	)

	-- Create terminal
	return create_terminal(cmd, runner.name) ~= nil
end

function M.toggle_mode()
	M.config.compilation.mode = M.config.compilation.mode == "debug" and "release" or "debug"
	local icon = M.config.compilation.mode == "debug" and "🐛" or "🚀"
	notify(string.format("Mode: %s %s", icon, M.config.compilation.mode), vim.log.levels.INFO, "⚙")
end

function M.show_supported_languages()
	local languages = {}
	for ext, runner in pairs(M.runners) do
		table.insert(languages, string.format(".%s - %s", ext, runner.name))
	end
	table.sort(languages)

	notify("Supported: " .. table.concat(languages, ", "), vim.log.levels.INFO, "📋")
end

function M.add_runner(ext, runner)
	M.runners[ext] = runner
	notify(string.format("Added runner for .%s", ext), vim.log.levels.INFO, "✓")
end

-- ========================
-- Setup
-- ========================

function M.setup(opts)
	-- Merge config
	if opts then
		M.config = vim.tbl_deep_extend("force", M.config, opts)
	end

	-- Commands
	vim.api.nvim_create_user_command("RunCode", M.run_code, { desc = "Run current file" })
	vim.api.nvim_create_user_command("RunCodeToggle", M.toggle_mode, { desc = "Toggle debug/release mode" })
	vim.api.nvim_create_user_command(
		"RunCodeLanguages",
		M.show_supported_languages,
		{ desc = "Show supported languages" }
	)

	-- Keymap
	if opts and opts.keymap then
		vim.keymap.set("n", opts.keymap, M.run_code, { desc = "Run current file", silent = true })
	end

	-- Autogroup for cleanup
	vim.api.nvim_create_augroup("CodeRunner", { clear = true })
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = "CodeRunner",
		callback = function()
			for _, session in pairs(M._sessions) do
				close_session(session)
			end
		end,
	})
end

return M
