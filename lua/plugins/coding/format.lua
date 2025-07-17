return {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "ConformInfo", "Format", "FormatToggle" },
    keys = {
        {
            "<leader>lf",
            "<cmd>Format<cr>",
            desc = "Format buffer",
        },
        {
            "<leader>lF",
            function()
                require("conform").format({
                    formatters = { "injected" },
                    timeout_ms = 3000,
                    lsp_format = "never",
                })
            end,
            mode = { "n", "v" },
            desc = "Format injected languages",
        },
    },
    dependencies = { "mason-org/mason.nvim" },
    config = function()
        local conform = require("conform")

        -- Global autoformat state
        vim.g.autoformat_enabled = true

        conform.setup({
            default_format_opts = {
                timeout_ms = 3000,
                lsp_format = "never",
            },
            formatters_by_ft = {
                lua = { "stylua" },
                python = { "isort", "black" },
                sh = { "shfmt" },
                markdown = { "prettier" },
                json = { "prettier" },
                yaml = { "prettier" },
                html = { "prettier" },
                css = { "prettier" },
                javascript = { "prettier" },
                typescript = { "prettier" },
                javascriptreact = { "prettier" },
                typescriptreact = { "prettier" },
                c = { "clang_format" },
                cpp = { "clang_format" },
                rust = { "rustfmt" },
                go = { "gofmt" },
                ["*"] = { "trim_whitespace" },
            },
            formatters = {
                stylua = {
                    prepend_args = {
                        "--indent-width",
                        "2",
                        "--column-width",
                        "100",
                        "--quote-style",
                        "AutoPreferDouble",
                    },
                },
                shfmt = {
                    prepend_args = { "-i", "2", "-ci" },
                },
                clang_format = {
                    prepend_args = {
                        "--style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, ColumnLimit: 100}",
                        "-assume-filename",
                        "$FILENAME",
                    },
                },
                prettier = {
                    prepend_args = {
                        "--tab-width",
                        "2",
                        "--print-width",
                        "100",
                        "--single-quote",
                    },
                },
                injected = {
                    options = { ignore_errors = true },
                },
            },
            format_on_save = function(bufnr)
                -- Skip formatting for certain filetypes
                local bufname = vim.api.nvim_buf_get_name(bufnr)
                if bufname:match("/node_modules/") or bufname:match("%.min%.") then
                    return
                end

                if vim.g.autoformat_enabled then
                    return {
                        bufnr = bufnr,
                        timeout_ms = 3000,
                        lsp_format = "never",
                    }
                end
            end,
            log_level = vim.log.levels.WARN,
            notify_on_error = true,
            notify_no_formatters = false, -- Reduce noise
        })

        -- Create user commands
        vim.api.nvim_create_user_command("FormatToggle", function()
            vim.g.autoformat_enabled = not vim.g.autoformat_enabled
            local status = vim.g.autoformat_enabled and "enabled" or "disabled"
            vim.notify(
                string.format("Autoformat %s", status),
                vim.log.levels.INFO,
                { title = "conform.nvim" }
            )
        end, { desc = "Toggle autoformat on save" })

        vim.api.nvim_create_user_command("Format", function()
            conform.format({ timeout_ms = 3000, lsp_format = "never" })
        end, { desc = "Format current buffer" })

        -- Add buffer-local format toggle
        vim.api.nvim_create_user_command("FormatBufferToggle", function()
            vim.b.autoformat_enabled = not vim.b.autoformat_enabled
            local status = vim.b.autoformat_enabled and "enabled" or "disabled"
            vim.notify(
                string.format("Buffer autoformat %s", status),
                vim.log.levels.INFO,
                { title = "conform.nvim" }
            )
        end, { desc = "Toggle autoformat for current buffer" })
    end,
}
