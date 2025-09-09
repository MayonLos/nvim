---@class AsyncCompiler
local M = {}

local utils = require("core.command.runners.utils")
local cache = require("core.command.runners.cache")

-- Track active async compilations
M.active_compilations = {}

---@class CompilationTask
---@field file table
---@field command string
---@field runner_name string
---@field project_root string
---@field start_time any
---@field timeout number
---@field on_complete function
---@field on_progress? function
---@field job_id number

---Start async compilation
---@param task CompilationTask
---@return boolean success
function M.compile_async(task)
	-- Check if already compiling this file
	local key = task.file.path
	if M.active_compilations[key] then
		utils.notify("Already compiling " .. task.file.name, vim.log.levels.WARN, "⚠")
		return false
	end
	
	utils.notify(
		string.format("Starting async compilation: %s", task.file.name),
		vim.log.levels.INFO,
		"🔄"
	)
	
	-- Create temporary build directory
	local temp_dir = vim.fn.tempname()
	vim.fn.mkdir(temp_dir, "p")
	
	-- Prepare compilation command with timeout
	local full_cmd = string.format(
		"cd %s && timeout %d %s",
		utils.shell_escape(task.file.dir),
		math.floor(task.timeout / 1000),
		task.command
	)
	
	-- Start async job
	local job_id = vim.fn.jobstart(full_cmd, {
		on_stdout = vim.schedule_wrap(function(_, data, _)
			if task.on_progress and data then
				local output = table.concat(data, "\n")
				if output:match("%S") then -- Non-empty output
					task.on_progress(output, "stdout")
				end
			end
		end),
		
		on_stderr = vim.schedule_wrap(function(_, data, _)
			if task.on_progress and data then
				local output = table.concat(data, "\n")
				if output:match("%S") then -- Non-empty output
					task.on_progress(output, "stderr")
				end
			end
		end),
		
		on_exit = vim.schedule_wrap(function(_, exit_code, _)
			M.on_compilation_complete(key, exit_code, task)
		end),
		
		cwd = task.file.dir,
		detach = false,
	})
	
	if job_id <= 0 then
		utils.notify("Failed to start async compilation", vim.log.levels.ERROR, "✗")
		return false
	end
	
	-- Track the compilation
	task.job_id = job_id
	task.start_time = vim.fn.reltime()
	M.active_compilations[key] = task
	
	-- Set up timeout
	vim.defer_fn(function()
		if M.active_compilations[key] and M.active_compilations[key].job_id == job_id then
			M.cancel_compilation(key, "timeout")
		end
	end, task.timeout)
	
	return true
end

---Handle compilation completion
---@param key string
---@param exit_code number
---@param task CompilationTask
function M.on_compilation_complete(key, exit_code, task)
	local compilation = M.active_compilations[key]
	if not compilation then
		return
	end
	
	local elapsed = vim.fn.reltimestr(vim.fn.reltime(task.start_time))
	local success = exit_code == 0
	
	-- Cache the result
	cache.cache_result(task.file.path, nil, success)
	
	-- Notification
	if success then
		utils.notify(
			string.format("%s compiled successfully in %ss", task.runner_name, elapsed),
			vim.log.levels.INFO,
			"✓"
		)
	else
		utils.notify(
			string.format("%s compilation failed (exit: %d) after %ss", task.runner_name, exit_code, elapsed),
			vim.log.levels.ERROR,
			"✗"
		)
	end
	
	-- Clean up
	M.active_compilations[key] = nil
	
	-- Call completion handler
	if task.on_complete then
		task.on_complete(success, exit_code, elapsed)
	end
end

---Cancel active compilation
---@param key string
---@param reason? string
function M.cancel_compilation(key, reason)
	local compilation = M.active_compilations[key]
	if not compilation then
		return false
	end
	
	-- Stop the job
	vim.fn.jobstop(compilation.job_id)
	
	-- Clean up
	M.active_compilations[key] = nil
	
	local msg = reason or "cancelled"
	utils.notify(
		string.format("Compilation %s: %s", msg, compilation.file.name),
		vim.log.levels.WARN,
		"⚠"
	)
	
	return true
end

---Cancel all active compilations
function M.cancel_all()
	local cancelled = 0
	for key, compilation in pairs(M.active_compilations) do
		vim.fn.jobstop(compilation.job_id)
		cancelled = cancelled + 1
	end
	
	M.active_compilations = {}
	
	if cancelled > 0 then
		utils.notify(
			string.format("Cancelled %d active compilations", cancelled),
			vim.log.levels.INFO,
			"🛑"
		)
	end
	
	return cancelled
end

---Get compilation status
---@param file_path? string
---@return table
function M.get_status(file_path)
	if file_path then
		local compilation = M.active_compilations[file_path]
		if compilation then
			return {
				active = true,
				runner_name = compilation.runner_name,
				elapsed = vim.fn.reltimestr(vim.fn.reltime(compilation.start_time)),
				job_id = compilation.job_id,
			}
		else
			return { active = false }
		end
	else
		-- Get all active compilations
		local status = {}
		for key, compilation in pairs(M.active_compilations) do
			status[key] = {
				runner_name = compilation.runner_name,
				elapsed = vim.fn.reltimestr(vim.fn.reltime(compilation.start_time)),
				job_id = compilation.job_id,
			}
		end
		return status
	end
end

---Check if file is currently being compiled
---@param file_path string
---@return boolean
function M.is_compiling(file_path)
	return M.active_compilations[file_path] ~= nil
end

---Get compilation progress/output for display
---@param file_path string
---@return string|nil
function M.get_compilation_output(file_path)
	local compilation = M.active_compilations[file_path]
	if not compilation then
		return nil
	end
	
	-- This would be enhanced to capture and return actual output
	-- For now, return basic status
	return string.format(
		"Compiling %s (%s)...",
		compilation.file.name,
		vim.fn.reltimestr(vim.fn.reltime(compilation.start_time))
	)
end

---Compile with smart async decision
---@param file table
---@param command string
---@param runner_name string
---@param project_root string
---@param config table
---@param on_complete function
---@return boolean success
function M.smart_compile(file, command, runner_name, project_root, config, on_complete)
	-- Decide whether to use async based on file size and complexity
	local should_async = config.behavior.async_compilation
	
	if should_async then
		-- Check file size - use async for larger files
		local file_size = vim.fn.getfsize(file.path)
		if file_size > 50000 then -- 50KB threshold
			should_async = true
		elseif file_size > 0 and file_size < 5000 then -- 5KB threshold
			should_async = false -- Small files compile quickly
		end
		
		-- Check for complex project structure
		local has_build_system = utils.file_exists(project_root .. "/CMakeLists.txt") or
		                        utils.file_exists(project_root .. "/Makefile") or
		                        utils.file_exists(project_root .. "/build.gradle")
		
		if has_build_system then
			should_async = true
		end
	end
	
	if should_async then
		return M.compile_async({
			file = file,
			command = command,
			runner_name = runner_name,
			project_root = project_root,
			timeout = config.compilation.timeout or 30000,
			on_complete = on_complete,
		})
	else
		-- Synchronous compilation
		if on_complete then
			on_complete(true, 0, "0") -- Assume success for sync
		end
		return true
	end
end

return M