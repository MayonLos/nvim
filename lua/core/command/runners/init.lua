---@class CodeRunner
local M = {}

-- Import modules
local utils = require("core.command.runners.utils")
local cache = require("core.command.runners.cache")
local config = require("core.command.runners.config")
local terminal = require("core.command.runners.terminal")
local runners = require("core.command.runners.runners")
local async = require("core.command.runners.async")

-- Expose configuration for backwards compatibility
M.config = config.config

-- Expose sessions for backwards compatibility  
M._sessions = {}

---Initialize notification system in modules
local function setup_notifications()
	terminal.notify = utils.notify
end

---Auto-save file if needed
---@return boolean success
local function auto_save()
	local cfg = config.get_config()
	if cfg.behavior.auto_save and vim.bo.modified then
		local success, error_msg = utils.safe_call(function()
			vim.cmd.write()
		end, "Auto-save failed")
		
		if success then
			utils.notify("File auto-saved", vim.log.levels.INFO, "💾")
		end
		return success
	end
	return true
end

---Run code with all optimizations
---@return boolean success
function M.run_code()
	-- Performance measurement for debugging
	return utils.measure_time(function()
		-- Auto save
		if not auto_save() then
			return false
		end
		
		-- Get file info (cached)
		local file, err = utils.get_file_info()
		if not file then
			utils.notify(err, vim.log.levels.ERROR, "✗")
			return false
		end
		
		-- Get project root and configuration
		local project_root = utils.get_project_root()
		local cfg = config.get_config(project_root)
		
		-- Check if runner exists
		local runner = runners.get_runner(file.ext, project_root)
		if not runner then
			utils.notify(
				string.format("Unsupported file type: .%s", file.ext),
				vim.log.levels.ERROR,
				"✗"
			)
			M.show_supported_languages()
			return false
		end
		
		-- Check cached compilation result
		local should_check_cache = runner.supports_project_config and 
			(runner.name:match("C") or runner.name:match("Rust") or runner.name:match("Java"))
		
		if should_check_cache then
			local flags = config.get_compile_flags(cfg.compilation.mode, project_root)
			local success, cached = cache.get_cached_result(file.path, flags)
			
			if cached then
				if success then
					utils.notify("Using cached build, skipping compilation", vim.log.levels.INFO, "⚡")
					-- Still run the executable
				else
					utils.notify("Previous compilation failed, rebuilding", vim.log.levels.WARN, "🔄")
				end
			end
		end
		
		-- Build command
		local cmd, context = runners.build_command(file, project_root)
		if not cmd then
			utils.notify("Failed to build command", vim.log.levels.ERROR, "✗")
			return false
		end
		
		-- Prepare full command with directory change
		local full_cmd = string.format("cd %s && %s", utils.shell_escape(file.dir), cmd)
		
		-- Show execution info
		local mode_icon = cfg.compilation.mode == "debug" and "🐛" or "🚀"
		local async_info = runners.should_use_async(file.ext, project_root) and " (async)" or ""
		utils.notify(
			string.format("Running %s [%s %s]%s", file.name, mode_icon, cfg.compilation.mode, async_info),
			vim.log.levels.INFO,
			"▶"
		)
		
		-- Check if this is a compilation task that could benefit from async
		local needs_compilation = runner.name:match("C") or runner.name:match("Rust") or runner.name:match("Java")
		
		if needs_compilation and cfg.behavior.async_compilation then
			-- Use async compilation for compilation tasks
			return async.smart_compile(
				file, 
				cmd, 
				runner.name, 
				project_root, 
				cfg,
				function(success, exit_code, elapsed)
					if success then
						-- After successful compilation, run the executable
						local run_cmd = cmd:match("&&%s*(.+)") or cmd -- Extract run command
						if run_cmd and run_cmd ~= cmd then
							local session = terminal.create_terminal(
								string.format("cd %s && %s", utils.shell_escape(file.dir), run_cmd),
								runner.name,
								session_key
							)
							
							if session then
								M._sessions[session.job_id] = session
							end
						end
					end
				end
			)
		end
		-- Create terminal with session reuse (for non-async or non-compilation tasks)
		local session_key = file.ext .. "_" .. file.base
		local session = terminal.create_terminal(full_cmd, runner.name, session_key)
		
		if session then
			-- Store additional context for result caching
			session.file_path = file.path
			session.compile_flags = should_check_cache and 
				config.get_compile_flags(cfg.compilation.mode, project_root) or nil
			
			-- Update backwards compatibility session tracking
			M._sessions[session.job_id] = session
			
			return true
		else
			return false
		end
	end, "CodeRunner execution")
end

---Toggle compilation mode (debug/release)
function M.toggle_mode()
	local current_mode = config.config.compilation.mode
	local new_mode = current_mode == "debug" and "release" or "debug"
	
	local success, error_msg = config.update({ compilation = { mode = new_mode } })
	if not success then
		utils.notify(string.format("Failed to change mode: %s", error_msg), vim.log.levels.ERROR, "✗")
		return
	end
	
	local icon = new_mode == "debug" and "🐛" or "🚀"
	utils.notify(string.format("Mode: %s %s", icon, new_mode), vim.log.levels.INFO, "⚙")
	
	-- Invalidate caches that depend on compilation mode
	cache.cleanup_cache()
end

---Show supported languages with enhanced information
function M.show_supported_languages()
	local languages = runners.list_supported_languages()
	local language_info = {}
	
	for _, lang in ipairs(languages) do
		local features = {}
		if lang.async then table.insert(features, "async") end
		if lang.supports_project_config then table.insert(features, "project-aware") end
		
		local feature_str = #features > 0 and (" [" .. table.concat(features, ", ") .. "]") or ""
		table.insert(language_info, string.format(".%s - %s%s", lang.extension, lang.name, feature_str))
	end
	
	local templates = config.list_templates()
	if #templates > 0 then
		table.insert(language_info, "")
		table.insert(language_info, "Custom templates: " .. table.concat(templates, ", "))
	end
	
	utils.notify("Supported: " .. table.concat(language_info, ", "), vim.log.levels.INFO, "📋")
end

---Add custom runner (backwards compatibility)
---@param ext string
---@param runner table
function M.add_runner(ext, runner)
	runners.add_runner(ext, runner)
end

---Add custom runner template
---@param name string
---@param template table
function M.add_template(name, template)
	config.add_template(name, template)
end

---Get runner statistics and cache information
function M.get_debug_info()
	return {
		runner_stats = runners.get_stats(),
		cache_stats = cache.get_stats(),
		config_info = config.get_debug_info(),
		active_terminals = terminal.list_terminals(),
	}
end

---Clean up all resources
function M.cleanup()
	async.cancel_all()
	terminal.close_all_terminals()
	utils.cleanup()
	cache.cleanup_cache()
	M._sessions = {}
end

---Setup with enhanced configuration
---@param opts? table
function M.setup(opts)
	-- Setup modules
	setup_notifications()
	
	-- Configure all modules
	local success, error_msg = config.setup(opts)
	if not success then
		vim.notify(
			string.format("CodeRunner setup failed: %s", error_msg),
			vim.log.levels.ERROR
		)
		return false
	end
	
	-- Setup terminal with config
	terminal.setup(config.config.terminal)
	
	-- Create user commands
	vim.api.nvim_create_user_command("RunCode", M.run_code, { desc = "Run current file" })
	vim.api.nvim_create_user_command("RunCodeToggle", M.toggle_mode, { desc = "Toggle debug/release mode" })
	vim.api.nvim_create_user_command(
		"RunCodeLanguages", 
		M.show_supported_languages, 
		{ desc = "Show supported languages" }
	)
	vim.api.nvim_create_user_command(
		"RunCodeDebug",
		function() 
			local info = M.get_debug_info()
			print(vim.inspect(info))
		end,
		{ desc = "Show CodeRunner debug information" }
	)
	vim.api.nvim_create_user_command(
		"RunCodeCleanup",
		M.cleanup,
		{ desc = "Clean up CodeRunner resources" }
	)
	vim.api.nvim_create_user_command(
		"RunCodeAsync",
		function()
			-- Check async compilation status
			local status = async.get_status()
			if vim.tbl_isempty(status) then
				utils.notify("No active async compilations", vim.log.levels.INFO, "ℹ")
			else
				for file_path, compilation in pairs(status) do
					local file_name = vim.fn.fnamemodify(file_path, ":t")
					utils.notify(
						string.format("%s: %s (%s)", file_name, compilation.runner_name, compilation.elapsed),
						vim.log.levels.INFO,
						"🔄"
					)
				end
			end
		end,
		{ desc = "Show async compilation status" }
	)
	vim.api.nvim_create_user_command(
		"RunCodeStop",
		function()
			local cancelled = async.cancel_all()
			if cancelled == 0 then
				utils.notify("No active compilations to stop", vim.log.levels.INFO, "ℹ")
			end
		end,
		{ desc = "Stop all async compilations" }
	)
	
	-- Create keymap if specified
	if opts and opts.keymap then
		vim.keymap.set("n", opts.keymap, M.run_code, { desc = "Run current file", silent = true })
	end
	
	-- Setup autogroup for cleanup and cache management
	vim.api.nvim_create_augroup("CodeRunner", { clear = true })
	
	-- Cleanup on exit
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = "CodeRunner",
		callback = M.cleanup,
	})
	
	-- Invalidate file info cache when buffer changes
	vim.api.nvim_create_autocmd("BufEnter", {
		group = "CodeRunner",
		callback = utils.invalidate_file_info,
	})
	
	-- Periodic cache cleanup
	vim.api.nvim_create_autocmd("CursorHold", {
		group = "CodeRunner",
		callback = utils.debounce(cache.cleanup_cache, 5000, "cache_cleanup"),
	})
	
	-- Invalidate project root cache when changing directories
	vim.api.nvim_create_autocmd("DirChanged", {
		group = "CodeRunner",
		callback = function()
			cache.invalidate_api_cache("project_root")
		end,
	})
	
	utils.notify("CodeRunner initialized with optimizations", vim.log.levels.INFO, "🚀")
	return true
end

-- Backwards compatibility: expose runners directly
M.runners = runners.runners

return M