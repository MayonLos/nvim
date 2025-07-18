local M = {}

-- ========================
-- Configuration
-- ========================
M.config = {
    terminal = {
        width_ratio = 0.8,
        height_ratio = 0.4,
        max_width = 120,
        max_height = 20,
        border = "rounded",
    },
    auto_save = true,
    show_success_message = true,
    common_flags = { "-g", "-Wall" },
}

-- ========================
-- Utility Functions
-- ========================
local function extend_table(dst, src)
    for _, v in ipairs(src) do
        dst[#dst + 1] = v
    end
    return dst
end

local function shellescape_list(list)
    local escaped = {}
    for _, v in ipairs(list) do
        escaped[#escaped + 1] = vim.fn.shellescape(v)
    end
    return escaped
end

local function get_terminal_size()
    local W, H = vim.o.columns, vim.o.lines
    local cfg = M.config.terminal

    return {
        width = math.min(cfg.max_width, math.floor(W * cfg.width_ratio)),
        height = math.min(cfg.max_height, math.floor(H * cfg.height_ratio)),
    }
end

-- ========================
-- File Path Utilities
-- ========================
function M.get_file_info()
    local file = {
        path = vim.fn.expand("%:p"),
        name = vim.fn.expand("%:t"),
        base = vim.fn.expand("%:t:r"),
        ext = vim.fn.expand("%:e"):lower(),
        dir = vim.fn.expand("%:p:h"),
    }

    -- Validate file existence
    if file.path == "" or not vim.fn.filereadable(file.path) then
        return nil, "No valid file in current buffer"
    end

    return file
end

-- ========================
-- Floating Terminal Functions
-- ========================
function M.open_floating_terminal(cmd, opts)
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
        border = M.config.terminal.border,
        width = size.width,
        height = size.height,
        col = math.floor((W - size.width) / 2),
        row = math.floor((H - size.height) / 2),
        title = opts.title or " Code Runner ",
        title_pos = "center",
    })

    -- Set window options
    vim.api.nvim_win_set_option(win, "winhl", "Normal:Normal,FloatBorder:FloatBorder")

    -- Set key mappings
    local close_keys = { "q", "<Esc>" }
    for _, key in ipairs(close_keys) do
        vim.keymap.set({ "n", "t" }, key, function()
            if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_win_close(win, true)
            end
        end, { buffer = buf, nowait = true, silent = true })
    end

    -- Start terminal
    local job_id = vim.fn.termopen(cmd, {
        on_exit = function(_, code)
            vim.schedule(function()
                if code == 0 then
                    if M.config.show_success_message then
                        vim.notify("✓ Execution completed successfully", vim.log.levels.INFO)
                    end
                else
                    vim.notify(("✗ Process exited with code %d"):format(code), vim.log.levels.ERROR)
                end
            end)
        end,
        on_stderr = function(_, data)
            if data and #data > 0 then
                vim.schedule(function()
                    -- Add error handling logic here
                end)
            end
        end,
    })

    if job_id == 0 then
        vim.notify("Failed to start terminal", vim.log.levels.ERROR)
        return
    end

    vim.cmd.startinsert()
    return win, buf, job_id
end

-- ========================
-- Compiler Configuration
-- ========================
local function make_compile_args(file, std, extra_flags)
    local args = { file.name, "-std=" .. std }
    extend_table(args, vim.deepcopy(M.config.common_flags))
    if extra_flags then
        extend_table(args, extra_flags)
    end
    extend_table(args, { "-o", file.base })
    return args
end

M.runners = {
    c = {
        cmd = "gcc",
        args = function(file)
            return make_compile_args(file, "c17", { "-lm" })
        end,
        run = function(file)
            return "./" .. file.base
        end,
        description = "C (gcc, c17)",
    },
    cpp = {
        cmd = "g++",
        args = function(file)
            return make_compile_args(file, "c++23", { "-lm" })
        end,
        run = function(file)
            return "./" .. file.base
        end,
        description = "C++ (g++, c++23)",
    },
    cxx = {
        cmd = "g++",
        args = function(file)
            return make_compile_args(file, "c++23", { "-lm" })
        end,
        run = function(file)
            return "./" .. file.base
        end,
        description = "C++ (g++, c++23)",
    },
    py = {
        cmd = "python3",
        args = function(file)
            return { file.name }
        end,
        description = "Python 3",
    },
    python = {
        cmd = "python3",
        args = function(file)
            return { file.name }
        end,
        description = "Python 3",
    },
    js = {
        cmd = "node",
        args = function(file)
            return { file.name }
        end,
        description = "Node.js",
    },
    ts = {
        cmd = "ts-node",
        args = function(file)
            return { file.name }
        end,
        description = "TypeScript",
    },
    lua = {
        cmd = "lua",
        args = function(file)
            return { file.name }
        end,
        description = "Lua",
    },
    go = {
        cmd = "go",
        args = function(file)
            return { "run", file.name }
        end,
        description = "Go",
    },
    rs = {
        cmd = "rustc",
        args = function(file)
            return { file.name, "-o", file.base }
        end,
        run = function(file)
            return "./" .. file.base
        end,
        description = "Rust",
    },
    java = {
        cmd = "javac",
        args = function(file)
            return { file.name }
        end,
        run = function(file)
            return "java " .. file.base
        end,
        description = "Java",
    },
}

-- ========================
-- Compile and Run Logic
-- ========================
function M.compile_and_run()
    -- Auto-save
    if M.config.auto_save and vim.bo.modified then
        vim.cmd.write()
    end

    -- Get file info
    local file, err = M.get_file_info()
    if not file then
        vim.notify(err or "Failed to get file info", vim.log.levels.ERROR)
        return
    end

    -- Check runner
    local runner = M.runners[file.ext]
    if not runner then
        local supported = {}
        for ext, r in pairs(M.runners) do
            table.insert(supported, ext .. " (" .. r.description .. ")")
        end
        table.sort(supported)

        vim.notify(
            ("Unsupported file type: %s\nSupported types:\n%s"):format(
                file.ext,
                table.concat(supported, "\n")
            ),
            vim.log.levels.ERROR
        )
        return
    end

    -- Build command
    local cmd_parts = {
        "cd",
        vim.fn.shellescape(file.dir),
        "&&",
        runner.cmd,
    }

    -- Add arguments
    extend_table(cmd_parts, shellescape_list(runner.args(file)))

    -- Add run command
    if runner.run then
        local run_cmd = type(runner.run) == "function" and runner.run(file) or runner.run
        table.insert(cmd_parts, "&&")
        table.insert(cmd_parts, run_cmd)
    end

    local final_cmd = table.concat(cmd_parts, " ")

    -- Show run info
    vim.notify(("Running: %s"):format(runner.description), vim.log.levels.INFO)

    -- Open floating terminal
    M.open_floating_terminal(final_cmd, {
        title = " " .. runner.description .. " ",
    })
end

-- ========================
-- Setup Function
-- ========================
function M.setup(opts)
    if opts then
        M.config = vim.tbl_deep_extend("force", M.config, opts)
    end

    -- Register user command
    vim.api.nvim_create_user_command("RunCode", function()
        M.compile_and_run()
    end, { desc = "Compile and run current file" })

    -- Optional: Register key mapping
    if M.config.keymap then
        vim.keymap.set("n", M.config.keymap, M.compile_and_run, {
            desc = "Compile and run current file",
            silent = true,
        })
    end
end

-- ========================
-- Public API
-- ========================
function M.add_runner(ext, runner)
    M.runners[ext] = runner
end

function M.get_supported_types()
    local types = {}
    for ext, runner in pairs(M.runners) do
        types[ext] = runner.description
    end
    return types
end

return M
