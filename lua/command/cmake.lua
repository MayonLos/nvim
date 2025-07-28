local M = {}

-- ========================================
-- CONFIGURATION
-- ========================================
local default_config = {
	-- File extensions to scan for
	extensions = { "cpp", "cxx", "cc", "c", "hpp", "h" },

	-- CMake settings
	cmake = {
		version = "3.10",
		cxx_standard = "23",
		export_compile_commands = true,
	},

	-- Project template options
	template = {
		basic = true,
		with_subdirs = false,
		with_tests = false,
		with_examples = false,
	},

	-- Build configuration
	build = {
		directory = "build",
		generator = nil, -- Auto-detect
		build_type = "Debug",
		parallel_jobs = nil, -- Auto-detect
		install_prefix = nil,
		options = {}, -- Additional cmake options
	},

	-- Terminal UI configuration
	terminal = {
		width_ratio = 0.85,
		height_ratio = 0.75,
		max_width = 120,
		max_height = 35,
		border = "rounded",
		close_on_success = false,
		show_progress = true,
		timeout = 300, -- seconds
		auto_enter_terminal_mode = true, -- Automatically enter terminal mode
		smart_close = true, -- Smart close behavior
		completion_delay = 1500, -- Delay between commands (ms)
	},

	-- Notifications
	notifications = {
		enabled = true,
		level = vim.log.levels.INFO,
	},

	-- Auto-detection settings
	auto_detect = {
		main_file = { "main.cpp", "main.c", "main.cxx" },
		test_dirs = { "test", "tests", "test_src" },
		include_dirs = { "include", "inc", "headers" },
		source_dirs = { "src", "source", "lib" },
	},
}

local config = vim.deepcopy(default_config)

-- ========================================
-- UTILITY FUNCTIONS
-- ========================================
local utils = {}

-- Safe notification function
function utils.notify(message, level, title)
	if not config.notifications.enabled then
		return
	end

	level = level or config.notifications.level
	local opts = title and { title = title } or {}

	vim.schedule(function()
		vim.notify(message, level, opts)
	end)
end

-- Get current working directory safely
function utils.get_cwd()
	return vim.fn.getcwd()
end

-- Check if file exists and is readable
function utils.file_exists(path)
	return vim.fn.filereadable(path) == 1
end

-- Check if directory exists
function utils.dir_exists(path)
	return vim.fn.isdirectory(path) == 1
end

-- Create directory recursively
function utils.mkdir(path)
	return vim.fn.mkdir(path, "p") == 1
end

-- Get project name from directory or custom name
function utils.get_project_name(custom_name)
	if custom_name and custom_name ~= "" then
		return custom_name:gsub("[^%w_%-]", "_") -- Sanitize name
	end
	return vim.fn.fnamemodify(utils.get_cwd(), ":t"):gsub("[^%w_%-]", "_")
end

-- Scan for source files with improved pattern matching
function utils.scan_source_files(extensions, recursive, directories)
	local files = {}
	local search_dirs = directories or { "." }

	for _, dir in ipairs(search_dirs) do
		local pattern = recursive and (dir .. "/**/*.") or (dir .. "/*.")

		for _, ext in ipairs(extensions) do
			local found = vim.fn.glob(pattern .. ext, false, true)
			for _, file in ipairs(found) do
				-- Normalize path and avoid duplicates
				local normalized = vim.fn.fnamemodify(file, ":.")
				if not vim.tbl_contains(files, normalized) then
					table.insert(files, normalized)
				end
			end
		end
	end

	table.sort(files)
	return files
end

-- Auto-detect project structure
function utils.detect_project_structure()
	local structure = {
		has_subdirs = false,
		has_tests = false,
		has_examples = false,
		main_files = {},
		include_dirs = {},
		source_dirs = {},
		test_dirs = {},
	}

	-- Check for common directories
	for _, dir in ipairs(config.auto_detect.include_dirs) do
		if utils.dir_exists(dir) then
			table.insert(structure.include_dirs, dir)
			structure.has_subdirs = true
		end
	end

	for _, dir in ipairs(config.auto_detect.source_dirs) do
		if utils.dir_exists(dir) then
			table.insert(structure.source_dirs, dir)
			structure.has_subdirs = true
		end
	end

	for _, dir in ipairs(config.auto_detect.test_dirs) do
		if utils.dir_exists(dir) then
			table.insert(structure.test_dirs, dir)
			structure.has_tests = true
		end
	end

	-- Check for main files
	for _, main_file in ipairs(config.auto_detect.main_file) do
		if utils.file_exists(main_file) then
			table.insert(structure.main_files, main_file)
		end
	end

	-- Check for examples
	if utils.dir_exists "examples" or utils.dir_exists "example" then
		structure.has_examples = true
	end

	return structure
end

-- Get optimal number of parallel jobs
function utils.get_parallel_jobs()
	if config.build.parallel_jobs then
		return config.build.parallel_jobs
	end

	-- Auto-detect based on system
	if vim.fn.has "unix" == 1 then
		local nproc = vim.fn.system("nproc 2>/dev/null || echo 4"):gsub("%s+", "")
		return tonumber(nproc) or 4
	elseif vim.fn.has "win32" == 1 then
		local proc = os.getenv "NUMBER_OF_PROCESSORS"
		return tonumber(proc) or 4
	end

	return 4
end

-- ========================================
-- TERMINAL MANAGEMENT
-- ========================================
local terminal = {}

-- Get terminal window size
function terminal.get_size()
	local W, H = vim.o.columns, vim.o.lines
	local cfg = config.terminal

	return {
		width = math.min(cfg.max_width, math.floor(W * cfg.width_ratio)),
		height = math.min(cfg.max_height, math.floor(H * cfg.height_ratio)),
	}
end

-- Create floating terminal window
function terminal.create_window(buf, title)
	local size = terminal.get_size()
	local W, H = vim.o.columns, vim.o.lines

	local win = vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		style = "minimal",
		border = config.terminal.border,
		width = size.width,
		height = size.height,
		col = math.floor((W - size.width) / 2),
		row = math.floor((H - size.height) / 2),
		title = title or " CMake ",
		title_pos = "center",
	})

	-- Set window highlights
	vim.api.nvim_win_set_option(win, "winhl", "Normal:Normal,FloatBorder:FloatBorder")

	return win
end

-- Setup terminal keybindings
function terminal.setup_keybindings(buf, win, state)
	-- Close keys - work in both normal and terminal mode
	local close_keys = { "q", "<Esc>", "<C-c>" }

	for _, key in ipairs(close_keys) do
		vim.keymap.set({ "n", "t" }, key, function()
			state.force_close = true
			if state.current_job_id then
				vim.fn.jobstop(state.current_job_id)
			end
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end, {
			buffer = buf,
			nowait = true,
			silent = true,
			desc = "Close CMake terminal",
		})
	end

	-- Enter key in normal mode - close if process finished, otherwise go to terminal mode
	vim.keymap.set("n", "<CR>", function()
		if state.current_job_id then
			-- Process is running, enter terminal mode
			vim.cmd.startinsert()
		else
			-- Process finished, close terminal
			state.force_close = true
			if vim.api.nvim_win_is_valid(win) then
				vim.api.nvim_win_close(win, true)
			end
		end
	end, {
		buffer = buf,
		nowait = true,
		silent = true,
		desc = "Enter terminal mode or close if finished",
	})

	-- Space key - always close
	vim.keymap.set("n", "<Space>", function()
		state.force_close = true
		if state.current_job_id then
			vim.fn.jobstop(state.current_job_id)
		end
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
	end, {
		buffer = buf,
		nowait = true,
		silent = true,
		desc = "Force close terminal",
	})

	-- Set up terminal mode exit mappings
	vim.keymap.set("t", "<C-\\><C-n>", "<C-\\><C-n>", {
		buffer = buf,
		nowait = true,
		silent = true,
		desc = "Exit to normal mode",
	})
end

-- Execute command sequence in terminal
function terminal.execute_commands(commands, opts)
	opts = opts or {}

	-- Create buffer and window
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "modifiable", false) -- Prevent modification
	vim.api.nvim_buf_set_option(buf, "swapfile", false) -- Disable swapfile

	local win = terminal.create_window(buf, opts.title)

	-- State tracking
	local state = {
		force_close = false,
		current_job_id = nil,
		commands_completed = 0,
		total_commands = #commands,
		start_time = vim.fn.reltime(),
		buf = buf,
		win = win,
		is_finished = false,
	}

	-- Setup keybindings
	terminal.setup_keybindings(buf, win, state)

	-- Auto-focus and enter terminal mode
	vim.api.nvim_set_current_win(win)
	vim.api.nvim_set_current_buf(buf)

	-- Execute commands recursively
	local function execute_next(index)
		if index > #commands or state.force_close then
			return
		end

		-- Ensure buffer is still valid and unmodified
		if not vim.api.nvim_buf_is_valid(state.buf) then
			utils.notify("Terminal buffer was closed", vim.log.levels.WARN)
			return
		end

		local cmd = commands[index]
		local is_last = index == #commands

		-- Build shell command with progress and timing
		local shell_parts = {}

		if config.terminal.show_progress then
			table.insert(
				shell_parts,
				string.format(
					'echo -e "\\033[1;36m[%d/%d] %s\\033[0m"',
					index,
					#commands,
					cmd.name or ("Step " .. index)
				)
			)
		end

		table.insert(shell_parts, cmd.cmd)

		-- Add completion message
		local completion_msg = is_last
				and "\\033[1;32m✓ All tasks completed! Press <Enter> or <Space> to close.\\033[0m"
			or "\\033[1;33m→ Continuing to next step...\\033[0m"
		table.insert(shell_parts, string.format('echo -e "%s"', completion_msg))

		local full_cmd = table.concat(shell_parts, " && ")

		-- Ensure we're in the correct buffer and it's ready for terminal
		vim.api.nvim_set_current_buf(state.buf)

		-- Start job
		local job_id = vim.fn.termopen(full_cmd, {
			on_exit = function(_, code)
				if state.force_close then
					return
				end

				vim.schedule(function()
					state.commands_completed = state.commands_completed + 1
					local elapsed = vim.fn.reltimestr(vim.fn.reltime(state.start_time))

					if code == 0 then
						local msg = cmd.success_msg or string.format("Step %d completed", index)
						utils.notify("✓ " .. msg .. string.format(" (%.1fs)", elapsed))

						if is_last then
							state.is_finished = true
							state.current_job_id = nil

							if opts.final_success_msg then
								utils.notify("🎉 " .. opts.final_success_msg, vim.log.levels.INFO)
							end

							-- Switch to normal mode and show completion message
							if vim.api.nvim_win_is_valid(state.win) then
								vim.api.nvim_set_current_win(state.win)
								-- Exit terminal mode
								if vim.fn.mode() == "t" then
									vim.cmd "stopinsert"
								end

								-- Set cursor to last line for better visibility
								vim.defer_fn(function()
									if vim.api.nvim_buf_is_valid(state.buf) then
										local line_count = vim.api.nvim_buf_line_count(state.buf)
										if line_count > 0 then
											vim.api.nvim_win_set_cursor(state.win, { line_count, 0 })
										end
									end
								end, 100)
							end

							if config.terminal.close_on_success then
								vim.defer_fn(function()
									if vim.api.nvim_win_is_valid(state.win) and not state.force_close then
										vim.api.nvim_win_close(state.win, true)
									end
								end, 3000)
							end
						else
							-- Continue with next command after a brief delay
							vim.defer_fn(function()
								if not state.force_close and vim.api.nvim_buf_is_valid(state.buf) then
									-- Create a new clean buffer for the next command
									local new_buf = vim.api.nvim_create_buf(false, true)
									vim.api.nvim_buf_set_option(new_buf, "bufhidden", "wipe")
									vim.api.nvim_buf_set_option(new_buf, "modifiable", false)
									vim.api.nvim_buf_set_option(new_buf, "swapfile", false)

									-- Replace buffer in window
									if vim.api.nvim_win_is_valid(state.win) then
										vim.api.nvim_win_set_buf(state.win, new_buf)
										state.buf = new_buf

										-- Re-setup keybindings for new buffer
										terminal.setup_keybindings(new_buf, state.win, state)

										-- Ensure we focus the window and enter terminal mode
										vim.api.nvim_set_current_win(state.win)
										vim.api.nvim_set_current_buf(new_buf)

										execute_next(index + 1)
									end
								end
							end, 1500)
						end
					else
						state.is_finished = true
						state.current_job_id = nil
						local msg = cmd.error_msg or string.format("Step %d failed", index)
						utils.notify(
							string.format("✗ %s (exit code: %d, %.1fs)", msg, code, elapsed),
							vim.log.levels.ERROR
						)

						-- Exit terminal mode on error
						if vim.fn.mode() == "t" then
							vim.cmd "stopinsert"
						end
					end

					if is_last or code ~= 0 then
						state.current_job_id = nil
					end
				end)
			end,
		})

		if job_id <= 0 then
			utils.notify("Failed to start terminal job", vim.log.levels.ERROR)
			return
		end

		state.current_job_id = job_id

		-- Enter terminal mode immediately
		vim.defer_fn(function()
			if vim.api.nvim_win_is_valid(state.win) and not state.force_close then
				vim.api.nvim_set_current_win(state.win)
				vim.cmd.startinsert()
			end
		end, 50)
	end

	-- Start execution
	execute_next(1)

	return win, buf
end

-- Execute single command in terminal
function terminal.execute_simple(cmd, title, success_msg, error_msg)
	-- Create buffer with proper settings
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
	vim.api.nvim_buf_set_option(buf, "modifiable", false) -- Prevent modification
	vim.api.nvim_buf_set_option(buf, "swapfile", false) -- Disable swapfile

	local win = terminal.create_window(buf, " " .. (title or "CMake") .. " ")

	-- Track state
	local state = {
		force_close = false,
		current_job_id = nil,
		start_time = vim.fn.reltime(),
		is_finished = false,
	}

	-- Setup keybindings
	terminal.setup_keybindings(buf, win, state)

	-- Auto-focus and prepare terminal
	vim.api.nvim_set_current_win(win)
	vim.api.nvim_set_current_buf(buf)

	-- Enhanced command with completion indicator
	local enhanced_cmd = cmd
		.. ' && echo -e "\\033[1;32m✓ Task completed! Press <Enter> or <Space> to close.\\033[0m"'

	-- Start terminal job
	local job_id = vim.fn.termopen(enhanced_cmd, {
		on_exit = function(_, code)
			if state.force_close then
				return
			end

			vim.schedule(function()
				local elapsed = vim.fn.reltimestr(vim.fn.reltime(state.start_time))
				state.is_finished = true
				state.current_job_id = nil

				if code == 0 then
					if success_msg then
						utils.notify("✓ " .. success_msg .. string.format(" (%.1fs)", elapsed))
					end

					-- Exit terminal mode when completed
					if vim.fn.mode() == "t" then
						vim.cmd "stopinsert"
					end

					-- Position cursor at the end
					vim.defer_fn(function()
						if vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_win_is_valid(win) then
							local line_count = vim.api.nvim_buf_line_count(buf)
							if line_count > 0 then
								vim.api.nvim_win_set_cursor(win, { line_count, 0 })
							end
						end
					end, 100)

					if config.terminal.close_on_success then
						vim.defer_fn(function()
							if vim.api.nvim_win_is_valid(win) and not state.force_close then
								vim.api.nvim_win_close(win, true)
							end
						end, 3000)
					end
				else
					if error_msg then
						utils.notify(
							string.format("✗ %s (exit code: %d, %.1fs)", error_msg, code, elapsed),
							vim.log.levels.ERROR
						)
					end

					-- Exit terminal mode on error too
					if vim.fn.mode() == "t" then
						vim.cmd "stopinsert"
					end
				end
			end)
		end,
	})

	if job_id <= 0 then
		utils.notify("Failed to start terminal", vim.log.levels.ERROR)
		if vim.api.nvim_win_is_valid(win) then
			vim.api.nvim_win_close(win, true)
		end
		return false
	end

	state.current_job_id = job_id

	-- Enter terminal mode after a brief delay
	vim.defer_fn(function()
		if vim.api.nvim_win_is_valid(win) and not state.force_close then
			vim.api.nvim_set_current_win(win)
			vim.cmd.startinsert()
		end
	end, 50)

	return win, buf
end

-- ========================================
-- CMAKE GENERATION
-- ========================================
local cmake_gen = {}

-- Generate CMakeLists.txt content
function cmake_gen.generate_content(project_name, sources, options)
	options = options or {}
	local lines = {
		"cmake_minimum_required(VERSION " .. config.cmake.version .. ")",
		"project(" .. project_name .. ")",
		"",
	}

	-- C++ standard
	table.insert(lines, "# Set C++ standard")
	table.insert(lines, "set(CMAKE_CXX_STANDARD " .. config.cmake.cxx_standard .. ")")
	table.insert(lines, "set(CMAKE_CXX_STANDARD_REQUIRED ON)")
	table.insert(lines, "set(CMAKE_CXX_EXTENSIONS OFF)")
	table.insert(lines, "")

	-- Export compile commands
	if config.cmake.export_compile_commands then
		table.insert(lines, "# Export compile commands for IDEs")
		table.insert(lines, "set(CMAKE_EXPORT_COMPILE_COMMANDS ON)")
		table.insert(lines, "")
	end

	-- Build type and compiler flags
	if options.debug then
		table.insert(lines, "# Debug configuration")
		table.insert(lines, "if(NOT CMAKE_BUILD_TYPE)")
		table.insert(lines, "    set(CMAKE_BUILD_TYPE Debug)")
		table.insert(lines, "endif()")
		table.insert(lines, "")
		table.insert(lines, "# Compiler flags")
		table.insert(lines, 'set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 -Wall -Wextra -Wpedantic")')
		table.insert(lines, 'set(CMAKE_CXX_FLAGS_RELEASE "-O3 -DNDEBUG")')
		table.insert(lines, "")
	end

	-- Include directories
	if options.include_dirs and #options.include_dirs > 0 then
		table.insert(lines, "# Include directories")
		for _, dir in ipairs(options.include_dirs) do
			table.insert(lines, "include_directories(" .. dir .. ")")
		end
		table.insert(lines, "")
	end

	-- Source files
	if #sources > 0 then
		table.insert(lines, "# Source files")
		table.insert(lines, "set(SOURCES")
		for _, src in ipairs(sources) do
			table.insert(lines, "    " .. src)
		end
		table.insert(lines, ")")
		table.insert(lines, "")

		-- Add executable
		table.insert(lines, "# Create executable")
		table.insert(lines, "add_executable(${PROJECT_NAME} ${SOURCES})")
	else
		table.insert(lines, "# Add your source files here")
		table.insert(lines, "# add_executable(${PROJECT_NAME} main.cpp)")
	end
	table.insert(lines, "")

	-- Subdirectories
	if options.with_subdirs then
		table.insert(lines, "# Add subdirectories")
		if options.source_dirs then
			for _, dir in ipairs(options.source_dirs) do
				table.insert(lines, "# add_subdirectory(" .. dir .. ")")
			end
		end
		table.insert(lines, "")
	end

	-- Testing
	if options.with_tests then
		table.insert(lines, "# Enable testing")
		table.insert(lines, "enable_testing()")
		if options.test_dirs then
			for _, dir in ipairs(options.test_dirs) do
				table.insert(lines, "add_subdirectory(" .. dir .. ")")
			end
		else
			table.insert(lines, "# add_subdirectory(tests)")
		end
		table.insert(lines, "")
	end

	-- Installation
	if options.with_install then
		table.insert(lines, "# Installation")
		table.insert(lines, "install(TARGETS ${PROJECT_NAME}")
		table.insert(lines, "    RUNTIME DESTINATION bin)")
		table.insert(lines, "")
	end

	return lines
end

-- Write CMakeLists.txt file
function cmake_gen.write_file(content, overwrite)
	local path = utils.get_cwd() .. "/CMakeLists.txt"

	if utils.file_exists(path) and not overwrite then
		local choice = vim.fn.confirm(
			"CMakeLists.txt already exists. What would you like to do?",
			"&Overwrite\n&Backup and overwrite\n&Cancel",
			3
		)

		if choice == 3 then
			utils.notify("CMakeLists.txt generation cancelled", vim.log.levels.INFO)
			return false
		elseif choice == 2 then
			local backup_path = path .. ".backup." .. os.date "%Y%m%d_%H%M%S"
			if vim.fn.rename(path, backup_path) == 0 then
				utils.notify("Backup created: " .. backup_path, vim.log.levels.INFO)
			else
				utils.notify("Failed to create backup", vim.log.levels.ERROR)
				return false
			end
		end
	end

	local success, err = pcall(vim.fn.writefile, content, path)
	if success then
		utils.notify("Generated CMakeLists.txt successfully", vim.log.levels.INFO)
		return true
	else
		utils.notify("Failed to write CMakeLists.txt: " .. tostring(err), vim.log.levels.ERROR)
		return false
	end
end

-- ========================================
-- CORE FUNCTIONS
-- ========================================

-- Generate CMakeLists.txt with auto-detection
function M.generate_cmake(opts)
	opts = opts or {}

	-- Auto-detect project structure
	local structure = utils.detect_project_structure()

	-- Merge options with detected structure
	local options = vim.tbl_extend("force", {
		name = "",
		recursive = false,
		debug = true,
		with_tests = structure.has_tests,
		with_subdirs = structure.has_subdirs,
		with_examples = structure.has_examples,
		with_install = false,
		overwrite = false,
		include_dirs = structure.include_dirs,
		source_dirs = structure.source_dirs,
		test_dirs = structure.test_dirs,
	}, opts)

	-- Scan for source files
	local search_dirs = { "." }
	if #structure.source_dirs > 0 then
		search_dirs = structure.source_dirs
	end

	local sources = utils.scan_source_files(
		vim.tbl_filter(function(ext)
			return not vim.tbl_contains({ "h", "hpp" }, ext)
		end, config.extensions),
		options.recursive,
		search_dirs
	)

	if vim.tbl_isempty(sources) and vim.tbl_isempty(structure.main_files) then
		utils.notify("No source files found in current directory", vim.log.levels.WARN)
		return false
	end

	-- Use main files if found
	if not vim.tbl_isempty(structure.main_files) then
		sources = structure.main_files
	end

	local project_name = utils.get_project_name(options.name)
	local content = cmake_gen.generate_content(project_name, sources, options)

	return cmake_gen.write_file(content, options.overwrite)
end

-- Configure CMake project
function M.configure_project(build_type, generator)
	local build_dir = config.build.directory
	build_type = build_type or config.build.build_type

	-- Ensure build directory exists
	if not utils.mkdir(build_dir) then
		utils.notify("Failed to create build directory", vim.log.levels.ERROR)
		return false
	end

	-- Build cmake command
	local cmd_parts = { "cmake" }

	-- Build type
	table.insert(cmd_parts, "-DCMAKE_BUILD_TYPE=" .. build_type)

	-- Export compile commands
	if config.cmake.export_compile_commands then
		table.insert(cmd_parts, "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON")
	end

	-- Generator
	if generator or config.build.generator then
		table.insert(cmd_parts, "-G")
		table.insert(cmd_parts, vim.fn.shellescape(generator or config.build.generator))
	end

	-- Install prefix
	if config.build.install_prefix then
		table.insert(cmd_parts, "-DCMAKE_INSTALL_PREFIX=" .. config.build.install_prefix)
	end

	-- Additional options
	for _, option in ipairs(config.build.options) do
		table.insert(cmd_parts, option)
	end

	table.insert(cmd_parts, "..")

	-- Full command with directory change
	local full_cmd = string.format("cd %s && %s", vim.fn.shellescape(build_dir), table.concat(cmd_parts, " "))

	return terminal.execute_simple(
		full_cmd,
		"CMake Configure",
		"Project configured successfully",
		"Project configuration failed"
	)
end

-- Build CMake project
function M.build_project(target, clean_first)
	local build_dir = config.build.directory

	if not utils.dir_exists(build_dir) then
		utils.notify("Build directory not found. Run configure first", vim.log.levels.ERROR)
		return false
	end

	local cmd_parts = { "cmake", "--build", vim.fn.shellescape(build_dir) }

	-- Clean first if requested
	if clean_first then
		table.insert(cmd_parts, "--clean-first")
	end

	-- Target
	if target then
		table.insert(cmd_parts, "--target")
		table.insert(cmd_parts, target)
	end

	-- Parallel build
	local jobs = utils.get_parallel_jobs()
	table.insert(cmd_parts, "--parallel")
	table.insert(cmd_parts, tostring(jobs))

	local cmd = table.concat(cmd_parts, " ")

	return terminal.execute_simple(cmd, "CMake Build", "Build completed successfully", "Build failed")
end

-- Run CMake project
function M.run_project(target, args)
	local build_dir = config.build.directory
	local project_name = target or utils.get_project_name ""

	-- Search for executable
	local search_paths = {
		build_dir .. "/" .. project_name,
		build_dir .. "/Debug/" .. project_name,
		build_dir .. "/Release/" .. project_name,
		build_dir .. "/RelWithDebInfo/" .. project_name,
		build_dir .. "/MinSizeRel/" .. project_name,
		build_dir .. "/bin/" .. project_name,
	}

	local executable_path = nil
	for _, path in ipairs(search_paths) do
		if vim.fn.executable(path) == 1 then
			executable_path = path
			break
		end
	end

	if not executable_path then
		utils.notify("Executable not found: " .. project_name, vim.log.levels.ERROR)
		utils.notify("Searched paths: " .. table.concat(search_paths, ", "), vim.log.levels.DEBUG)
		return false
	end

	local cmd = vim.fn.shellescape(executable_path)
	if args then
		cmd = cmd .. " " .. args
	end

	return terminal.execute_simple(cmd, "Run Project", "Program execution completed", "Program execution failed")
end

-- Quick workflow: Generate + Configure + Build + Run
function M.quick_workflow(project_name, build_type, run_args)
	project_name = project_name or utils.get_project_name ""
	build_type = build_type or config.build.build_type

	-- Check for source files first
	local sources = utils.scan_source_files(config.extensions, false)
	if vim.tbl_isempty(sources) then
		utils.notify("No source files found", vim.log.levels.WARN)
		return false
	end

	-- Auto-generate CMakeLists.txt
	if not utils.file_exists "CMakeLists.txt" then
		if not M.generate_cmake { name = project_name, debug = build_type == "Debug" } then
			return false
		end
	end

	local build_dir = config.build.directory
	local jobs = utils.get_parallel_jobs()

	-- Build command sequence
	local commands = {
		{
			cmd = string.format("mkdir -p %s", vim.fn.shellescape(build_dir)),
			name = "Create build directory",
			success_msg = "Build directory ready",
			error_msg = "Failed to create build directory",
		},
		{
			cmd = string.format(
				"cd %s && cmake -DCMAKE_BUILD_TYPE=%s -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..",
				vim.fn.shellescape(build_dir),
				build_type
			),
			name = "Configure project",
			success_msg = "Project configured successfully",
			error_msg = "Configuration failed",
		},
		{
			cmd = string.format("cmake --build %s --parallel %d", vim.fn.shellescape(build_dir), jobs),
			name = "Build project",
			success_msg = "Build completed successfully",
			error_msg = "Build failed",
		},
	}

	-- Add run command if possible
	local executable_path = build_dir .. "/" .. project_name
	if vim.fn.executable(executable_path) == 1 or true then -- Allow attempt even if not yet built
		local run_cmd = vim.fn.shellescape(executable_path)
		if run_args then
			run_cmd = run_cmd .. " " .. run_args
		end

		table.insert(commands, {
			cmd = run_cmd,
			name = "Run project",
			success_msg = "Program execution completed",
			error_msg = "Program execution failed",
		})
	end

	return terminal.execute_commands(commands, {
		title = " CMake Quick Workflow ",
		final_success_msg = "🚀 Complete workflow finished successfully!",
	})
end

-- Clean build directory
function M.clean_project()
	local build_dir = config.build.directory

	if not utils.dir_exists(build_dir) then
		utils.notify("Build directory not found", vim.log.levels.WARN)
		return false
	end

	return terminal.execute_simple(
		"rm -rf " .. vim.fn.shellescape(build_dir) .. " && echo 'Build directory cleaned'",
		"CMake Clean",
		"Build directory cleaned successfully",
		"Clean operation failed"
	)
end

-- Install project
function M.install_project()
	local build_dir = config.build.directory

	if not utils.dir_exists(build_dir) then
		utils.notify("Build directory not found", vim.log.levels.ERROR)
		return false
	end

	return terminal.execute_simple(
		"cmake --build " .. vim.fn.shellescape(build_dir) .. " --target install",
		"CMake Install",
		"Project installed successfully",
		"Installation failed"
	)
end

-- Run tests
function M.test_project()
	local build_dir = config.build.directory

	if not utils.dir_exists(build_dir) then
		utils.notify("Build directory not found", vim.log.levels.ERROR)
		return false
	end

	return terminal.execute_simple(
		string.format(
			"cd %s && ctest --output-on-failure --parallel %d",
			vim.fn.shellescape(build_dir),
			utils.get_parallel_jobs()
		),
		"CMake Test",
		"All tests passed",
		"Some tests failed"
	)
end

-- Show project status
function M.status()
	local cwd = utils.get_cwd()
	local build_dir = config.build.directory
	local cmake_file = cwd .. "/CMakeLists.txt"
	local structure = utils.detect_project_structure()

	print "📋 CMake Project Status"
	print("=" .. string.rep("=", 50))
	print("  📁 Project Directory: " .. cwd)
	print("  📄 Project Name: " .. utils.get_project_name "")
	print("  📋 CMakeLists.txt: " .. (utils.file_exists(cmake_file) and "✅ Found" or "❌ Missing"))
	print(
		"  🏗️  Build Directory: "
			.. build_dir
			.. " "
			.. (utils.dir_exists(build_dir) and "✅ Exists" or "❌ Missing")
	)

	if utils.dir_exists(build_dir) then
		local cache_file = build_dir .. "/CMakeCache.txt"
		print("  ⚙️  CMake Cache: " .. (utils.file_exists(cache_file) and "✅ Configured" or "❌ Not configured"))

		-- Check for executables
		local project_name = utils.get_project_name ""
		local search_paths = {
			build_dir .. "/" .. project_name,
			build_dir .. "/Debug/" .. project_name,
			build_dir .. "/Release/" .. project_name,
		}

		local executable_found = false
		for _, path in ipairs(search_paths) do
			if vim.fn.executable(path) == 1 then
				print("  🚀 Executable: ✅ " .. path)
				executable_found = true
				break
			end
		end

		if not executable_found then
			print "  🚀 Executable: ❌ Not found"
		end
	end

	-- Project structure info
	print "\n🏗️  Detected Project Structure"
	print("=" .. string.rep("=", 50))
	print(
		"  Include directories: "
			.. (#structure.include_dirs > 0 and table.concat(structure.include_dirs, ", ") or "None")
	)
	print(
		"  Source directories: " .. (#structure.source_dirs > 0 and table.concat(structure.source_dirs, ", ") or "None")
	)
	print("  Test directories: " .. (#structure.test_dirs > 0 and table.concat(structure.test_dirs, ", ") or "None"))
	print("  Main files: " .. (#structure.main_files > 0 and table.concat(structure.main_files, ", ") or "None"))

	-- Configuration info
	print "\n⚙️  Current Configuration"
	print("=" .. string.rep("=", 50))
	print("  Build Type: " .. config.build.build_type)
	print("  C++ Standard: " .. config.cmake.cxx_standard)
	print("  CMake Version: " .. config.cmake.version)
	print("  Parallel Jobs: " .. utils.get_parallel_jobs())
	print("  Extensions: " .. table.concat(config.extensions, ", "))
end

-- ========================================
-- CONFIGURATION MANAGEMENT
-- ========================================

-- Update configuration
function M.update_config(new_config)
	config = vim.tbl_deep_extend("force", config, new_config or {})
end

-- Get current configuration
function M.get_config()
	return vim.deepcopy(config)
end

-- Reset configuration to defaults
function M.reset_config()
	config = vim.deepcopy(default_config)
	utils.notify("Configuration reset to defaults", vim.log.levels.INFO)
end

-- ========================================
-- SETUP AND COMMANDS
-- ========================================

function M.setup(user_config)
	-- Update configuration
	if user_config then
		M.update_config(user_config)
	end

	-- ===== GENERATION COMMANDS =====
	vim.api.nvim_create_user_command("GenCMake", function(cmd_opts)
		M.generate_cmake { name = cmd_opts.args }
	end, {
		nargs = "?",
		desc = "Generate basic CMakeLists.txt with auto-detection",
		complete = function()
			return { utils.get_project_name "" }
		end,
	})

	vim.api.nvim_create_user_command("GenCMakeAdvanced", function(cmd_opts)
		local options = {}

		for _, arg in ipairs(cmd_opts.fargs) do
			if arg:match "^name=" then
				options.name = arg:match "^name=(.+)"
			elseif arg == "recursive" then
				options.recursive = true
			elseif arg == "debug" then
				options.debug = true
			elseif arg == "release" then
				options.debug = false
			elseif arg == "tests" then
				options.with_tests = true
			elseif arg == "subdirs" then
				options.with_subdirs = true
			elseif arg == "examples" then
				options.with_examples = true
			elseif arg == "install" then
				options.with_install = true
			elseif arg == "overwrite" then
				options.overwrite = true
			end
		end

		M.generate_cmake(options)
	end, {
		nargs = "*",
		desc = "Generate advanced CMakeLists.txt with options",
		complete = function()
			return {
				"recursive",
				"debug",
				"release",
				"tests",
				"subdirs",
				"examples",
				"install",
				"overwrite",
				"name=",
			}
		end,
	})

	-- ===== BUILD COMMANDS =====
	vim.api.nvim_create_user_command("CMakeConfigure", function(cmd_opts)
		local args = cmd_opts.fargs
		M.configure_project(args[1], args[2])
	end, {
		nargs = "*",
		desc = "Configure CMake project",
		complete = function()
			return { "Debug", "Release", "RelWithDebInfo", "MinSizeRel" }
		end,
	})

	vim.api.nvim_create_user_command("CMakeBuild", function(cmd_opts)
		local args = vim.split(cmd_opts.args or "", "%s+")
		local target = args[1] ~= "" and args[1] or nil
		local clean_first = vim.tbl_contains(args, "--clean")
		M.build_project(target, clean_first)
	end, {
		nargs = "*",
		desc = "Build CMake project (use --clean for clean build)",
		complete = function()
			return { "all", "clean", "install", "--clean" }
		end,
	})

	vim.api.nvim_create_user_command("CMakeRun", function(cmd_opts)
		local args = vim.split(cmd_opts.args or "", "%s+", { plain = true })
		local target = args[1] ~= "" and args[1] or nil
		local run_args = #args > 1 and table.concat(vim.list_slice(args, 2), " ") or nil
		M.run_project(target, run_args)
	end, {
		nargs = "*",
		desc = "Run CMake project with optional arguments",
	})

	vim.api.nvim_create_user_command("CMakeClean", function()
		M.clean_project()
	end, {
		desc = "Clean CMake build directory",
	})

	-- ===== WORKFLOW COMMANDS =====
	vim.api.nvim_create_user_command("CMakeQuick", function(cmd_opts)
		local args = vim.split(cmd_opts.args or "", "%s+", { plain = true })
		local project_name = args[1] ~= "" and args[1] or nil
		local build_type = args[2] or "Debug"
		local run_args = #args > 2 and table.concat(vim.list_slice(args, 3), " ") or nil
		M.quick_workflow(project_name, build_type, run_args)
	end, {
		nargs = "*",
		desc = "Quick workflow: Generate + Configure + Build + Run",
		complete = function()
			return { utils.get_project_name "", "Debug", "Release" }
		end,
	})

	-- ===== UTILITY COMMANDS =====
	vim.api.nvim_create_user_command("CMakeInstall", function()
		M.install_project()
	end, {
		desc = "Install CMake project",
	})

	vim.api.nvim_create_user_command("CMakeTest", function()
		M.test_project()
	end, {
		desc = "Run CMake tests with parallel execution",
	})

	vim.api.nvim_create_user_command("CMakeStatus", function()
		M.status()
	end, {
		desc = "Show comprehensive CMake project status",
	})

	-- ===== CONFIGURATION COMMANDS =====
	vim.api.nvim_create_user_command("CMakeConfig", function(cmd_opts)
		if cmd_opts.args == "" then
			-- Show current configuration
			print "📋 Current CMake Configuration"
			print("=" .. string.rep("=", 50))
			print("Extensions: " .. table.concat(config.extensions, ", "))
			print("CMake Version: " .. config.cmake.version)
			print("C++ Standard: " .. config.cmake.cxx_standard)
			print("Build Directory: " .. config.build.directory)
			print("Build Type: " .. config.build.build_type)
			print("Parallel Jobs: " .. (config.build.parallel_jobs or "auto (" .. utils.get_parallel_jobs() .. ")"))
			print("Generator: " .. (config.build.generator or "auto"))
			print("Close Terminal on Success: " .. tostring(config.terminal.close_on_success))
			print("Show Progress: " .. tostring(config.terminal.show_progress))
			print("Notifications: " .. tostring(config.notifications.enabled))
		else
			-- Update configuration
			local key, value = cmd_opts.args:match "([^=]+)=(.+)"
			if key and value then
				local updated = false

				if key == "extensions" then
					config.extensions = vim.split(value, ",")
					updated = true
				elseif key == "cmake_version" then
					config.cmake.version = value
					updated = true
				elseif key == "cxx_standard" then
					config.cmake.cxx_standard = value
					updated = true
				elseif key == "build_dir" then
					config.build.directory = value
					updated = true
				elseif key == "build_type" then
					if vim.tbl_contains({ "Debug", "Release", "RelWithDebInfo", "MinSizeRel" }, value) then
						config.build.build_type = value
						updated = true
					else
						utils.notify(
							"Invalid build type. Use: Debug, Release, RelWithDebInfo, MinSizeRel",
							vim.log.levels.ERROR
						)
					end
				elseif key == "jobs" then
					local jobs = tonumber(value)
					if jobs and jobs > 0 then
						config.build.parallel_jobs = jobs
						updated = true
					else
						utils.notify("Invalid job count. Must be a positive number", vim.log.levels.ERROR)
					end
				elseif key == "generator" then
					config.build.generator = value ~= "auto" and value or nil
					updated = true
				elseif key == "close_on_success" then
					config.terminal.close_on_success = value:lower() == "true"
					updated = true
				elseif key == "show_progress" then
					config.terminal.show_progress = value:lower() == "true"
					updated = true
				elseif key == "notifications" then
					config.notifications.enabled = value:lower() == "true"
					updated = true
				else
					utils.notify("Unknown configuration key: " .. key, vim.log.levels.ERROR)
				end

				if updated then
					utils.notify("Updated " .. key .. " to " .. tostring(value), vim.log.levels.INFO)
				end
			else
				utils.notify("Invalid format. Use: key=value", vim.log.levels.ERROR)
			end
		end
	end, {
		nargs = "?",
		desc = "Show or update CMake configuration",
		complete = function()
			return {
				"extensions=cpp,cxx,cc,c",
				"cmake_version=3.10",
				"cxx_standard=23",
				"build_dir=build",
				"build_type=Debug",
				"jobs=4",
				"generator=auto",
				"close_on_success=false",
				"show_progress=true",
				"notifications=true",
			}
		end,
	})

	vim.api.nvim_create_user_command("CMakeConfigReset", function()
		M.reset_config()
	end, {
		desc = "Reset CMake configuration to defaults",
	})

	-- ===== PRESET COMMANDS =====
	vim.api.nvim_create_user_command("CMakePreset", function(cmd_opts)
		local preset = cmd_opts.args

		if preset == "cpp_basic" then
			M.update_config {
				extensions = { "cpp", "hpp", "h" },
				cmake = { cxx_standard = "17" },
				template = { with_subdirs = false, with_tests = false },
			}
			utils.notify("Applied C++ basic preset", vim.log.levels.INFO)
		elseif preset == "cpp_advanced" then
			M.update_config {
				extensions = { "cpp", "cxx", "hpp", "hxx", "h" },
				cmake = { cxx_standard = "23" },
				template = { with_subdirs = true, with_tests = true },
				build = { build_type = "Debug" },
			}
			utils.notify("Applied C++ advanced preset", vim.log.levels.INFO)
		elseif preset == "c_project" then
			M.update_config {
				extensions = { "c", "h" },
				cmake = { cxx_standard = "11" }, -- CMake still uses CXX_STANDARD for C projects
				template = { with_subdirs = false, with_tests = false },
			}
			utils.notify("Applied C project preset", vim.log.levels.INFO)
		elseif preset == "library" then
			M.update_config {
				template = { with_subdirs = true, with_tests = true, with_examples = true },
				build = { build_type = "Release" },
			}
			utils.notify("Applied library project preset", vim.log.levels.INFO)
		else
			print "Available presets:"
			print "  cpp_basic   - Basic C++ project"
			print "  cpp_advanced - Advanced C++ project with subdirs and tests"
			print "  c_project   - C project configuration"
			print "  library     - Library project with examples and tests"
		end
	end, {
		nargs = 1,
		desc = "Apply configuration preset",
		complete = function()
			return { "cpp_basic", "cpp_advanced", "c_project", "library" }
		end,
	})

	-- ===== KEYMAPS (Optional) =====
	-- Users can override these in their config
	if config.keymaps and config.keymaps.enabled then
		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true })
		end

		local prefix = config.keymaps.prefix or "<leader>c"

		map("n", prefix .. "g", M.generate_cmake, "Generate CMakeLists.txt")
		map("n", prefix .. "c", M.configure_project, "Configure project")
		map("n", prefix .. "b", M.build_project, "Build project")
		map("n", prefix .. "r", M.run_project, "Run project")
		map("n", prefix .. "q", M.quick_workflow, "Quick workflow")
		map("n", prefix .. "t", M.test_project, "Run tests")
		map("n", prefix .. "s", M.status, "Show status")
		map("n", prefix .. "x", M.clean_project, "Clean project")
	end

	-- ===== AUTO-COMMANDS =====
	-- Auto-generate CMakeLists.txt when entering a directory with source files but no CMakeLists.txt
	if config.auto_generate and config.auto_generate.enabled then
		vim.api.nvim_create_autocmd("DirChanged", {
			pattern = "*",
			callback = function()
				if not utils.file_exists "CMakeLists.txt" then
					local sources = utils.scan_source_files(config.extensions, false)
					if not vim.tbl_isempty(sources) then
						if config.auto_generate.prompt then
							local choice =
								vim.fn.confirm("Source files found but no CMakeLists.txt. Generate?", "&Yes\n&No", 2)
							if choice == 1 then
								M.generate_cmake()
							end
						else
							M.generate_cmake()
						end
					end
				end
			end,
		})
	end

	utils.notify("CMake plugin loaded successfully", vim.log.levels.INFO, "CMake")
end

-- ========================================
-- ADDITIONAL UTILITY FUNCTIONS
-- ========================================

-- Get CMake cache variables
function M.get_cache_vars()
	local build_dir = config.build.directory
	local cache_file = build_dir .. "/CMakeCache.txt"

	if not utils.file_exists(cache_file) then
		return {}
	end

	local vars = {}
	local lines = vim.fn.readfile(cache_file)

	for _, line in ipairs(lines) do
		local key, type_info, value = line:match "^([^:]+):([^=]+)=(.*)$"
		if key and not key:match "^//" and not key:match "^#" then
			vars[key] = { type = type_info, value = value }
		end
	end

	return vars
end

-- Switch build type quickly
function M.switch_build_type(build_type)
	if not vim.tbl_contains({ "Debug", "Release", "RelWithDebInfo", "MinSizeRel" }, build_type) then
		utils.notify("Invalid build type: " .. build_type, vim.log.levels.ERROR)
		return false
	end

	config.build.build_type = build_type
	utils.notify("Switched to " .. build_type .. " build type", vim.log.levels.INFO)

	-- Optionally reconfigure
	if utils.dir_exists(config.build.directory) then
		local choice = vim.fn.confirm("Reconfigure project with new build type?", "&Yes\n&No", 1)
		if choice == 1 then
			M.configure_project(build_type)
		end
	end

	return true
end

-- Export for use by other plugins or user configuration
M.utils = utils
M.terminal = terminal
M.cmake_gen = cmake_gen

return M
