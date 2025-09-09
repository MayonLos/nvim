---@class RunnerConfig
local M = {}

---@class CodeRunnerConfig
---@field terminal TerminalConfig
---@field behavior BehaviorConfig
---@field compilation CompilationConfig
---@field project ProjectConfig

---@class BehaviorConfig
---@field auto_save boolean
---@field show_notifications boolean
---@field async_compilation boolean

---@class CompilationConfig
---@field mode string
---@field flags table<string, table>
---@field timeout number

---@class ProjectConfig
---@field enable boolean
---@field config_files table<string>
---@field custom_templates table

-- Default configuration
M.default_config = {
	terminal = {
		width_ratio = 0.8,
		height_ratio = 0.6,
		border = "rounded",
		focus_on_open = true,
		clear_before_run = true,
		auto_close_on_success = false,
		persist = true,
		smart_positioning = true,
	},
	behavior = {
		auto_save = true,
		show_notifications = true,
		async_compilation = true, -- New: Enable async compilation
	},
	compilation = {
		mode = "debug", -- debug | release
		flags = {
			debug = { "-g", "-Wall", "-Wextra", "-O0" },
			release = { "-O2", "-DNDEBUG" },
		},
		timeout = 30000, -- 30 seconds timeout for compilation
	},
	project = {
		enable = true, -- New: Enable project-specific configurations
		config_files = { ".nvim-runner.lua", "runner.lua" }, -- Config file names to look for
		custom_templates = {}, -- User-defined runner templates
	},
}

-- Current configuration
M.config = vim.deepcopy(M.default_config)

-- Project-specific config cache
M.project_configs = {}

---Load project-specific configuration
---@param project_root? string
---@return table|nil
local function load_project_config(project_root)
	if not M.config.project.enable then
		return nil
	end
	
	project_root = project_root or vim.fn.getcwd()
	
	-- Check cache first
	if M.project_configs[project_root] then
		return M.project_configs[project_root]
	end
	
	-- Look for project config files
	for _, config_file in ipairs(M.config.project.config_files) do
		local config_path = project_root .. "/" .. config_file
		if vim.fn.filereadable(config_path) == 1 then
			local ok, project_config = pcall(dofile, config_path)
			if ok and type(project_config) == "table" then
				-- Cache the project config
				M.project_configs[project_root] = project_config
				return project_config
			else
				vim.notify(
					string.format("Error loading project config: %s", config_path),
					vim.log.levels.WARN
				)
			end
		end
	end
	
	-- Cache empty result to avoid repeated file system checks
	M.project_configs[project_root] = {}
	return nil
end

---Get effective configuration (default + project-specific)
---@param project_root? string
---@return table
function M.get_config(project_root)
	local project_config = load_project_config(project_root)
	if not project_config then
		return M.config
	end
	
	-- Merge project config with default config
	return vim.tbl_deep_extend("force", M.config, project_config)
end

---Get compilation flags for current mode
---@param mode? string
---@param project_root? string
---@return table
function M.get_compile_flags(mode, project_root)
	local config = M.get_config(project_root)
	mode = mode or config.compilation.mode
	return config.compilation.flags[mode] or {}
end

---Add custom runner template
---@param name string
---@param template table
function M.add_template(name, template)
	M.config.project.custom_templates[name] = template
	vim.notify(string.format("Added custom template: %s", name), vim.log.levels.INFO)
end

---Get custom template by name
---@param name string
---@param project_root? string
---@return table|nil
function M.get_template(name, project_root)
	local config = M.get_config(project_root)
	return config.project.custom_templates[name]
end

---List available templates
---@param project_root? string
---@return table
function M.list_templates(project_root)
	local config = M.get_config(project_root)
	local templates = {}
	for name, _ in pairs(config.project.custom_templates) do
		table.insert(templates, name)
	end
	return templates
end

---Validate configuration structure
---@param config table
---@return boolean, string?
local function validate_config(config)
	-- Basic validation
	if type(config) ~= "table" then
		return false, "Config must be a table"
	end
	
	-- Validate terminal config
	if config.terminal then
		if config.terminal.width_ratio and (config.terminal.width_ratio <= 0 or config.terminal.width_ratio > 1) then
			return false, "terminal.width_ratio must be between 0 and 1"
		end
		if config.terminal.height_ratio and (config.terminal.height_ratio <= 0 or config.terminal.height_ratio > 1) then
			return false, "terminal.height_ratio must be between 0 and 1"
		end
	end
	
	-- Validate compilation config
	if config.compilation then
		if config.compilation.mode and not M.default_config.compilation.flags[config.compilation.mode] then
			-- Check if custom flags are provided for the mode
			if not config.compilation.flags or not config.compilation.flags[config.compilation.mode] then
				return false, "Unknown compilation mode: " .. config.compilation.mode
			end
		end
	end
	
	return true, nil
end

---Update configuration with validation
---@param opts table
---@return boolean, string?
function M.update(opts)
	if not opts then
		return true, nil
	end
	
	-- Validate new config
	local new_config = vim.tbl_deep_extend("force", M.config, opts)
	local valid, error_msg = validate_config(new_config)
	if not valid then
		return false, error_msg
	end
	
	-- Apply configuration
	M.config = new_config
	
	-- Clear project config cache if project settings changed
	if opts.project then
		M.project_configs = {}
	end
	
	return true, nil
end

---Reset configuration to defaults
function M.reset()
	M.config = vim.deepcopy(M.default_config)
	M.project_configs = {}
end

---Get configuration for display/debugging
---@return table
function M.get_debug_info()
	return {
		current_config = M.config,
		project_configs_cached = vim.tbl_keys(M.project_configs),
		project_root = vim.fn.getcwd(),
	}
end

---Setup module with initial configuration
---@param opts? table
function M.setup(opts)
	if opts then
		local success, error_msg = M.update(opts)
		if not success then
			vim.notify(
				string.format("Invalid CodeRunner configuration: %s", error_msg),
				vim.log.levels.ERROR
			)
			return false
		end
	end
	return true
end

return M