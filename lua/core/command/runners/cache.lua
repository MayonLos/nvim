---@class RunnerCache
---@field api_cache table<string, any>
---@field result_cache table<string, {hash: string, success: boolean, timestamp: number}>
local M = {}

-- Cache for frequently accessed vim API calls
M.api_cache = {}

-- Cache for compilation results to avoid recompiling unchanged files
M.result_cache = {}

-- Cache TTL in seconds (5 minutes for results, API cache never expires in session)
M.RESULT_TTL = 300

---Cache a vim API call result
---@param key string
---@param fn function
---@return any
function M.cache_api_call(key, fn)
	if M.api_cache[key] == nil then
		M.api_cache[key] = fn()
	end
	return M.api_cache[key]
end

---Invalidate API cache entry
---@param key string
function M.invalidate_api_cache(key)
	M.api_cache[key] = nil
end

---Clear all API cache
function M.clear_api_cache()
	M.api_cache = {}
end

---Get file hash for caching compilation results
---@param file_path string
---@return string|nil
local function get_file_hash(file_path)
	local stat = vim.loop.fs_stat(file_path)
	if not stat then
		return nil
	end
	-- Use modification time and size as a simple hash
	return string.format("%d_%d", stat.mtime.sec, stat.size)
end

---Check if compilation result is cached and valid
---@param file_path string
---@param compile_flags? table
---@return boolean success, boolean cached
function M.get_cached_result(file_path, compile_flags)
	local hash = get_file_hash(file_path)
	if not hash then
		return false, false
	end
	
	-- Create cache key including compile flags
	local flags_str = compile_flags and table.concat(compile_flags, " ") or ""
	local cache_key = file_path .. ":" .. flags_str
	
	local cached = M.result_cache[cache_key]
	if not cached then
		return false, false
	end
	
	-- Check if cache is still valid
	local now = os.time()
	if cached.hash ~= hash or (now - cached.timestamp) > M.RESULT_TTL then
		M.result_cache[cache_key] = nil
		return false, false
	end
	
	return cached.success, true
end

---Cache compilation result
---@param file_path string
---@param compile_flags? table
---@param success boolean
function M.cache_result(file_path, compile_flags, success)
	local hash = get_file_hash(file_path)
	if not hash then
		return
	end
	
	local flags_str = compile_flags and table.concat(compile_flags, " ") or ""
	local cache_key = file_path .. ":" .. flags_str
	
	M.result_cache[cache_key] = {
		hash = hash,
		success = success,
		timestamp = os.time(),
	}
end

---Clear expired results from cache
function M.cleanup_cache()
	local now = os.time()
	for key, cached in pairs(M.result_cache) do
		if (now - cached.timestamp) > M.RESULT_TTL then
			M.result_cache[key] = nil
		end
	end
end

---Get cache statistics
---@return table
function M.get_stats()
	local api_count = 0
	local result_count = 0
	
	for _ in pairs(M.api_cache) do
		api_count = api_count + 1
	end
	
	for _ in pairs(M.result_cache) do
		result_count = result_count + 1
	end
	
	return {
		api_calls_cached = api_count,
		results_cached = result_count,
	}
end

return M