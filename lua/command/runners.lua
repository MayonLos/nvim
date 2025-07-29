---@class CodeRunner
---@field config Config Plugin configuration
---@field runners table<string, Runner> Language runners configuration
---@field _sessions table<number, TerminalSession> Active terminal sessions
local M = {}

-- ========================
-- Type Definitions
-- ========================

---@class Config
---@field terminal TerminalConfig
---@field ui UIConfig
---@field behavior BehaviorConfig
---@field keybindings KeybindingsConfig
---@field compilation CompilationConfig

---@class TerminalConfig
---@field width_ratio number
---@field height_ratio number
---@field max_width number
---@field max_height number
---@field min_width number
---@field min_height number
---@field border string
---@field winblend number
---@field highlight table<string, string>

---@class UIConfig
---@field icons table<string, string>
---@field colors table<string, string>

---@class BehaviorConfig
---@field auto_save boolean
---@field auto_close_on_success boolean
---@field show_notifications boolean
---@field focus_terminal boolean
---@field clear_terminal boolean
---@field save_output boolean

---@class KeybindingsConfig
---@field close_terminal table<string>
---@field toggle_terminal string

---@class CompilationConfig
---@field common_flags table<string>
---@field optimization table<string, table<string>>
---@field mode string

---@class Runner
---@field name string
---@field cmd string
---@field icon string
---@field args function|table
---@field run function|string|nil
---@field compile_first boolean|nil
---@field description string
---@field color string

---@class FileInfo
---@field path string
---@field name string
---@field base string
---@field ext string
---@field dir string
---@field exists boolean
---@field size number

---@class TerminalSession
---@field win number
---@field buf number
---@field job_id number
---@field start_time number
---@field runner Runner

-- ========================
-- Configuration
-- ========================

---@type Config
M.config = {
	terminal = {
		width_ratio = 0.85,
		height_ratio = 0.6,
		max_width = 150,
		max_height = 40,
		min_width = 80,
		min_height = 15,
		border = "rounded",
		winblend = 0,
		highlight = {
			normal = "Normal",
			border = "FloatBorder",
			title = "Title",
		},
	},
	ui = {
		icons = {
			success = "✓",
			error = "✗",
			warning = "⚠",
			info = "ℹ",
			running = "▶",
			compile = "⚙",
			terminal = "▣",
			file = "📄",
			debug = "🐛",
			release = "🚀",
		},
		colors = {
			success = "DiagnosticOk",
			error = "DiagnosticError",
			info = "DiagnosticInfo",
			warn = "DiagnosticWarn",
		},
	},
	behavior = {
		auto_save = true,
		auto_close_on_success = false,
		show_notifications = true,
		focus_terminal = true,
		clear_terminal = true,
		save_output = false,
	},
	keybindings = {
		close_terminal = { "q", "<Esc>", "<C-c>" },
		toggle_terminal = "<C-t>",
	},
	compilation = {
		common_flags = { "-g", "-Wall", "-Wextra" },
		optimization = {
			debug = { "-O0", "-DDEBUG" },
			release = { "-O2", "-DNDEBUG" },
		},
		mode = "debug",
	},
}

---@type table<number, TerminalSession>
M._sessions = {}

-- ========================
-- Utility Functions
-- ========================

---Deep merge two tables
---@param base table
---@param override table
---@return table
local function merge_config(base, override)
	local result = vim.deepcopy(base)
	return vim.tbl_deep_extend("force", result, override)
end

---Safely execute a function with error handling
---@param fn function
---@param error_msg string
---@return boolean success
---@return any result
local function safe_call(fn, error_msg)
	local ok, result = pcall(fn)
	if not ok then
		M._notify(error_msg .. ": " .. tostring(result), vim.log.levels.ERROR)
		return false, nil
	end
	return true, result
end

---Escape shell arguments
---@param args table<string>
---@return table<string>
local function escape_args(args)
	return vim.tbl_map(vim.fn.shellescape, args)
end

---Get terminal dimensions based on configuration
---@return table
local function get_terminal_dimensions()
	local screen_w, screen_h = vim.o.columns, vim.o.lines
	local cfg = M.config.terminal

	local width = math.max(cfg.min_width, math.min(cfg.max_width, math.floor(screen_w * cfg.width_ratio)))
	local height = math.max(cfg.min_height, math.min(cfg.max_height, math.floor(screen_h * cfg.height_ratio)))

	return {
		width = width,
		height = height,
		col = math.floor((screen_w - width) / 2),
		row = math.floor((screen_h - height) / 2),
	}
end

-- ========================
-- Notification System
-- ========================

---Enhanced notification with icon support
---@param message string
---@param level number
---@param icon? string
function M._notify(message, level, icon)
	if not M.config.behavior.show_notifications then
		return
	end

	icon = icon or M.config.ui.icons.info
	local full_message = string.format("%s %s", icon, message)

	-- Try nvim-notify first, fallback to built-in
	local ok, notify_fn = pcall(require, "notify")
	if ok then
		notify_fn(full_message, level, {
			title = "CodeRunner",
			timeout = 3000,
		})
	else
		vim.notify(full_message, level)
	end
end

-- ========================
-- File Operations
-- ========================

---Get comprehensive file information
---@return FileInfo|nil, string?
function M.get_file_info()
	local bufnr = vim.api.nvim_get_current_buf()
	local path = vim.api.nvim_buf_get_name(bufnr)

	if path == "" then
		return nil, "Buffer is not associated with a file"
	end

	local file = {
		path = vim.fn.fnamemodify(path, ":p"),
		name = vim.fn.fnamemodify(path, ":t"),
		base = vim.fn.fnamemodify(path, ":t:r"),
		ext = vim.fn.fnamemodify(path, ":e"):lower(),
		dir = vim.fn.fnamemodify(path, ":p:h"),
	}

	file.exists = vim.fn.filereadable(file.path) == 1
	file.size = file.exists and vim.fn.getfsize(file.path) or 0

	if not file.exists then
		return nil, "File does not exist or is not readable"
	end

	if file.name == "" then
		return nil, "Invalid file name"
	end

	return file
end

-- ========================
-- Terminal Management
-- ========================

---Create a floating terminal window
---@param cmd string Command to execute
---@param runner Runner Runner configuration
---@param opts? table Additional options
---@return TerminalSession|nil
function M._create_terminal(cmd, runner, opts)
	opts = opts or {}
	local dimensions = get_terminal_dimensions()
	local cfg = M.config.terminal

	-- Create buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"
	vim.bo[buf].filetype = "coderunner"
	vim.bo[buf].swapfile = false

	-- Window configuration
	local title = string.format(" %s %s %s ", runner.icon, runner.name, runner.icon)
	local win_config = {
		relative = "editor",
		style = "minimal",
		border = cfg.border,
		width = dimensions.width,
		height = dimensions.height,
		col = dimensions.col,
		row = dimensions.row,
		title = title,
		title_pos = "center",
		zindex = 50,
		noautocmd = true,
	}

	local win = vim.api.nvim_open_win(buf, M.config.behavior.focus_terminal, win_config)

	-- Window options
	local wo = vim.wo[win]
	wo.winblend = cfg.winblend
	wo.winhighlight = string.format(
		"Normal:%s,FloatBorder:%s,FloatTitle:%s",
		cfg.highlight.normal,
		cfg.highlight.border,
		cfg.highlight.title
	)
	wo.number = false
	wo.relativenumber = false
	wo.signcolumn = "no"
	wo.wrap = false

	-- Session object
	local session = {
		win = win,
		buf = buf,
		job_id = -1,
		start_time = vim.fn.reltime(),
		runner = runner,
	}

	-- Key mappings
	local function close_terminal()
		M._close_session(session)
	end

	for _, key in ipairs(M.config.keybindings.close_terminal) do
		vim.keymap.set({ "n", "t" }, key, close_terminal, {
			buffer = buf,
			nowait = true,
			silent = true,
			desc = "Close CodeRunner terminal",
		})
	end

	-- Prepare command
	local full_cmd = M.config.behavior.clear_terminal and ("clear; " .. cmd) or cmd

	-- Start terminal job
	session.job_id = vim.fn.termopen(full_cmd, {
		on_exit = function(_, exit_code)
			vim.schedule(function()
				M._handle_job_exit(session, exit_code)
			end)
		end,
		on_stdout = opts.on_stdout,
		on_stderr = opts.on_stderr,
	})

	if session.job_id <= 0 then
		vim.api.nvim_win_close(win, true)
		M._notify("Failed to start terminal process", vim.log.levels.ERROR, M.config.ui.icons.error)
		return nil
	end

	-- Store session
	M._sessions[session.job_id] = session

	if M.config.behavior.focus_terminal then
		vim.cmd.startinsert()
	end

	return session
end

---Handle job exit
---@param session TerminalSession
---@param exit_code number
function M._handle_job_exit(session, exit_code)
	local success = exit_code == 0
	local elapsed = vim.fn.reltimestr(vim.fn.reltime(session.start_time))
	local runner = session.runner

	-- Clean up session
	M._sessions[session.job_id] = nil

	if success then
		local message = string.format("%s completed in %ss", runner.name, elapsed)
		M._notify(message, vim.log.levels.INFO, M.config.ui.icons.success)

		if M.config.behavior.auto_close_on_success then
			vim.defer_fn(function()
				M._close_session(session)
			end, 2000)
		end
	else
		local message = string.format("%s failed (exit: %d, time: %ss)", runner.name, exit_code, elapsed)
		M._notify(message, vim.log.levels.ERROR, M.config.ui.icons.error)
	end
end

---Close a terminal session
---@param session TerminalSession
function M._close_session(session)
	if vim.api.nvim_win_is_valid(session.win) then
		vim.api.nvim_win_close(session.win, true)
	end
	M._sessions[session.job_id] = nil
end

-- ========================
-- Language Runners
-- ========================

---Generate compilation arguments
---@param file FileInfo
---@param std? string
---@param extra_flags? table<string>
---@return table<string>
local function make_compile_args(file, std, extra_flags)
	local args = { file.name }

	if std then
		table.insert(args, "-std=" .. std)
	end

	-- Add common flags
	vim.list_extend(args, M.config.compilation.common_flags)

	-- Add optimization flags
	local opt_flags = M.config.compilation.optimization[M.config.compilation.mode] or {}
	vim.list_extend(args, opt_flags)

	-- Add extra flags
	if extra_flags then
		vim.list_extend(args, extra_flags)
	end

	-- Output specification
	vim.list_extend(args, { "-o", file.base })

	return args
end

---@type table<string, Runner>
M.runners = {
	-- Systems Programming
	c = {
		name = "C",
		cmd = "gcc",
		icon = "🔧",
		args = function(file)
			return make_compile_args(file, "c17", { "-lm" })
		end,
		run = function(file)
			return "./" .. file.base
		end,
		compile_first = true,
		description = "C (GCC, C17 standard)",
		color = "DiagnosticInfo",
	},

	cpp = {
		name = "C++",
		cmd = "g++",
		icon = "⚡",
		args = function(file)
			return make_compile_args(file, "c++23", { "-lm", "-pthread" })
		end,
		run = function(file)
			return "./" .. file.base
		end,
		compile_first = true,
		description = "C++ (G++, C++23 standard)",
		color = "DiagnosticInfo",
	},

	rs = {
		name = "Rust",
		cmd = "rustc",
		icon = "🦀",
		args = function(file)
			local args = { file.name, "-o", file.base }
			if M.config.compilation.mode == "release" then
				vim.list_extend(args, { "-O" })
			end
			return args
		end,
		run = function(file)
			return "./" .. file.base
		end,
		compile_first = true,
		description = "Rust (rustc)",
		color = "DiagnosticWarn",
	},

	go = {
		name = "Go",
		cmd = "go",
		icon = "🐹",
		args = function(file)
			return { "run", file.name }
		end,
		description = "Go (go run)",
		color = "DiagnosticInfo",
	},

	py = {
		name = "Python",
		cmd = "python3",
		icon = "🐍",
		args = function(file)
			return { file.name }
		end,
		description = "Python 3",
		color = "DiagnosticOk",
	},

	js = {
		name = "JavaScript",
		cmd = "node",
		icon = "🟨",
		args = function(file)
			return { file.name }
		end,
		description = "Node.js",
		color = "DiagnosticWarn",
	},

	ts = {
		name = "TypeScript",
		cmd = "ts-node",
		icon = "🔷",
		args = function(file)
			return { file.name }
		end,
		description = "TypeScript (ts-node)",
		color = "DiagnosticInfo",
	},

	lua = {
		name = "Lua",
		cmd = "lua",
		icon = "🌙",
		args = function(file)
			return { file.name }
		end,
		description = "Lua interpreter",
		color = "DiagnosticInfo",
	},

	java = {
		name = "Java",
		cmd = "javac",
		icon = "☕",
		args = function(file)
			return { file.name }
		end,
		run = function(file)
			return "java " .. file.base
		end,
		compile_first = true,
		description = "Java (javac + java)",
		color = "DiagnosticWarn",
	},

	sh = {
		name = "Shell",
		cmd = "bash",
		icon = "🐚",
		args = function(file)
			return { file.name }
		end,
		description = "Bash shell script",
		color = "DiagnosticInfo",
	},
}

-- ========================
-- Core Functionality
-- ========================

---Compile and run the current file
---@return boolean success
function M.compile_and_run()
	-- Auto-save if configured
	if M.config.behavior.auto_save and vim.bo.modified then
		vim.cmd.write()
		M._notify("File auto-saved", vim.log.levels.INFO, M.config.ui.icons.file)
	end

	-- Get file information
	local file, err = M.get_file_info()
	if not file then
		M._notify(err or "Failed to get file information", vim.log.levels.ERROR, M.config.ui.icons.error)
		return false
	end

	-- Find runner
	local runner = M.runners[file.ext]
	if not runner then
		M._show_supported_languages()
		M._notify(string.format("Unsupported file type: .%s", file.ext), vim.log.levels.ERROR, M.config.ui.icons.error)
		return false
	end

	-- Build command
	local cmd_parts = { "cd", vim.fn.shellescape(file.dir) }

	if runner.compile_first then
		M._notify(string.format("Compiling %s file...", runner.name), vim.log.levels.INFO, M.config.ui.icons.compile)

		vim.list_extend(cmd_parts, { "&&", runner.cmd })
		vim.list_extend(cmd_parts, escape_args(runner.args(file)))

		if runner.run then
			local run_cmd = type(runner.run) == "function" and runner.run(file) or runner.run
			vim.list_extend(cmd_parts, { "&&", run_cmd })
		end
	else
		vim.list_extend(cmd_parts, { "&&", runner.cmd })
		vim.list_extend(cmd_parts, escape_args(runner.args(file)))
	end

	local final_cmd = table.concat(cmd_parts, " ")

	-- Show execution info
	local mode_icon = M.config.compilation.mode == "debug" and M.config.ui.icons.debug or M.config.ui.icons.release
	local info_msg = string.format(
		"Running %s %s (%d bytes) [%s %s]",
		runner.name,
		file.name,
		file.size,
		mode_icon,
		M.config.compilation.mode
	)
	M._notify(info_msg, vim.log.levels.INFO, M.config.ui.icons.running)

	-- Create and launch terminal
	local session = M._create_terminal(final_cmd, runner)
	return session ~= nil
end

---Show supported languages
function M._show_supported_languages()
	local languages = {}
	for ext, runner in pairs(M.runners) do
		table.insert(languages, string.format("%s .%s - %s", runner.icon, ext, runner.description))
	end
	table.sort(languages)

	local message = "Supported Languages:\n" .. table.concat(languages, "\n")
	M._notify(message, vim.log.levels.INFO, M.config.ui.icons.info)
end

---Show plugin information
function M.show_info()
	local file, _ = M.get_file_info()
	local current_runner = file and M.runners[file.ext]

	local info_lines = {
		"CodeRunner Plugin Information",
		"",
		"Current Context:",
		string.format("  File: %s", file and file.name or "No file"),
		string.format("  Runner: %s", current_runner and current_runner.description or "Not supported"),
		string.format("  Size: %s", file and file.size .. " bytes" or "N/A"),
		"",
		"Configuration:",
		string.format("  Mode: %s", M.config.compilation.mode),
		string.format("  Auto-save: %s", M.config.behavior.auto_save and "enabled" or "disabled"),
		string.format("  Auto-focus: %s", M.config.behavior.focus_terminal and "enabled" or "disabled"),
		"",
		"Commands:",
		"  :RunCode - Run current file",
		"  :RunCodeToggleMode - Switch debug/release",
		"  :RunCodeLanguages - Show supported languages",
	}

	M._notify(table.concat(info_lines, "\n"), vim.log.levels.INFO, M.config.ui.icons.info)
end

---Toggle compilation mode
function M.toggle_compilation_mode()
	M.config.compilation.mode = M.config.compilation.mode == "debug" and "release" or "debug"
	local mode_icon = M.config.compilation.mode == "debug" and M.config.ui.icons.debug or M.config.ui.icons.release
	local message = string.format("Compilation mode: %s %s", mode_icon, M.config.compilation.mode)
	M._notify(message, vim.log.levels.INFO, M.config.ui.icons.compile)
end

-- ========================
-- Public API
-- ========================

---Add a custom runner
---@param ext string File extension
---@param runner Runner Runner configuration
function M.add_runner(ext, runner)
	M.runners[ext] = runner
	M._notify(string.format("Added runner for .%s files", ext), vim.log.levels.INFO, M.config.ui.icons.success)
end

---Remove a runner
---@param ext string File extension
function M.remove_runner(ext)
	if M.runners[ext] then
		M.runners[ext] = nil
		M._notify(string.format("Removed runner for .%s files", ext), vim.log.levels.INFO, M.config.ui.icons.info)
	end
end

---Get supported file types
---@return table<string, table>
function M.get_supported_types()
	local types = {}
	for ext, runner in pairs(M.runners) do
		types[ext] = {
			name = runner.name,
			description = runner.description,
			icon = runner.icon,
			color = runner.color,
		}
	end
	return types
end

---Check if runner exists for extension
---@param ext string File extension
---@return boolean
function M.has_runner(ext)
	return M.runners[ext] ~= nil
end

---Get runner for extension
---@param ext string File extension
---@return Runner|nil
function M.get_runner(ext)
	return M.runners[ext]
end

---Setup the plugin
---@param user_config? table User configuration
function M.setup(user_config)
	-- Merge configuration
	if user_config then
		M.config = merge_config(M.config, user_config)
	end

	-- Create commands
	vim.api.nvim_create_user_command("RunCode", M.compile_and_run, {
		desc = "Compile and run current file",
		nargs = 0,
	})

	vim.api.nvim_create_user_command("RunCodeInfo", M.show_info, {
		desc = "Show CodeRunner information",
		nargs = 0,
	})

	vim.api.nvim_create_user_command("RunCodeToggleMode", M.toggle_compilation_mode, {
		desc = "Toggle compilation mode (debug/release)",
		nargs = 0,
	})

	vim.api.nvim_create_user_command("RunCodeLanguages", M._show_supported_languages, {
		desc = "Show supported languages",
		nargs = 0,
	})

	-- Set up keybinding if provided
	if M.config.keymap then
		vim.keymap.set("n", M.config.keymap, M.compile_and_run, {
			desc = "Compile and run current file",
			silent = true,
		})
	end

	-- Create autogroup
	vim.api.nvim_create_augroup("CodeRunner", { clear = true })

	-- -- Success notification
	-- vim.defer_fn(function()
	-- 	M._notify("CodeRunner loaded successfully", vim.log.levels.INFO, M.config.ui.icons.success)
	-- end, 100)
end

return M
