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
}

-- Utility functions
local function scan_source_files(extensions, recursive)
    local files = {}
    local pattern = recursive and "**/*." or "*."

    for _, ext in ipairs(extensions) do
        local found = vim.fn.glob(pattern .. ext, false, true)
        vim.list_extend(files, found)
    end

    -- Sort files for consistent output
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

    -- Check if file exists
    if vim.fn.filereadable(path) == 1 and not overwrite then
        local choice =
            vim.fn.confirm("CMakeLists.txt already exists. Overwrite?", "&Yes\n&No\n&Backup", 2)

        if choice == 2 then -- No
            vim.notify("CMakeLists.txt generation cancelled", vim.log.levels.INFO)
            return false
        elseif choice == 3 then -- Backup
            local backup_path = path .. ".bak"
            vim.fn.rename(path, backup_path)
            vim.notify("Backup created: " .. backup_path, vim.log.levels.INFO)
        end
    end

    -- Write file
    local success = pcall(vim.fn.writefile, content, path)
    if success then
        vim.notify("Generated CMakeLists.txt at " .. path, vim.log.levels.INFO)
        return true
    else
        vim.notify("Failed to write CMakeLists.txt", vim.log.levels.ERROR)
        return false
    end
end

-- Main functions
function M.generate_cmake(opts)
    local options = vim.tbl_extend("force", {
        name = "",
        recursive = false,
        debug = false,
        with_tests = false,
        with_subdirs = false,
        overwrite = false,
    }, opts or {})

    -- Find source files
    local sources = scan_source_files(config.extensions, options.recursive)

    if vim.tbl_isempty(sources) then
        vim.notify("No source files found in current directory", vim.log.levels.WARN)
        return false
    end

    -- Generate content
    local project_name = get_project_name(options.name)
    local content = generate_cmake_content(project_name, sources, options)

    -- Write file
    return write_cmake_file(content, options.overwrite)
end

function M.setup()
    -- Basic command
    vim.api.nvim_create_user_command("GenCMake", function(cmd_opts)
        M.generate_cmake({ name = cmd_opts.args })
    end, {
        nargs = "?",
        desc = "Generate basic CMakeLists.txt (optional project name)",
    })

    -- Advanced command with options
    vim.api.nvim_create_user_command("GenCMakeAdvanced", function(cmd_opts)
        local options = {}

        -- Parse arguments
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
        desc = "Generate advanced CMakeLists.txt (name=<name> recursive debug tests subdirs overwrite)",
        complete = function()
            return { "recursive", "debug", "tests", "subdirs", "overwrite", "name=" }
        end,
    })

    -- Configuration command
    vim.api.nvim_create_user_command("CMakeConfig", function(cmd_opts)
        if cmd_opts.args == "" then
            -- Show current config
            print("Current CMake Generator Configuration:")
            print("  Extensions: " .. table.concat(config.extensions, ", "))
            print("  CMake Version: " .. config.cmake_version)
            print("  C++ Standard: " .. config.cxx_standard)
        else
            -- Set configuration
            local key, value = cmd_opts.args:match("([^=]+)=(.+)")
            if key and value then
                if key == "extensions" then
                    config.extensions = vim.split(value, ",")
                elseif key == "cmake_version" then
                    config.cmake_version = value
                elseif key == "cxx_standard" then
                    config.cxx_standard = value
                end
                vim.notify("Updated " .. key .. " to " .. value, vim.log.levels.INFO)
            end
        end
    end, {
        nargs = "?",
        desc = "Configure CMake generator (key=value or empty to show config)",
    })
end

return M
