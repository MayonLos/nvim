return {
    {
        "mfussenegger/nvim-dap",
        dependencies = {
            {
                "rcarriga/nvim-dap-ui",
                dependencies = { "nvim-neotest/nvim-nio" },
                opts = {
                    icons = { expanded = "", collapsed = "", current_frame = "" },
                    mappings = {
                        expand = { "<CR>", "<2-LeftMouse>" },
                        open = "o",
                        remove = "d",
                        edit = "e",
                        repl = "r",
                        toggle = "t",
                    },
                    element_mappings = {
                        stacks = { open = "<CR>", expand = "o" },
                    },
                    layouts = {
                        {
                            elements = {
                                { id = "scopes",      size = 0.30 },
                                { id = "watches",     size = 0.20 },
                                { id = "stacks",      size = 0.25 },
                                { id = "breakpoints", size = 0.25 },
                            },
                            size = 45,
                            position = "left",
                        },
                        {
                            elements = {
                                { id = "repl",    size = 0.6 },
                                { id = "console", size = 0.4 },
                            },
                            size = 0.25,
                            position = "bottom",
                        },
                    },
                    controls = {
                        enabled = true,
                        element = "repl",
                        icons = {
                            pause = "",
                            play = "",
                            step_into = "",
                            step_over = "",
                            step_out = "",
                            step_back = "",
                            run_last = "",
                            terminate = "",
                            disconnect = "",
                        },
                    },
                    floating = {
                        max_height = 0.9,
                        max_width = 0.5,
                        border = "rounded",
                        mappings = { close = { "q", "<Esc>" } },
                    },
                    windows = { indent = 1 },
                    render = {
                        max_type_length = nil,
                        max_value_lines = 100,
                        indent = 1,
                    },
                },
                config = function(_, opts)
                    local dap = require("dap")
                    local dapui = require("dapui")
                    dapui.setup(opts)

                    local function open_dapui()
                        dapui.open()
                        vim.api.nvim_command("DapVirtualTextEnable")
                    end

                    local function close_dapui()
                        dapui.close()
                        vim.api.nvim_command("DapVirtualTextDisable")
                    end

                    dap.listeners.after.event_initialized["dapui_config"] = open_dapui
                    dap.listeners.before.event_terminated["dapui_config"] = close_dapui
                    dap.listeners.before.event_exited["dapui_config"] = close_dapui

                    dap.listeners.after.event_stopped["dapui_config"] = function()
                        vim.schedule(function()
                            if vim.api.nvim_get_mode().mode == "n" then
                                dapui.float_element("scopes", { enter = false })
                            end
                        end)
                    end
                end,
            },
            {
                "theHamsta/nvim-dap-virtual-text",
                opts = {
                    enabled = true,
                    enabled_commands = true,
                    highlight_changed_variables = true,
                    highlight_new_as_changed = false,
                    show_stop_reason = true,
                    commented = true,
                    only_first_definition = true,
                    all_references = false,
                    clear_on_continue = false,
                    display_callback = function(variable, _, _, _, options)
                        return (options.virt_text_pos == "inline" and " = " or variable.name .. " = ")
                            .. variable.value:gsub("%s+", " ")
                    end,
                    virt_text_pos = "eol",
                    all_frames = false,
                    virt_lines = false,
                },
            },
            {
                "nvim-telescope/telescope-dap.nvim",
                config = function()
                    require("telescope").load_extension("dap")
                end,
            },
        },
        keys = {
            -- Debugging
            {
                "<F5>",
                function()
                    local dap = require("dap")
                    if dap.session() then
                        dap.continue()
                    else
                        local filetype = vim.bo.filetype
                        local configs = dap.configurations[filetype]
                        if configs and #configs > 0 then
                            if #configs == 1 then
                                dap.run(configs[1])
                            else
                                require("telescope").extensions.dap.configurations({})
                            end
                        else
                            vim.notify("No DAP configurations for " .. filetype, vim.log.levels.WARN)
                        end
                    end
                end,
                desc = "DAP: Start/Continue",
            },
            {
                "<F9>",
                function()
                    require("dap").toggle_breakpoint()
                end,
                desc = "DAP: Toggle Breakpoint",
            },
            {
                "<F10>",
                function()
                    require("dap").step_over()
                end,
                desc = "DAP: Step Over",
            },
            {
                "<F11>",
                function()
                    require("dap").step_into()
                end,
                desc = "DAP: Step Into",
            },
            {
                "<S-F11>",
                function()
                    require("dap").step_out()
                end,
                desc = "DAP: Step Out",
            },
            {
                "<S-F5>",
                function()
                    require("dap").terminate()
                    require("dapui").close()
                end,
                desc = "DAP: Stop",
            },
            {
                "<C-S-F5>",
                function()
                    require("dap").restart()
                end,
                desc = "DAP: Restart",
            },

            -- Management
            {
                "<leader>dc",
                function()
                    require("telescope").extensions.dap.configurations({})
                end,
                desc = "DAP: Configurations",
            },
            {
                "<leader>db",
                function()
                    require("telescope").extensions.dap.list_breakpoints({})
                end,
                desc = "DAP: List Breakpoints",
            },
            {
                "<leader>dv",
                function()
                    require("telescope").extensions.dap.variables({})
                end,
                desc = "DAP: Variables",
            },
            {
                "<leader>df",
                function()
                    require("telescope").extensions.dap.frames({})
                end,
                desc = "DAP: Frames",
            },
            {
                "<leader>dd",
                function()
                    require("telescope").extensions.dap.commands({})
                end,
                desc = "DAP: Commands",
            },

            -- Breakpoints
            {
                "<leader>dB",
                function()
                    local condition = vim.fn.input("Breakpoint condition: ")
                    if condition and condition ~= "" then
                        require("dap").set_breakpoint(condition)
                    end
                end,
                desc = "DAP: Conditional Breakpoint",
            },
            {
                "<leader>dL",
                function()
                    local message = vim.fn.input("Log point message: ")
                    if message and message ~= "" then
                        require("dap").set_breakpoint(nil, nil, message)
                    end
                end,
                desc = "DAP: Log Point",
            },
            {
                "<leader>dC",
                function()
                    require("dap").clear_breakpoints()
                    vim.notify("All breakpoints cleared", vim.log.levels.INFO)
                end,
                desc = "DAP: Clear All Breakpoints",
            },

            -- UI and Interaction
            {
                "<leader>du",
                function()
                    require("dapui").toggle()
                end,
                desc = "DAP: Toggle UI",
            },
            {
                "<leader>dr",
                function()
                    require("dap").repl.toggle()
                end,
                desc = "DAP: Toggle REPL",
            },
            {
                "<leader>dl",
                function()
                    require("dap").run_last()
                end,
                desc = "DAP: Run Last",
            },
            {
                "<leader>de",
                function()
                    require("dapui").eval()
                end,
                desc = "DAP: Evaluate Expression",
                mode = { "n", "v" },
            },
            {
                "<leader>dE",
                function()
                    local expr = vim.fn.input("Expression: ")
                    if expr and expr ~= "" then
                        require("dapui").eval(expr)
                    end
                end,
                desc = "DAP: Evaluate Input",
            },
            {
                "<leader>dh",
                function()
                    require("dap.ui.widgets").hover()
                end,
                desc = "DAP: Hover Variables",
            },
            {
                "<leader>ds",
                function()
                    local widgets = require("dap.ui.widgets")
                    widgets.sidebar(widgets.scopes).open()
                end,
                desc = "DAP: Scopes Sidebar",
            },
        },
        config = function()
            local dap = require("dap")

            -- Icons with Nerd Fonts
            vim.fn.sign_define(
                "DapBreakpoint",
                { text = "󰃤", texthl = "DapBreakpoint", linehl = "", numhl = "" }
            )
            vim.fn.sign_define(
                "DapBreakpointCondition",
                { text = "", texthl = "DapBreakpointCondition", linehl = "", numhl = "" }
            )
            vim.fn.sign_define(
                "DapBreakpointRejected",
                { text = "", texthl = "DapBreakpointRejected", linehl = "", numhl = "" }
            )
            vim.fn.sign_define(
                "DapStopped",
                { text = "󰁕", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" }
            )
            vim.fn.sign_define(
                "DapLogPoint",
                { text = "󰍛", texthl = "DapLogPoint", linehl = "", numhl = "" }
            )

            -- Highlight groups
            vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = "#e06c75" })
            vim.api.nvim_set_hl(0, "DapBreakpointCondition", { fg = "#e5c07b" })
            vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = "#5c6370" })
            vim.api.nvim_set_hl(0, "DapStopped", { fg = "#98c379" })
            vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#2d3748" })
            vim.api.nvim_set_hl(0, "DapLogPoint", { fg = "#61afef" })

            -- Python
            dap.adapters.python = function(callback, config)
                if config.request == "attach" then
                    local port = (config.connect or config).port
                    local host = (config.connect or config).host or "127.0.0.1"
                    callback({
                        type = "server",
                        port = assert(port, "`connect.port` is required for a python `attach` configuration"),
                        host = host,
                        options = { source_filetype = "python" },
                    })
                else
                    callback({
                        type = "executable",
                        command = "python",
                        args = { "-m", "debugpy.adapter" },
                        options = { source_filetype = "python" },
                    })
                end
            end

            local function get_python_path()
                local cwd = vim.fn.getcwd()
                local venv_paths = {
                    cwd .. "/venv/bin/python",
                    cwd .. "/.venv/bin/python",
                    cwd .. "/env/bin/python",
                    os.getenv("VIRTUAL_ENV") and (os.getenv("VIRTUAL_ENV") .. "/bin/python"),
                }
                for _, path in ipairs(venv_paths) do
                    if path and vim.fn.executable(path) == 1 then
                        return path
                    end
                end
                return vim.fn.exepath("python3") or vim.fn.exepath("python") or "python"
            end

            dap.configurations.python = {
                {
                    type = "python",
                    request = "launch",
                    name = "Launch file",
                    program = "${file}",
                    pythonPath = get_python_path,
                    console = "integratedTerminal",
                    justMyCode = false,
                },
                {
                    type = "python",
                    request = "launch",
                    name = "Launch file with arguments",
                    program = "${file}",
                    args = function()
                        local args_string = vim.fn.input("Arguments: ")
                        return args_string ~= "" and vim.split(args_string, " ") or {}
                    end,
                    pythonPath = get_python_path,
                    console = "integratedTerminal",
                    justMyCode = false,
                },
                {
                    type = "python",
                    request = "attach",
                    name = "Attach remote",
                    connect = function()
                        local host = vim.fn.input("Host [127.0.0.1]: ") or "127.0.0.1"
                        local port = tonumber(vim.fn.input("Port [5678]: ")) or 5678
                        return { host = host, port = port }
                    end,
                },
            }

            -- C/C++
            local function setup_cpp_debugging()
                if vim.fn.executable("codelldb") == 1 then
                    dap.adapters.codelldb = {
                        type = "server",
                        port = "${port}",
                        executable = { command = "codelldb", args = { "--port", "${port}" } },
                    }
                    dap.configurations.cpp = {
                        {
                            name = "Launch (codelldb)",
                            type = "codelldb",
                            request = "launch",
                            program = function()
                                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                            end,
                            cwd = "${workspaceFolder}",
                            stopOnEntry = false,
                            args = function()
                                local args_string = vim.fn.input("Arguments: ")
                                return args_string ~= "" and vim.split(args_string, " ") or {}
                            end,
                            runInTerminal = false,
                        },
                        {
                            name = "Attach to process (codelldb)",
                            type = "codelldb",
                            request = "attach",
                            pid = function()
                                return require("dap.utils").pick_process()
                            end,
                            cwd = "${workspaceFolder}",
                        },
                    }
                elseif vim.fn.executable("lldb-vscode") == 1 then
                    dap.adapters.lldb = {
                        type = "executable",
                        command = "lldb-vscode",
                        name = "lldb",
                    }
                    dap.configurations.cpp = {
                        {
                            name = "Launch (lldb)",
                            type = "lldb",
                            request = "launch",
                            program = function()
                                return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
                            end,
                            cwd = "${workspaceFolder}",
                            stopOnEntry = false,
                            args = function()
                                local args_string = vim.fn.input("Arguments: ")
                                return args_string ~= "" and vim.split(args_string, " ") or {}
                            end,
                            runInTerminal = false,
                        },
                    }
                end
                dap.configurations.c = dap.configurations.cpp
            end
            setup_cpp_debugging()

            -- JavaScript/TypeScript
            dap.adapters.node2 = {
                type = "executable",
                command = "node",
                args = {
                    vim.fn.stdpath("data") .. "/mason/packages/node-debug2-adapter/out/src/nodeDebug.js",
                },
            }
            dap.configurations.javascript = {
                {
                    name = "Launch Node.js",
                    type = "node2",
                    request = "launch",
                    program = "${file}",
                    cwd = vim.fn.getcwd(),
                    sourceMaps = true,
                    protocol = "inspector",
                    console = "integratedTerminal",
                    args = function()
                        local args_string = vim.fn.input("Arguments: ")
                        return args_string ~= "" and vim.split(args_string, " ") or {}
                    end,
                },
                {
                    name = "Attach to Node.js",
                    type = "node2",
                    request = "attach",
                    processId = function()
                        return require("dap.utils").pick_process()
                    end,
                    cwd = vim.fn.getcwd(),
                    sourceMaps = true,
                    protocol = "inspector",
                },
            }
            dap.configurations.typescript = dap.configurations.javascript

            -- Go
            if vim.fn.executable("dlv") == 1 then
                dap.adapters.go = {
                    type = "executable",
                    command = "dlv",
                    args = { "dap", "-l", "127.0.0.1:38697" },
                }
                dap.configurations.go = {
                    {
                        type = "go",
                        name = "Debug",
                        request = "launch",
                        program = "${file}",
                        args = function()
                            local args_string = vim.fn.input("Arguments: ")
                            return args_string ~= "" and vim.split(args_string, " ") or {}
                        end,
                    },
                    {
                        type = "go",
                        name = "Debug test",
                        request = "launch",
                        mode = "test",
                        program = "${file}",
                    },
                    {
                        type = "go",
                        name = "Debug test (go.mod)",
                        request = "launch",
                        mode = "test",
                        program = "./${relativeFileDirname}",
                    },
                    {
                        type = "go",
                        name = "Debug package",
                        request = "launch",
                        program = "${workspaceFolder}",
                        args = function()
                            local args_string = vim.fn.input("Arguments: ")
                            return args_string ~= "" and vim.split(args_string, " ") or {}
                        end,
                    },
                }
            end

            -- User commands
            vim.api.nvim_create_user_command("DapStart", function()
                local filetype = vim.bo.filetype
                local configs = dap.configurations[filetype]
                if configs and #configs > 0 then
                    if #configs == 1 then
                        dap.run(configs[1])
                    else
                        require("telescope").extensions.dap.configurations({})
                    end
                else
                    vim.notify("No DAP configurations for " .. filetype, vim.log.levels.WARN)
                end
            end, { desc = "Start DAP with configuration selection" })

            vim.api.nvim_create_user_command("DapUIToggle", function()
                require("dapui").toggle()
            end, { desc = "Toggle DAP UI" })
            vim.api.nvim_create_user_command("DapUIOpen", function()
                require("dapui").open()
            end, { desc = "Open DAP UI" })
            vim.api.nvim_create_user_command("DapUIClose", function()
                require("dapui").close()
            end, { desc = "Close DAP UI" })

            -- Autocompletion for dap-repl
            vim.api.nvim_create_autocmd("FileType", {
                pattern = "dap-repl",
                callback = function()
                    require("dap.ext.autocompl").attach()
                end,
            })

            -- Session notifications
            dap.listeners.after.event_initialized["notify"] = function()
                vim.notify("Debugger session started", vim.log.levels.INFO)
            end
            dap.listeners.before.event_terminated["notify"] = function()
                vim.notify("Debugger session ended", vim.log.levels.INFO)
            end
            dap.listeners.before.event_exited["notify"] = function()
                vim.notify("Debugger session exited", vim.log.levels.INFO)
            end
        end,
    },
}
