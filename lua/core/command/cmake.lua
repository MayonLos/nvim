local M = {}

-- Default configuration
M.config = {
	build_dir = "build",
	build_type = "Debug",
	cxx_standard = 17,
	-- jobs = nil, -- parallel build jobs (auto-detect if nil)
}

-- Utility: check if file or directory exists
local function file_exists(path)
	return vim.fn.filereadable(path) == 1
end
local function dir_exists(path)
	return vim.fn.isdirectory(path) == 1
end

-- Utility: derive project name from current directory
local function get_project_name()
	local name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	name = name:gsub("[^%w_%-]", "_") -- sanitize to valid name
	if name == "" then
		name = "Project"
	end
	return name
end

-- Generate a simple CMakeLists.txt (if not already present)
function M.generate_cmake()
	if file_exists "CMakeLists.txt" then
		vim.notify("CMakeLists.txt already exists", vim.log.levels.WARN)
		return
	end
	local project = get_project_name()
	-- Collect source files from current dir and src/ (recursive)
	local sources = {}
	local patterns = { "**/*.c", "**/*.cpp", "**/*.cxx" }
	for _, dir in ipairs { ".", "src" } do
		if dir == "." or dir_exists(dir) then
			for _, pat in ipairs(patterns) do
				for _, file in ipairs(vim.fn.globpath(dir, pat, false, true)) do
					-- Skip files in 'build', 'test', or 'example' directories
					if not file:find "/build/" and not file:find "/test" and not file:find "/example" then
						table.insert(sources, vim.fn.fnamemodify(file, ":.")) -- relative path
					end
				end
			end
		end
	end
	table.sort(sources)
	if #sources == 0 then
		vim.notify("No source files found for CMakeLists.txt", vim.log.levels.WARN)
	end

	-- Construct CMakeLists.txt content
	local lines = {
		"cmake_minimum_required(VERSION 3.10)",
		"project(" .. project .. ")",
		"set(CMAKE_CXX_STANDARD " .. M.config.cxx_standard .. ")",
		"set(CMAKE_CXX_STANDARD_REQUIRED ON)",
		"set(CMAKE_EXPORT_COMPILE_COMMANDS ON)",
	}
	if dir_exists "include" then
		table.insert(lines, "include_directories(include)")
	end
	if #sources > 0 then
		table.insert(lines, "add_executable(${PROJECT_NAME}")
		for _, src in ipairs(sources) do
			table.insert(lines, "    " .. src)
		end
		table.insert(lines, ")")
	else
		table.insert(lines, "# add_executable(${PROJECT_NAME} main.cpp)")
	end

	-- Write out the file
	local ok, err = pcall(vim.fn.writefile, lines, "CMakeLists.txt")
	if ok then
		vim.notify("Generated CMakeLists.txt for project " .. project, vim.log.levels.INFO)
	else
		vim.notify("Error writing CMakeLists.txt: " .. err, vim.log.levels.ERROR)
	end
end

-- Internal helper: open a floating terminal to run a given shell command
local function open_terminal(cmd, title)
	local buf = vim.api.nvim_create_buf(false, true) -- scratch buffer for terminal
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	local width = math.floor(vim.o.columns * 0.8)
	local height = math.floor(vim.o.lines * 0.8)
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		style = "minimal",
		border = "rounded",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		title = title or "Terminal",
		title_pos = "center",
	})
	vim.fn.termopen(cmd)
	vim.cmd "startinsert" -- enter Terminal mode to show live output
	-- Close mappings: press Esc or 'q' to close the floating window
	vim.keymap.set("t", "<Esc>", [[<C-\><C-n>:close<CR>]], { buffer = buf, silent = true })
	vim.keymap.set("n", "q", ":close<CR>", { buffer = buf, silent = true })
end

-- Build (configure + compile) the project
function M.build_project()
	local build_dir = M.config.build_dir
	local build_type = M.config.build_type
	if not dir_exists(build_dir) then
		vim.fn.mkdir(build_dir, "p")
	end -- create build dir if needed

	-- Determine parallel jobs (auto-detect CPU count once if not set)
	local jobs = M.config.jobs
	if jobs == nil then
		local handle = io.popen "nproc 2>/dev/null || echo 4"
		jobs = handle and tonumber(handle:read "*a") or 4
		if handle then
			handle:close()
		end
		M.config.jobs = jobs
	end

	-- Prepare the shell command: CMake configure and then build
	local cmd = string.format(
		"cmake -B %s -S . -DCMAKE_BUILD_TYPE=%s && cmake --build %s --parallel %d",
		vim.fn.shellescape(build_dir),
		build_type,
		vim.fn.shellescape(build_dir),
		jobs
	)
	open_terminal(cmd, "Build")
end

-- Run the compiled executable (with optional arguments)
function M.run_project(args)
	local project = get_project_name()
	local build_dir = M.config.build_dir
	-- Determine the expected executable path
	local exe_path = build_dir .. "/" .. project
	if vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 then
		exe_path = exe_path .. ".exe"
	end
	if not file_exists(exe_path) then
		-- If not found, try the Debug subdirectory (for multi-config generators)
		local alt = build_dir
			.. "/Debug/"
			.. project
			.. (vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 and ".exe" or "")
		if file_exists(alt) then
			exe_path = alt
		else
			return vim.notify("Executable not found. Please build the project first.", vim.log.levels.ERROR)
		end
	end
	if args and args ~= "" then
		exe_path = exe_path .. " " .. args
	end
	open_terminal(exe_path, "Run")
end

-- Quick workflow: generate CMakeLists if needed, then build and run
function M.quick_run(args)
	if not file_exists "CMakeLists.txt" then
		M.generate_cmake()
	end
	local project = get_project_name()
	local build_dir = M.config.build_dir
	local build_type = M.config.build_type
	local jobs = M.config.jobs or 4 -- use detected jobs or default to 4
	local exe = build_dir .. "/" .. project .. (vim.fn.has "win32" == 1 or vim.fn.has "win64" == 1 and ".exe" or "")
	-- Chain: CMake configure, build, and run the executable
	local cmd = string.format(
		"cmake -B %s -S . -DCMAKE_BUILD_TYPE=%s && cmake --build %s --parallel %d && %s",
		vim.fn.shellescape(build_dir),
		build_type,
		vim.fn.shellescape(build_dir),
		jobs,
		exe .. (args and " " .. args or "")
	)
	open_terminal(cmd, "Build & Run")
end

-- Clean the build directory
function M.clean_project()
	if dir_exists(M.config.build_dir) then
		vim.fn.delete(M.config.build_dir, "rf")
		vim.notify("Build directory removed.", vim.log.levels.INFO)
	end
end

-- Setup user commands for easy access to the functions
function M.setup(user_config)
	if user_config then
		for k, v in pairs(user_config) do
			M.config[k] = v
		end -- apply user overrides
	end
	vim.api.nvim_create_user_command("CMakeGen", function()
		M.generate_cmake()
	end, { desc = "Generate CMakeLists.txt" })
	vim.api.nvim_create_user_command("CMakeBuild", function()
		M.build_project()
	end, { desc = "Configure and build project" })
	vim.api.nvim_create_user_command("CMakeRun", function(opts)
		M.run_project(opts.args)
	end, { desc = "Run project executable", nargs = "*" })
	vim.api.nvim_create_user_command("CMakeQuick", function(opts)
		M.quick_run(opts.args)
	end, { desc = "Build and run (quick)", nargs = "*" })
	vim.api.nvim_create_user_command("CMakeClean", function()
		M.clean_project()
	end, { desc = "Clean build directory" })
end

return M
