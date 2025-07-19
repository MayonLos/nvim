return {
    "CopilotC-Nvim/CopilotChat.nvim",
    dependencies = {
        { "zbirenbaum/copilot.lua" },
        { "nvim-lua/plenary.nvim", branch = "master" },
    },
    build = "make tiktoken",
    cmd = {
        "CopilotChat",
        "CopilotChatOpen",
        "CopilotChatToggle",
        "CopilotChatReset",
        "CopilotChatPrompts",
        "CopilotChatModels",
        "CopilotChatAgents",
        "CopilotChatExplain",
        "CopilotChatReview",
        "CopilotChatFix",
        "CopilotChatOptimize",
        "CopilotChatDocs",
        "CopilotChatTests",
        "CopilotChatCommit",
    },
    keys = {
        -- Core chat interactions
        {
            "<leader>ac",
            "<cmd>CopilotChatToggle<cr>",
            desc = "Toggle Copilot Chat",
            mode = { "n", "v" },
        },
        { "<leader>ar", "<cmd>CopilotChatReset<cr>", desc = "Reset Copilot Chat", mode = "n" },
        { "<leader>aq", "<cmd>CopilotChatClose<cr>", desc = "Close Copilot Chat", mode = "n" },

        -- Quick actions - fixed key mappings to avoid conflicts
        {
            "<leader>ae",
            "<cmd>CopilotChatExplain<cr>",
            desc = "Explain Code",
            mode = { "n", "v" },
        },
        {
            "<leader>aR", -- Changed from ar to aR to avoid conflict with reset
            "<cmd>CopilotChatReview<cr>",
            desc = "Review Code",
            mode = { "n", "v" },
        },
        {
            "<leader>af",
            "<cmd>CopilotChatFix<cr>",
            desc = "Fix Code",
            mode = { "n", "v" },
        },
        {
            "<leader>ao",
            "<cmd>CopilotChatOptimize<cr>",
            desc = "Optimize Code",
            mode = { "n", "v" },
        },
        {
            "<leader>ad",
            "<cmd>CopilotChatDocs<cr>",
            desc = "Generate Docs",
            mode = { "n", "v" },
        },
        {
            "<leader>at",
            "<cmd>CopilotChatTests<cr>",
            desc = "Generate Tests",
            mode = { "n", "v" },
        },

        -- Utilities
        { "<leader>ap", "<cmd>CopilotChatPrompts<cr>", desc = "Select Prompt",           mode = "n" },
        { "<leader>am", "<cmd>CopilotChatModels<cr>",  desc = "Select Model",            mode = "n" },
        { "<leader>aa", "<cmd>CopilotChatAgents<cr>",  desc = "Select Agent",            mode = "n" },

        -- Git integration
        { "<leader>ag", "<cmd>CopilotChatCommit<cr>",  desc = "Generate Commit Message", mode = "n" },

        -- Custom prompts
        {
            "<leader>ai",
            function()
                local input = vim.fn.input("Ask Copilot: ")
                if input and input ~= "" then
                    require("CopilotChat").ask(input)
                end
            end,
            desc = "Ask Copilot (Input)",
            mode = { "n", "v" },
        },

        -- Quick fix for diagnostics
        {
            "<leader>aD",
            function()
                local diagnostics = vim.diagnostic.get(0)
                if #diagnostics > 0 then
                    local lines = {}
                    for _, diag in ipairs(diagnostics) do
                        table.insert(lines, string.format("Line %d: %s", diag.lnum + 1, diag.message))
                    end
                    local context = table.concat(lines, "\n")
                    require("CopilotChat").ask("Please help fix these diagnostic issues:\n" .. context)
                else
                    vim.notify("No diagnostics found", vim.log.levels.INFO)
                end
            end,
            desc = "Fix Diagnostic Issues",
            mode = "n",
        },
    },
    config = function()
        local copilot_chat = require("CopilotChat")

        -- Helper function to get visual selection
        local function get_visual_selection()
            local mode = vim.fn.mode()
            if mode == "v" or mode == "V" or mode == "\22" then
                local start_pos = vim.fn.getpos("'<")
                local end_pos = vim.fn.getpos("'>")
                local start_line, start_col = start_pos[2], start_pos[3]
                local end_line, end_col = end_pos[2], end_pos[3]

                return vim.api.nvim_buf_get_text(
                    0,
                    start_line - 1,
                    start_col - 1,
                    end_line - 1,
                    end_col,
                    {}
                )
            end
            return nil
        end

        copilot_chat.setup({
            -- Model configuration
            model = "gpt-4o",
            temperature = 0.1,

            -- UI configuration
            window = {
                layout = "vertical",
                width = 0.5,
                height = 0.5,
                relative = "editor",
                border = "rounded",
                title = "Copilot Chat",
                footer = nil,
                zindex = 1,
            },

            -- Chat configuration
            chat = {
                welcome_message = "Welcome to Copilot Chat! How can I help you today?",
                loading_text = "Thinking...",
                question_prefix = "## User ",
                answer_prefix = "## Copilot ",
                error_prefix = "## Error ",
                separator = "\n\n",
            },

            -- Fixed selection configuration
            selection = function(source)
                local select = require("CopilotChat.select")
                return select.visual(source) or select.line(source)
            end,

            -- Context configuration
            context = "buffers", -- Simplified context configuration

            -- Mappings for chat buffer
            mappings = {
                complete = {
                    insert = "<Tab>",
                },
                close = {
                    normal = "q",
                    insert = "<C-c>",
                },
                reset = {
                    normal = "<C-r>",
                    insert = "<C-r>",
                },
                submit_prompt = {
                    normal = "<CR>",
                    insert = "<C-s>",
                },
                yank_diff = {
                    normal = "gy",
                    register = '"',
                },
                show_diff = {
                    normal = "gd",
                },
                show_info = {
                    normal = "gi",
                },
                show_context = {
                    normal = "gc",
                },
            },

            -- Simplified and fixed prompts configuration
            prompts = {
                Explain = {
                    prompt = "Please explain how this code works:",
                    selection = function(source)
                        local select = require("CopilotChat.select")
                        return select.visual(source) or select.line(source)
                    end,
                },
                Review = {
                    prompt = "Please review this code and provide suggestions for improvement:",
                    selection = function(source)
                        local select = require("CopilotChat.select")
                        return select.visual(source) or select.line(source)
                    end,
                },
                Tests = {
                    prompt = "Please write comprehensive tests for this code:",
                    selection = function(source)
                        local select = require("CopilotChat.select")
                        return select.visual(source) or select.line(source)
                    end,
                },
                Refactor = {
                    prompt = "Please refactor this code to improve its clarity and readability:",
                    selection = function(source)
                        local select = require("CopilotChat.select")
                        return select.visual(source) or select.line(source)
                    end,
                },
                FixBug = {
                    prompt = "There is a bug in this code. Please identify and fix it:",
                    selection = function(source)
                        local select = require("CopilotChat.select")
                        return select.visual(source) or select.line(source)
                    end,
                },
                Documentation = {
                    prompt = "Please provide documentation for this code:",
                    selection = function(source)
                        local select = require("CopilotChat.select")
                        return select.visual(source) or select.line(source)
                    end,
                },
                SwaggerApiDocs = {
                    prompt = "Please provide swagger API documentation for this code:",
                    selection = function(source)
                        local select = require("CopilotChat.select")
                        return select.visual(source) or select.line(source)
                    end,
                },
                Optimize = {
                    prompt = "Please optimize this code for performance:",
                    selection = function(source)
                        local select = require("CopilotChat.select")
                        return select.visual(source) or select.line(source)
                    end,
                },
                Summarize = {
                    prompt = "Please summarize this code:",
                    selection = function(source)
                        local select = require("CopilotChat.select")
                        return select.visual(source) or select.line(source)
                    end,
                },
                BetterNamings = {
                    prompt = "Please suggest better variable and function names for this code:",
                    selection = function(source)
                        local select = require("CopilotChat.select")
                        return select.visual(source) or select.line(source)
                    end,
                },
            },

            -- Auto-completion
            auto_insert_mode = true,
            auto_follow_cursor = true,

            -- History
            history_path = vim.fn.stdpath("data") .. "/copilot_chat_history",

            -- Logging
            log_level = "info",
        })

        -- Auto-commands for better integration
        local copilot_chat_group = vim.api.nvim_create_augroup("CopilotChatConfig", { clear = true })

        vim.api.nvim_create_autocmd("BufEnter", {
            group = copilot_chat_group,
            pattern = "*",
            callback = function()
                local ft = vim.bo.filetype
                if ft == "copilot-chat" then
                    vim.wo.wrap = true
                    vim.wo.linebreak = true
                    vim.wo.breakindent = true
                    vim.wo.number = false
                    vim.wo.relativenumber = false
                end
            end,
        })

        -- Enhanced command for quick questions with proper selection handling
        vim.api.nvim_create_user_command("CopilotChatQuick", function(opts)
            local prompt = opts.args
            local selection = get_visual_selection()

            if selection and #selection > 0 then
                local context = table.concat(selection, "\n")
                prompt = prompt .. "\n\nContext:\n```\n" .. context .. "\n```"
            end

            copilot_chat.ask(prompt)
        end, {
            nargs = 1,
            range = true,
            desc = "Quick Copilot Chat with context",
        })

        -- Command to open chat with current diagnostics
        vim.api.nvim_create_user_command("CopilotChatDiagnostics", function()
            local diagnostics = vim.diagnostic.get(0)
            if #diagnostics == 0 then
                vim.notify("No diagnostics found", vim.log.levels.INFO)
                return
            end

            local lines = {}
            for _, diag in ipairs(diagnostics) do
                table.insert(lines, string.format("Line %d: %s", diag.lnum + 1, diag.message))
            end
            local context = table.concat(lines, "\n")
            copilot_chat.ask("Please help fix these diagnostic issues:\n" .. context)
        end, {
            desc = "Ask Copilot to fix diagnostic issues",
        })
    end,
}
