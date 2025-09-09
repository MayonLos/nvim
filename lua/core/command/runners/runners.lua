---@class LanguageRunners
local M = {}

local utils = require("core.command.runners.utils")
local cache = require("core.command.runners.cache")
local config = require("core.command.runners.config")

---@class Runner
---@field name string
---@field cmd function|string
---@field async? boolean
---@field pre_run? function
---@field post_run? function
---@field supports_project_config? boolean

-- Built-in language runners with enhanced features
M.runners = {
	c = {
		name = "C",
		async = true,
		supports_project_config = true,
		cmd = function(file, project_root)
			local cfg = config.get_config(project_root)
			local flags = config.get_compile_flags(cfg.compilation.mode, project_root)
			local compile_cmd = string.format("gcc %s %s -o %s", 
				utils.join(flags, " "), file.name, file.base)
			return string.format("%s && ./%s", compile_cmd, file.base)
		end,
		pre_run = function(file, project_root)
			-- Check for cached compilation result
			local cfg = config.get_config(project_root)
			local flags = config.get_compile_flags(cfg.compilation.mode, project_root)
			local success, cached = cache.get_cached_result(file.path, flags)
			
			if cached then
				if success then
					utils.notify("Using cached compilation", vim.log.levels.INFO, "⚡")
					return { skip_compile = true }
				else
					utils.notify("Cached compilation failed, recompiling", vim.log.levels.WARN, "🔄")
				end
			end
			
			return {}
		end,
	},
	
	cpp = {
		name = "C++",
		async = true,
		supports_project_config = true,
		cmd = function(file, project_root)
			local cfg = config.get_config(project_root)
			local flags = config.get_compile_flags(cfg.compilation.mode, project_root)
			local compile_cmd = string.format("g++ -std=c++20 %s %s -o %s", 
				utils.join(flags, " "), file.name, file.base)
			return string.format("%s && ./%s", compile_cmd, file.base)
		end,
		pre_run = function(file, project_root)
			local cfg = config.get_config(project_root)
			local flags = config.get_compile_flags(cfg.compilation.mode, project_root)
			local success, cached = cache.get_cached_result(file.path, flags)
			
			if cached then
				if success then
					utils.notify("Using cached compilation", vim.log.levels.INFO, "⚡")
					return { skip_compile = true }
				else
					utils.notify("Cached compilation failed, recompiling", vim.log.levels.WARN, "🔄")
				end
			end
			
			return {}
		end,
	},
	
	rs = {
		name = "Rust",
		async = true,
		supports_project_config = true,
		cmd = function(file, project_root)
			local cfg = config.get_config(project_root)
			local opt_flag = cfg.compilation.mode == "release" and "-O" or ""
			local compile_cmd = string.format("rustc %s %s -o %s", opt_flag, file.name, file.base)
			return string.format("%s && ./%s", compile_cmd, file.base)
		end,
		pre_run = function(file, project_root)
			-- Check if we're in a Cargo project
			local cargo_file = utils.get_project_root() .. "/Cargo.toml"
			if utils.file_exists(cargo_file) then
				utils.notify("Detected Cargo project, using 'cargo run'", vim.log.levels.INFO, "🦀")
				return { use_cargo = true }
			end
			return {}
		end,
		post_run = function(file, success, context)
			if context.use_cargo then
				-- Override command for Cargo projects
				return "cargo run"
			end
			return nil
		end,
	},
	
	go = {
		name = "Go",
		async = false, -- Go compilation is usually fast
		supports_project_config = true,
		cmd = function(file, project_root)
			-- Check if we're in a Go module
			local mod_file = utils.get_project_root() .. "/go.mod"
			if utils.file_exists(mod_file) then
				return "go run ."
			end
			return string.format("go run %s", file.name)
		end,
	},
	
	py = {
		name = "Python",
		async = false,
		supports_project_config = true,
		cmd = function(file, project_root)
			local cfg = config.get_config(project_root)
			local python_cmd = cfg.python_command or "python3"
			return string.format("%s %s", python_cmd, file.name)
		end,
		pre_run = function(file, project_root)
			-- Check for virtual environment
			local venv_paths = { "venv/bin/activate", ".venv/bin/activate", "env/bin/activate" }
			for _, venv_path in ipairs(venv_paths) do
				if utils.file_exists(utils.get_project_root() .. "/" .. venv_path) then
					utils.notify("Virtual environment detected", vim.log.levels.INFO, "🐍")
					return { has_venv = true, venv_path = venv_path }
				end
			end
			return {}
		end,
	},
	
	js = {
		name = "JavaScript",
		async = false,
		supports_project_config = true,
		cmd = function(file, project_root)
			local cfg = config.get_config(project_root)
			local node_cmd = cfg.node_command or "node"
			return string.format("%s %s", node_cmd, file.name)
		end,
		pre_run = function(file, project_root)
			-- Check for package.json and suggest npm run
			local pkg_file = utils.get_project_root() .. "/package.json"
			if utils.file_exists(pkg_file) then
				utils.notify("Node.js project detected", vim.log.levels.INFO, "📦")
				return { has_package_json = true }
			end
			return {}
		end,
	},
	
	ts = {
		name = "TypeScript", 
		async = false,
		supports_project_config = true,
		cmd = function(file, project_root)
			local cfg = config.get_config(project_root)
			local ts_cmd = cfg.typescript_runner or "ts-node"
			return string.format("%s %s", ts_cmd, file.name)
		end,
		pre_run = function(file, project_root)
			-- Check for TypeScript configuration
			local ts_configs = { "tsconfig.json", "jsconfig.json" }
			for _, ts_config in ipairs(ts_configs) do
				if utils.file_exists(utils.get_project_root() .. "/" .. ts_config) then
					utils.notify("TypeScript project detected", vim.log.levels.INFO, "📘")
					return { has_ts_config = true }
				end
			end
			return {}
		end,
	},
	
	lua = {
		name = "Lua",
		async = false,
		supports_project_config = true,
		cmd = function(file, project_root)
			local cfg = config.get_config(project_root)
			local lua_cmd = cfg.lua_command or "lua"
			return string.format("%s %s", lua_cmd, file.name)
		end,
	},
	
	java = {
		name = "Java",
		async = true, -- Java compilation can be slow
		supports_project_config = true,
		cmd = function(file, project_root)
			local compile_cmd = string.format("javac %s", file.name)
			local run_cmd = string.format("java %s", file.base)
			return string.format("%s && %s", compile_cmd, run_cmd)
		end,
		pre_run = function(file, project_root)
			-- Check for Maven or Gradle project
			local build_files = { "pom.xml", "build.gradle", "build.gradle.kts" }
			for _, build_file in ipairs(build_files) do
				if utils.file_exists(utils.get_project_root() .. "/" .. build_file) then
					local build_tool = build_file:match("pom%.xml") and "Maven" or "Gradle"
					utils.notify(string.format("%s project detected", build_tool), vim.log.levels.INFO, "☕")
					return { has_build_tool = true, build_tool = build_tool:lower() }
				end
			end
			return {}
		end,
	},
	
	sh = {
		name = "Shell",
		async = false,
		supports_project_config = true,
		cmd = function(file, project_root)
			local cfg = config.get_config(project_root)
			local shell_cmd = cfg.shell_command or "bash"
			return string.format("%s %s", shell_cmd, file.name)
		end,
	},
}

---Get runner for file extension
---@param ext string
---@param project_root? string
---@return table|nil
function M.get_runner(ext, project_root)
	local runner = M.runners[ext]
	if not runner then
		return nil
	end
	
	-- Check for custom template override
	local template = config.get_template(ext, project_root)
	if template then
		utils.notify(string.format("Using custom template for .%s", ext), vim.log.levels.INFO, "🎨")
		return vim.tbl_deep_extend("force", runner, template)
	end
	
	return runner
end

---Add or update a runner
---@param ext string
---@param runner Runner
function M.add_runner(ext, runner)
	M.runners[ext] = runner
	utils.notify(string.format("Added runner for .%s", ext), vim.log.levels.INFO, "✓")
end

---Remove a runner
---@param ext string
function M.remove_runner(ext)
	if M.runners[ext] then
		M.runners[ext] = nil
		utils.notify(string.format("Removed runner for .%s", ext), vim.log.levels.INFO, "🗑")
	end
end

---List all supported languages
---@return table
function M.list_supported_languages()
	local languages = {}
	for ext, runner in pairs(M.runners) do
		table.insert(languages, {
			extension = ext,
			name = runner.name,
			async = runner.async or false,
			supports_project_config = runner.supports_project_config or false,
		})
	end
	
	-- Sort by extension
	table.sort(languages, function(a, b)
		return a.extension < b.extension
	end)
	
	return languages
end

---Build command for a file using the appropriate runner
---@param file table
---@param project_root? string
---@return string|nil cmd, table|nil context
function M.build_command(file, project_root)
	local runner = M.get_runner(file.ext, project_root)
	if not runner then
		return nil, nil
	end
	
	local context = {}
	
	-- Execute pre-run hook if available
	if runner.pre_run then
		local success, result = utils.safe_call(function()
			return runner.pre_run(file, project_root)
		end, "Pre-run hook failed")
		
		if success and result then
			context = vim.tbl_extend("force", context, result)
		end
	end
	
	-- Build command
	local cmd
	if type(runner.cmd) == "function" then
		local success, result = utils.safe_call(function()
			return runner.cmd(file, project_root)
		end, "Command generation failed")
		
		if not success then
			return nil, nil
		end
		cmd = result
	else
		cmd = runner.cmd
	end
	
	-- Execute post-run hook if available
	if runner.post_run then
		local success, modified_cmd = utils.safe_call(function()
			return runner.post_run(file, true, context)
		end, "Post-run hook failed")
		
		if success and modified_cmd then
			cmd = modified_cmd
		end
	end
	
	return cmd, context
end

---Check if async compilation is supported and beneficial
---@param file table
---@param project_root? string
---@return boolean
function M.should_use_async(file, project_root)
	local runner = M.get_runner(file.ext, project_root)
	if not runner then
		return false
	end
	
	local cfg = config.get_config(project_root)
	if not cfg.behavior.async_compilation then
		return false
	end
	
	return runner.async or false
end

---Get runner statistics
---@return table
function M.get_stats()
	local stats = {
		total_runners = 0,
		async_runners = 0,
		project_aware_runners = 0,
	}
	
	for _, runner in pairs(M.runners) do
		stats.total_runners = stats.total_runners + 1
		if runner.async then
			stats.async_runners = stats.async_runners + 1
		end
		if runner.supports_project_config then
			stats.project_aware_runners = stats.project_aware_runners + 1
		end
	end
	
	return stats
end

return M