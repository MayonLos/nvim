---@class RunnerUtils
local M = {}

local cache = require("core.command.runners.cache")

---Cached notification function
---@param msg string
---@param level number
---@param icon? string
---@param title? string
function M.notify(msg, level, icon, title)
	icon = icon or "ℹ"
	title = title or "CodeRunner"
	local message = string.format("%s %s", icon, msg)
	
	-- Use cached check for notify plugin availability
	local notify_fn = cache.cache_api_call("notify_plugin", function()
		local ok, notify = pcall(require, "notify")
		return ok and notify or nil
	end)
	
	if notify_fn then
		notify_fn(message, level, { title = title })
	else
		vim.notify(message, level)
	end
end

---Get file information with caching for repeated calls
---@return table|nil file, string? error
function M.get_file_info()
	local buf_name = vim.api.nvim_buf_get_name(0)
	if buf_name == "" then
		return nil, "Buffer not associated with file"
	end
	
	-- Cache file info for the current buffer to avoid repeated filesystem calls
	local cache_key = "file_info_" .. buf_name
	return cache.cache_api_call(cache_key, function()
		local file = {
			path = vim.fn.fnamemodify(buf_name, ":p"),
			name = vim.fn.fnamemodify(buf_name, ":t"),
			base = vim.fn.fnamemodify(buf_name, ":t:r"),
			ext = vim.fn.fnamemodify(buf_name, ":e"):lower(),
			dir = vim.fn.fnamemodify(buf_name, ":p:h"),
		}
		
		if vim.fn.filereadable(file.path) ~= 1 then
			return nil, "File not readable"
		end
		
		return file
	end), nil
end

---Invalidate file info cache (call when buffer changes)
function M.invalidate_file_info()
	local buf_name = vim.api.nvim_buf_get_name(0)
	local cache_key = "file_info_" .. buf_name
	cache.invalidate_api_cache(cache_key)
end

---Execute with proper error handling
---@param fn function
---@param error_msg? string
---@return boolean success, any result
function M.safe_call(fn, error_msg)
	local ok, result = pcall(fn)
	if not ok then
		local msg = error_msg or "Operation failed"
		M.notify(string.format("%s: %s", msg, result), vim.log.levels.ERROR, "✗")
		return false, result
	end
	return true, result
end

---Debounced function execution to avoid excessive calls
---@param fn function
---@param delay number
---@param key string
---@return function
function M.debounce(fn, delay, key)
	local timer_key = "debounce_" .. key
	
	return function(...)
		local args = { ... }
		
		-- Cancel existing timer
		if M._debounce_timers and M._debounce_timers[timer_key] then
			M._debounce_timers[timer_key]:stop()
			M._debounce_timers[timer_key]:close()
		end
		
		-- Initialize timers table if needed
		if not M._debounce_timers then
			M._debounce_timers = {}
		end
		
		-- Create new timer
		M._debounce_timers[timer_key] = vim.loop.new_timer()
		M._debounce_timers[timer_key]:start(delay, 0, vim.schedule_wrap(function()
			fn(unpack(args))
			M._debounce_timers[timer_key]:close()
			M._debounce_timers[timer_key] = nil
		end))
	end
end

---Throttled function execution to limit call frequency
---@param fn function
---@param delay number
---@param key string
---@return function
function M.throttle(fn, delay, key)
	local last_call_key = "throttle_last_" .. key
	
	return function(...)
		local now = vim.loop.hrtime()
		local last_call = M._throttle_last and M._throttle_last[last_call_key] or 0
		
		if (now - last_call) >= (delay * 1000000) then -- Convert ms to nanoseconds
			if not M._throttle_last then
				M._throttle_last = {}
			end
			M._throttle_last[last_call_key] = now
			fn(...)
		end
	end
end

---Measure execution time of a function
---@param fn function
---@param name string
---@return any result, number time_ms
function M.measure_time(fn, name)
	local start_time = vim.fn.reltime()
	local result = fn()
	local elapsed = vim.fn.reltimefloat(vim.fn.reltime(start_time)) * 1000
	
	if name then
		M.notify(string.format("%s took %.2fms", name, elapsed), vim.log.levels.DEBUG, "⏱")
	end
	
	return result, elapsed
end

---Async wrapper for potentially blocking operations
---@param fn function
---@param callback? function
function M.async_call(fn, callback)
	vim.schedule(function()
		local success, result = M.safe_call(fn)
		if callback then
			vim.schedule_wrap(callback)(success, result)
		end
	end)
end

---Get project root directory with caching
---@return string
function M.get_project_root()
	return cache.cache_api_call("project_root", function()
		-- Look for common project markers
		local markers = { ".git", "package.json", "Cargo.toml", "go.mod", "CMakeLists.txt" }
		local current_dir = vim.fn.expand("%:p:h")
		
		-- Walk up the directory tree
		local function find_root(path)
			for _, marker in ipairs(markers) do
				if vim.fn.isdirectory(path .. "/" .. marker) == 1 or vim.fn.filereadable(path .. "/" .. marker) == 1 then
					return path
				end
			end
			
			local parent = vim.fn.fnamemodify(path, ":h")
			if parent == path then
				return nil -- Reached filesystem root
			end
			
			return find_root(parent)
		end
		
		return find_root(current_dir) or vim.fn.getcwd()
	end)
end

---Escape shell command arguments
---@param arg string
---@return string
function M.shell_escape(arg)
	return vim.fn.shellescape(arg)
end

---Split string with optimized table reuse
---@param str string
---@param delimiter string
---@return table
function M.split(str, delimiter)
	local result = {}
	local start = 1
	local pos
	
	while true do
		pos = string.find(str, delimiter, start, true)
		if not pos then
			result[#result + 1] = string.sub(str, start)
			break
		end
		
		result[#result + 1] = string.sub(str, start, pos - 1)
		start = pos + #delimiter
	end
	
	return result
end

---Join table elements into string with minimal allocations
---@param tbl table
---@param delimiter string
---@return string
function M.join(tbl, delimiter)
	if #tbl == 0 then
		return ""
	end
	if #tbl == 1 then
		return tostring(tbl[1])
	end
	
	return table.concat(tbl, delimiter)
end

---Check if file exists with caching
---@param filepath string
---@return boolean
function M.file_exists(filepath)
	local cache_key = "file_exists_" .. filepath
	return cache.cache_api_call(cache_key, function()
		return vim.fn.filereadable(filepath) == 1
	end)
end

---Get file modification time for change detection
---@param filepath string
---@return number|nil
function M.get_file_mtime(filepath)
	local stat = vim.loop.fs_stat(filepath)
	return stat and stat.mtime.sec or nil
end

---Cleanup resources on module unload
function M.cleanup()
	-- Stop all debounce timers
	if M._debounce_timers then
		for _, timer in pairs(M._debounce_timers) do
			if timer and not timer:is_closing() then
				timer:stop()
				timer:close()
			end
		end
		M._debounce_timers = {}
	end
	
	-- Clear throttle data
	M._throttle_last = {}
	
	-- Clear caches
	cache.clear_api_cache()
end

return M