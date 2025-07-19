local M = {}

-- Configuration
local config = {
    extensions = { "cpp", "cxx", "cc", "c" },
    cmake_version = "3.10",
    cxx_standard = "23",
    template = {
        basic = true,
        with_subdirs = false,
        with_tests = false,
    },
    -- Build configuration
    build = {
        directory = "build",
        generator = nil,
        build_type = "Debug",
        auto_build = false,
        auto_run = false,
        jobs = nil,
    },
    -- Terminal configuration
    terminal = {
        width_ratio = 0.9,
        height_ratio = 0.7,
        max_width = 140,
        max_height = 30,
        border = "rounded",
        close_on_success = false,
        show_progress = true,
    },
}

-- ========================
-- Terminal utility function
-- ========================
local function get_terminal_size()
    local W, H = vim.o.columns, vim.o.lines
    local cfg = config.terminal

    return {
        width = math.min(cfg.max_width, math.floor(W * cfg.width_ratio)),
        height = math.min(cfg.max_height, math.floor(H * cfg.height_ratio)),
    }
end

-- Terminal function
local function open_floating_terminal(commands, opts)
    opts = opts or {}
    local size = get_terminal_size()
    local W, H = vim.o.columns, vim.o.lines

    -- Create buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

    -- Create window
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "editor",
        style = "minimal",
        border = config.terminal.border,
        width = size.width,
        height = size.height,
        col = math.floor((W - size.width) / 2),
        row = math.floor((H - size.height) / 2),
        title = opts.title or " CMake ",
        title_pos = "center",
    })

    -- Set window options
    vim.api.nvim_win_set_option(win, "winhl", "Normal:Normal,FloatBorder:FloatBorder")

    -- Track state
    local state = {
        force_close = false,
        current_job_id = nil,
        commands_completed = 0,
        total_commands = 0,
    }

    -- Set key mappings for closing
    local close_keys = { "q", "<Esc>" }
    for _, key in ipairs(close_keys) do
        vim.keymap.set({ "n", "t" }, key, function()
            state.force_close = true
            if state.current_job_id then
                vim.fn.jobstop(state.current_job_id)
            end
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
        end, { buffer = buf, nowait = true, silent = true })
    end

    -- If it's a single command, convert to command list format
    if type(commands) == "string" then
        commands = { { cmd = commands, name = "Execute" } }
    elseif commands.cmd then
        commands = { commands }
    end

    state.total_commands = #commands

    -- Function to execute multiple commands
    local function execute_commands(cmd_list, index)
        index = index or 1
        if index > #cmd_list or state.force_close then
            return
        end

        local current_cmd = cmd_list[index]
        local is_last = index == #cmd_list

        -- Construct full shell script
        local shell_script = {}

        -- Add progress display
        if config.terminal.show_progress then
            table.insert(
                shell_script,
                string.format(
                    'echo -e "\\033[1;36m[%d/%d] %s\\033[0m"',
                    index,
                    #cmd_list,
                    current_cmd.name or "Executing"
                )
            )
        end

        -- Add actual command
        table.insert(shell_script, current_cmd.cmd)

        -- Combine into one script
        local combined_cmd = table.concat(shell_script, " && ")

        -- Start task
        local job_id = vim.fn.termopen(combined_cmd, {
            on_exit = function(_, code)
                if state.force_close then
                    return
                end

                vim.schedule(function()
                    state.commands_completed = state.commands_completed + 1

                    if code == 0 then
                        local msg = current_cmd.success_msg or ("Step " .. index .. " completed")
                        vim.notify("✓ " .. msg, vim.log.levels.INFO)

                        if not is_last then
                            vim.defer_fn(function()
                                if not state.force_close and vim.api.nvim_buf_is_valid(buf) then
                                    execute_commands(cmd_list, index + 1)
                                end
                            end, 1000)
                        else
                            if opts.final_success_msg then
                                vim.notify("🎉 " .. opts.final_success_msg, vim.log.levels.INFO)
                            end

                            if config.terminal.close_on_success then
                                vim.defer_fn(function()
                                    if vim.api.nvim_win_is_valid(win) and not state.force_close then
                                        vim.api.nvim_win_close(win, true)
                                    end
                                end, 3000)
                            end
                        end
                    else
                        local msg = current_cmd.error_msg or ("Step " .. index .. " failed")
                        vim.notify(("✗ %s (exit code: %d)"):format(msg, code), vim.log.levels.ERROR)
                    end

                    -- Clear current job ID
                    state.current_job_id = nil
                end)
            end,
        })

        if job_id == 0 then
            vim.notify("Failed to start terminal job", vim.log.levels.ERROR)
            return
        end

        state.current_job_id = job_id
    end

    -- Start executing command sequence
    execute_commands(commands)
    vim.cmd.startinsert()

    return win, buf
end

-- ========================
-- Single command terminal execution function
-- ========================
local function open_simple_terminal(cmd, title, success_msg, error_msg)
    local size = get_terminal_size()
    local W, H = vim.o.columns, vim.o.lines

    -- Create buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")

    -- Create window
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

    -- Set window options
    vim.api.nvim_win_set_option(win, "winhl", "Normal:Normal,FloatBorder:FloatBorder")

    -- Track state
    local job_id = nil

    -- Set key mappings for closing
    local close_keys = { "q", "<Esc>" }
    for _, key in ipairs(close_keys) do
        vim.keymap.set({ "n", "t" }, key, function()
            if job_id then
                vim.fn.jobstop(job_id)
            end
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
        end, { buffer = buf, nowait = true, silent = true })
    end

    -- Start terminal job
    job_id = vim.fn.termopen(cmd, {
        on_exit = function(_, code)
            vim.schedule(function()
                if code == 0 then
                    if success_msg then
                        vim.notify("✓ " .. success_msg, vim.log.levels.INFO)
                    end

                    if config.terminal.close_on_success then
                        vim.defer_fn(function()
                            if vim.api.nvim_win_is_valid(win) then
                                vim.api.nvim_win_close(win, true)
                            end
                        end, 3000)
                    end
                else
                    if error_msg then
                        vim.notify(("✗ %s (exit code: %d)"):format(error_msg, code), vim.log.levels.ERROR)
                    end
                end
            end)
        end,
    })

    if job_id == 0 then
        vim.notify("Failed to start terminal", vim.log.levels.ERROR)
        if vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, true)
        end
        return false
    end

    vim.cmd.startinsert()
    return win, buf
end

-- ========================
-- Existing utility functions
-- ========================
local function scan_source_files(extensions, recursive)
    local files = {}
    local pattern = recursive and "**/*." or "*."

    for _, ext in ipairs(extensions) do
        local found = vim.fn.glob(pattern .. ext, false, true)
        vim.list_extend(files, found)
    end

    table.sort(files)
    return files
end

local function get_project_name(custom_name)
    if custom_name and custom_name ~= "" then
        return custom_name
    end
    return vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
end

local function generate_cmake_content(project_name, sources, options)
    local lines = {
        "cmake_minimum_required(VERSION " .. config.cmake_version .. ")",
        "project(" .. project_name .. ")",
        "",
        "# Set C++ standard",
        "set(CMAKE_CXX_STANDARD " .. config.cxx_standard .. ")",
        "set(CMAKE_CXX_STANDARD_REQUIRED ON)",
        "set(CMAKE_CXX_EXTENSIONS OFF)",
        "",
    }

    -- Add compiler flags
    if options.debug then
        table.insert(lines, "# Debug configuration")
        table.insert(lines, "set(CMAKE_BUILD_TYPE Debug)")
        table.insert(lines, 'set(CMAKE_CXX_FLAGS_DEBUG "-g -O0 -Wall -Wextra")')
        table.insert(lines, "")
    end

    -- Add executable
    table.insert(lines, "# Add executable")
    table.insert(lines, "add_executable(" .. project_name)

    for _, src in ipairs(sources) do
        table.insert(lines, "    " .. src)
    end
    table.insert(lines, ")")

    -- Add optional features
    if options.with_tests then
        table.insert(lines, "")
        table.insert(lines, "# Enable testing")
        table.insert(lines, "enable_testing()")
        table.insert(lines, "add_subdirectory(tests)")
    end

    if options.with_subdirs then
        table.insert(lines, "")
        table.insert(lines, "# Add subdirectories")
        table.insert(lines, "# add_subdirectory(src)")
        table.insert(lines, "# add_subdirectory(include)")
    end

    return lines
end

local function write_cmake_file(content, overwrite)
    local path = vim.fn.getcwd() .. "/CMakeLists.txt"

    if vim.fn.filereadable(path) == 1 and not overwrite then
        local choice =
            vim.fn.confirm("CMakeLists.txt already exists. Overwrite?", "&Yes\n&No\n&Backup", 2)

        if choice == 2 then
            vim.notify("CMakeLists.txt generation cancelled", vim.log.levels.INFO)
            return false
        elseif choice == 3 then
            local backup_path = path .. ".bak"
            vim.fn.rename(path, backup_path)
            vim.notify("Backup created: " .. backup_path, vim.log.levels.INFO)
        end
    end

    local success = pcall(vim.fn.writefile, content, path)
    if success then
        vim.notify("Generated CMakeLists.txt at " .. path, vim.log.levels.INFO)
        return true
    else
        vim.notify("Failed to write CMakeLists.txt", vim.log.levels.ERROR)
        return false
    end
end

-- ========================
-- Existing utility functions
-- ========================
function M.configure_project(build_type, generator)
    local build_dir = config.build.directory
    build_type = build_type or config.build.build_type

    -- Ensure build directory exists
    vim.fn.mkdir(build_dir, "p")

    -- Construct cmake command
    local cmd_parts = { "cmake" }
    table.insert(cmd_parts, "-DCMAKE_BUILD_TYPE=" .. build_type)
    table.insert(cmd_parts, "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON")

    if generator then
        table.insert(cmd_parts, "-G")
        table.insert(cmd_parts, vim.fn.shellescape(generator))
    end

    table.insert(cmd_parts, "..")

    -- Use cd command to switch to build directory
    local full_cmd =
        string.format("cd %s && %s", vim.fn.shellescape(build_dir), table.concat(cmd_parts, " "))

    open_simple_terminal(
        full_cmd,
        " CMake Configure ",
        "Project configured successfully",
        "Project configuration failed"
    )
end

function M.build_project(target)
    local build_dir = config.build.directory

    if vim.fn.isdirectory(build_dir) == 0 then
        vim.notify("Build directory not found. Run :CMakeConfigure first", vim.log.levels.ERROR)
        return false
    end

    local cmd_parts = { "cmake", "--build", vim.fn.shellescape(build_dir) }

    if target then
        table.insert(cmd_parts, "--target")
        table.insert(cmd_parts, target)
    end

    -- Parallel build
    if config.build.jobs then
        table.insert(cmd_parts, "--parallel")
        table.insert(cmd_parts, tostring(config.build.jobs))
    elseif vim.fn.has("unix") == 1 then
        local nproc = vim.fn.system("nproc 2>/dev/null || echo 4"):gsub("%s+", "")
        table.insert(cmd_parts, "--parallel")
        table.insert(cmd_parts, nproc)
    end

    local cmd = table.concat(cmd_parts, " ")

    open_simple_terminal(cmd, " CMake Build ", "Build completed successfully", "Build failed")
end

function M.run_project(target)
    local build_dir = config.build.directory
    local project_name = target or get_project_name("")
    local executable_path = nil

    -- Try common executable paths
    local common_paths = {
        build_dir .. "/" .. project_name,
        build_dir .. "/Debug/" .. project_name,
        build_dir .. "/Release/" .. project_name,
        build_dir .. "/bin/" .. project_name,
    }

    for _, path in ipairs(common_paths) do
        if vim.fn.executable(path) == 1 then
            executable_path = path
            break
        end
    end

    if not executable_path then
        vim.notify("Executable not found for project: " .. project_name, vim.log.levels.ERROR)
        vim.notify("Searched paths: " .. table.concat(common_paths, ", "), vim.log.levels.DEBUG)
        return false
    end

    open_simple_terminal(
        vim.fn.shellescape(executable_path),
        " Run Project ",
        "Program execution completed",
        "Program execution failed"
    )
end

-- ========================
-- One-click workflow functions
-- ========================
function M.quick_workflow(project_name, build_type)
    project_name = project_name or get_project_name("")
    build_type = build_type or config.build.build_type
    local build_dir = config.build.directory

    -- Check source files
    local sources = scan_source_files(config.extensions, false)
    if vim.tbl_isempty(sources) then
        vim.notify("No source files found in current directory", vim.log.levels.WARN)
        return false
    end

    -- Generate CMakeLists.txt
    local content = generate_cmake_content(project_name, sources, { debug = build_type == "Debug" })
    if not write_cmake_file(content, true) then
        return false
    end

    -- Create build directory
    vim.fn.mkdir(build_dir, "p")

    -- Build full command script
    local script_lines = {
        "#!/bin/bash",
        "set -e",
        "",
        'echo -e "\\033[1;36m[1/3] Configuring project...\\033[0m"',
        string.format("cd %s", vim.fn.shellescape(build_dir)),
        string.format("cmake -DCMAKE_BUILD_TYPE=%s -DCMAKE_EXPORT_COMPILE_COMMANDS=ON ..", build_type),
        "",
        'echo -e "\\033[1;36m[2/3] Building project...\\033[0m"',
        "cmake --build . --parallel",
        "",
        'echo -e "\\033[1;36m[3/3] Running project...\\033[0m"',
        string.format("./%s", project_name),
    }

    -- Create temporary script file
    local script_content = table.concat(script_lines, "\n")
    local tmp_script = vim.fn.tempname() .. "_cmake_workflow.sh"
    vim.fn.writefile(vim.split(script_content, "\n"), tmp_script)
    vim.fn.setfperm(tmp_script, "rwx------")

    -- Execute script
    open_simple_terminal(
        "bash " .. vim.fn.shellescape(tmp_script) .. "; rm -f " .. vim.fn.shellescape(tmp_script),
        " CMake Quick Workflow ",
        "🚀 Complete workflow finished successfully!",
        "Workflow failed"
    )
end

function M.clean_project()
    local build_dir = config.build.directory

    if vim.fn.isdirectory(build_dir) == 0 then
        vim.notify("Build directory not found", vim.log.levels.WARN)
        return false
    end

    open_simple_terminal(
        "rm -rf " .. vim.fn.shellescape(build_dir) .. " && echo 'Build directory cleaned'",
        " CMake Clean ",
        "Build directory cleaned successfully",
        "Clean operation failed"
    )
end

-- ========================
-- Other utility features
-- ========================
function M.install_project()
    local build_dir = config.build.directory

    if vim.fn.isdirectory(build_dir) == 0 then
        vim.notify("Build directory not found. Build project first", vim.log.levels.ERROR)
        return false
    end

    open_simple_terminal(
        "cmake --build " .. vim.fn.shellescape(build_dir) .. " --target install",
        " CMake Install ",
        "Project installed successfully",
        "Installation failed"
    )
end

function M.test_project()
    local build_dir = config.build.directory

    if vim.fn.isdirectory(build_dir) == 0 then
        vim.notify("Build directory not found. Build project first", vim.log.levels.ERROR)
        return false
    end

    open_simple_terminal(
        string.format("cd %s && ctest --output-on-failure", vim.fn.shellescape(build_dir)),
        " CMake Test ",
        "All tests passed",
        "Some tests failed"
    )
end

-- Project status check
function M.status()
    local cwd = vim.fn.getcwd()
    local build_dir = config.build.directory
    local cmake_file = cwd .. "/CMakeLists.txt"

    print("📋 CMake Project Status:")
    print("  📁 Project Directory: " .. cwd)
    print(
        "  📋 CMakeLists.txt: "
        .. (vim.fn.filereadable(cmake_file) == 1 and "✅ Found" or "❌ Missing")
    )
    print(
        "  🏗️  Build Directory: "
        .. build_dir
        .. " "
        .. (vim.fn.isdirectory(build_dir) == 1 and "✅ Exists" or "❌ Missing")
    )

    if vim.fn.isdirectory(build_dir) == 1 then
        local cache_file = build_dir .. "/CMakeCache.txt"
        print(
            "  ⚙️  CMake Cache: "
            .. (vim.fn.filereadable(cache_file) == 1 and "✅ Configured" or "❌ Not configured")
        )

        -- Check executable files
        local project_name = get_project_name("")
        local executable_paths = {
            build_dir .. "/" .. project_name,
            build_dir .. "/Debug/" .. project_name,
            build_dir .. "/Release/" .. project_name,
        }

        local executable_found = false
        for _, path in ipairs(executable_paths) do
            if vim.fn.executable(path) == 1 then
                print("  🚀 Executable: ✅ " .. path)
                executable_found = true
                break
            end
        end

        if not executable_found then
            print("  🚀 Executable: ❌ Not found")
        end
    end

    -- Show current configuration
    print("\n⚙️  Current Configuration:")
    print("  Build Type: " .. config.build.build_type)
    print("  C++ Standard: " .. config.cxx_standard)
    print("  CMake Version: " .. config.cmake_version)
end

-- ========================
-- Main functional functions
-- ========================
function M.generate_cmake(opts)
    local options = vim.tbl_extend("force", {
        name = "",
        recursive = false,
        debug = false,
        with_tests = false,
        with_subdirs = false,
        overwrite = false,
    }, opts or {})

    local sources = scan_source_files(config.extensions, options.recursive)

    if vim.tbl_isempty(sources) then
        vim.notify("No source files found in current directory", vim.log.levels.WARN)
        return false
    end

    local project_name = get_project_name(options.name)
    local content = generate_cmake_content(project_name, sources, options)

    return write_cmake_file(content, options.overwrite)
end

-- ========================
-- Configuration update function
-- ========================
function M.update_config(new_config)
    config = vim.tbl_deep_extend("force", config, new_config or {})
end

function M.get_config()
    return vim.deepcopy(config)
end

-- ========================
-- Configuration update function
-- ========================
function M.setup(user_config)
    -- Get configuration
    if user_config then
        M.update_config(user_config)
    end

    -- Basic generate command
    vim.api.nvim_create_user_command("GenCMake", function(cmd_opts)
        M.generate_cmake({ name = cmd_opts.args })
    end, {
        nargs = "?",
        desc = "Generate basic CMakeLists.txt (optional project name)",
    })

    vim.api.nvim_create_user_command("GenCMakeAdvanced", function(cmd_opts)
        local options = {}

        for _, arg in ipairs(cmd_opts.fargs) do
            if arg:match("^name=") then
                options.name = arg:match("^name=(.+)")
            elseif arg == "recursive" then
                options.recursive = true
            elseif arg == "debug" then
                options.debug = true
            elseif arg == "tests" then
                options.with_tests = true
            elseif arg == "subdirs" then
                options.with_subdirs = true
            elseif arg == "overwrite" then
                options.overwrite = true
            end
        end

        M.generate_cmake(options)
    end, {
        nargs = "*",
        desc = "Generate advanced CMakeLists.txt",
        complete = function()
            return { "recursive", "debug", "tests", "subdirs", "overwrite", "name=" }
        end,
    })

    -- Build command
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
        M.build_project(cmd_opts.args ~= "" and cmd_opts.args or nil)
    end, {
        nargs = "?",
        desc = "Build CMake project",
    })

    vim.api.nvim_create_user_command("CMakeRun", function(cmd_opts)
        M.run_project(cmd_opts.args ~= "" and cmd_opts.args or nil)
    end, {
        nargs = "?",
        desc = "Run CMake project",
    })

    vim.api.nvim_create_user_command("CMakeClean", function()
        M.clean_project()
    end, {
        desc = "Clean CMake build directory",
    })

    -- One-click command
    vim.api.nvim_create_user_command("CMakeQuick", function(cmd_opts)
        local args = vim.split(cmd_opts.args or "", "%s+")
        local project_name = args[1] ~= "" and args[1] or nil
        local build_type = args[2] or "Debug"
        M.quick_workflow(project_name, build_type)
    end, {
        nargs = "*",
        desc = "Quick workflow: Generate + Configure + Build + Run",
        complete = function()
            return { get_project_name(""), "Debug", "Release" }
        end,
    })

    -- Utility commands
    vim.api.nvim_create_user_command("CMakeInstall", function()
        M.install_project()
    end, {
        desc = "Install CMake project",
    })

    vim.api.nvim_create_user_command("CMakeTest", function()
        M.test_project()
    end, {
        desc = "Run CMake tests",
    })

    vim.api.nvim_create_user_command("CMakeStatus", function()
        M.status()
    end, {
        desc = "Show CMake project status",
    })

    -- Config commands
    vim.api.nvim_create_user_command("CMakeConfig", function(cmd_opts)
        if cmd_opts.args == "" then
            print("Current CMake Configuration:")
            print("  Extensions: " .. table.concat(config.extensions, ", "))
            print("  CMake Version: " .. config.cmake_version)
            print("  C++ Standard: " .. config.cxx_standard)
            print("  Build Directory: " .. config.build.directory)
            print("  Build Type: " .. config.build.build_type)
            print("  Parallel Jobs: " .. (config.build.jobs or "auto"))
            print("  Close on Success: " .. tostring(config.terminal.close_on_success))
        else
            local key, value = cmd_opts.args:match("([^=]+)=(.+)")
            if key and value then
                if key == "extensions" then
                    config.extensions = vim.split(value, ",")
                elseif key == "cmake_version" then
                    config.cmake_version = value
                elseif key == "cxx_standard" then
                    config.cxx_standard = value
                elseif key == "build_dir" then
                    config.build.directory = value
                elseif key == "build_type" then
                    config.build.build_type = value
                elseif key == "jobs" then
                    config.build.jobs = tonumber(value)
                elseif key == "close_on_success" then
                    config.terminal.close_on_success = value == "true"
                end
                vim.notify("Updated " .. key .. " to " .. value, vim.log.levels.INFO)
            end
        end
    end, {
        nargs = "?",
        desc = "Configure CMake generator",
    })

    -- vim.notify("CMake plugin loaded successfully! 🚀", vim.log.levels.INFO)
end

return M
