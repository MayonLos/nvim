---@class RunnerTerminal
---@field terminals table<string, {win: number, buf: number, job_id: number, start_time: any}>
---@field config table
local M = {}

local cache = require("core.command.runners.cache")

-- Terminal sessions indexed by runner type or custom key
M.terminals = {}

---@class TerminalConfig
---@field width_ratio number
---@field height_ratio number 
---@field border string
---@field focus_on_open boolean
---@field clear_before_run boolean
---@field auto_close_on_success boolean
---@field persist boolean
---@field smart_positioning boolean

M.config = {
	width_ratio = 0.8,
	height_ratio = 0.6,
	border = "rounded",
	focus_on_open = true,
	clear_before_run = true,
	auto_close_on_success = false,
	persist = true, -- Enable terminal persistence
	smart_positioning = true, -- Smart positioning based on editor layout
}

---Get terminal size with caching and smart positioning
---@param smart_position? boolean
---@return table
local function get_terminal_size(smart_position)
	local cache_key = "terminal_size"
	return cache.cache_api_call(cache_key, function()
		local cfg = M.config
		local width = math.floor(vim.o.columns * cfg.width_ratio)
		local height = math.floor(vim.o.lines * cfg.height_ratio)
		
		local col = math.floor((vim.o.columns - width) / 2)
		local row = math.floor((vim.o.lines - height) / 2)
		
		-- Smart positioning based on editor layout
		if smart_position and cfg.smart_positioning then
			-- Check if there are splits and position accordingly
			local winlist = vim.api.nvim_list_wins()
			if #winlist > 1 then
				-- Position to the right if there are vertical splits
				col = math.max(col, math.floor(vim.o.columns * 0.6))
			end
		end
		
		return {
			width = width,
			height = height,
			col = col,
			row = row,
		}
	end)
end

---Close terminal session with proper cleanup
---@param session table
local function close_session(session)
	if session and vim.api.nvim_win_is_valid(session.win) then
		vim.api.nvim_win_close(session.win, true)
	end
end

---Get or create terminal buffer for reuse
---@param key string
---@return number buf
local function get_or_create_terminal_buf(key)
	local existing = M.terminals[key]
	if existing and vim.api.nvim_buf_is_valid(existing.buf) then
		-- Reuse existing buffer
		return existing.buf
	end
	
	-- Create new buffer
	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "hide" -- Keep buffer alive for reuse
	vim.bo[buf].filetype = "coderunner"
	
	return buf
end

---Create or show terminal with buffer reuse
---@param cmd string
---@param runner_name string
---@param key? string Terminal session key for persistence
---@return table|nil
function M.create_terminal(cmd, runner_name, key)
	key = key or runner_name
	
	-- Check if we can reuse existing terminal
	local existing = M.terminals[key]
	if M.config.persist and existing then
		if vim.api.nvim_win_is_valid(existing.win) then
			-- Focus existing terminal
			vim.api.nvim_set_current_win(existing.win)
			if M.config.focus_on_open then
				vim.cmd.startinsert()
			end
			return existing
		elseif vim.api.nvim_buf_is_valid(existing.buf) then
			-- Reopen window for existing buffer
			local size = get_terminal_size(true)
			local win = vim.api.nvim_open_win(existing.buf, M.config.focus_on_open, {
				relative = "editor",
				style = "minimal",
				border = M.config.border,
				width = size.width,
				height = size.height,
				col = size.col,
				row = size.row,
				title = " " .. runner_name .. " (cached) ",
				title_pos = "center",
			})
			
			existing.win = win
			M.setup_terminal_keymaps(existing.buf, existing)
			
			if M.config.focus_on_open then
				vim.cmd.startinsert()
			end
			
			return existing
		end
	end
	
	-- Create new terminal
	local size = get_terminal_size(true)
	local buf = get_or_create_terminal_buf(key)
	
	local win = vim.api.nvim_open_win(buf, M.config.focus_on_open, {
		relative = "editor",
		style = "minimal", 
		border = M.config.border,
		width = size.width,
		height = size.height,
		col = size.col,
		row = size.row,
		title = " " .. runner_name .. " ",
		title_pos = "center",
	})
	
	-- Window options with caching
	cache.cache_api_call("terminal_win_opts", function()
		vim.wo[win].number = false
		vim.wo[win].relativenumber = false
		vim.wo[win].signcolumn = "no"
		return true
	end)
	
	-- Create session
	local session = {
		win = win,
		buf = buf,
		job_id = -1,
		start_time = vim.fn.reltime(),
		runner_name = runner_name,
		key = key,
	}
	
	M.setup_terminal_keymaps(buf, session)
	M.start_job(session, cmd, runner_name)
	
	M.terminals[key] = session
	
	if M.config.focus_on_open then
		vim.cmd.startinsert()
	end
	
	return session
end

---Setup terminal keymaps with proper cleanup
---@param buf number
---@param session table
function M.setup_terminal_keymaps(buf, session)
	local function close_term()
		M.close_terminal(session.key)
	end
	
	-- Use vim.schedule_wrap for async-safe callbacks
	local close_term_wrapped = vim.schedule_wrap(close_term)
	
	for _, key in ipairs { "q", "<Esc>", "<C-c>" } do
		vim.keymap.set({ "n", "t" }, key, close_term_wrapped, {
			buffer = buf,
			silent = true,
			nowait = true,
		})
	end
end

---Start job in terminal session
---@param session table
---@param cmd string
---@param runner_name string
function M.start_job(session, cmd, runner_name)
	-- Prepare command with optional clear
	local full_cmd = M.config.clear_before_run and ("clear; " .. cmd) or cmd
	
	-- Use vim.schedule_wrap for async-safe callbacks
	local on_exit = vim.schedule_wrap(function(_, exit_code)
		local elapsed = vim.fn.reltimestr(vim.fn.reltime(session.start_time))
		
		if exit_code == 0 then
			M.notify(string.format("%s completed in %ss", runner_name, elapsed), vim.log.levels.INFO, "✓")
			if M.config.auto_close_on_success then
				vim.defer_fn(function()
					M.close_terminal(session.key)
				end, 1500)
			end
		else
			M.notify(string.format("%s failed (exit: %d)", runner_name, exit_code), vim.log.levels.ERROR, "✗")
		end
		
		-- Cache the result for future runs
		if session.file_path and session.compile_flags then
			cache.cache_result(session.file_path, session.compile_flags, exit_code == 0)
		end
	end)
	
	-- Start job
	session.job_id = vim.fn.termopen(full_cmd, { on_exit = on_exit })
	
	if session.job_id <= 0 then
		vim.api.nvim_win_close(session.win, true)
		M.notify("Failed to start terminal", vim.log.levels.ERROR, "✗")
		return false
	end
	
	return true
end

---Close specific terminal by key
---@param key string
function M.close_terminal(key)
	local session = M.terminals[key]
	if session then
		close_session(session)
		if M.config.persist then
			-- Keep session for reuse but mark window as closed
			session.win = -1
		else
			M.terminals[key] = nil
		end
	end
end

---Close all terminals
function M.close_all_terminals()
	for key, session in pairs(M.terminals) do
		close_session(session)
		M.terminals[key] = nil
	end
end

---List active terminals
---@return table
function M.list_terminals()
	local active = {}
	for key, session in pairs(M.terminals) do
		if vim.api.nvim_win_is_valid(session.win) then
			table.insert(active, {
				key = key,
				runner_name = session.runner_name,
				job_id = session.job_id,
			})
		end
	end
	return active
end

---Notification function (to be set by main module)
---@param msg string
---@param level number
---@param icon? string
function M.notify(msg, level, icon)
	-- Default implementation, will be overridden
	vim.notify(msg, level)
end

---Update terminal configuration
---@param opts TerminalConfig
function M.setup(opts)
	if opts then
		M.config = vim.tbl_deep_extend("force", M.config, opts)
	end
	
	-- Invalidate cached terminal size when config changes
	cache.invalidate_api_cache("terminal_size")
end

return M