return {
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local lint = require("lint")

            -- Configure linters for file types
            lint.linters_by_ft = {
                cpp = { "cpplint" },
                c = { "cpplint" },
                python = { "pylint" },
                sh = { "shellcheck" },
                lua = { "luacheck" },
                markdown = { "markdownlint" },
                javascript = { "eslint" },
                typescript = { "eslint" },
                json = { "jsonlint" },
                yaml = { "yamllint" },
            }

            -- Debounced lint function
            local lint_timer = nil
            local function lint_debounced()
                if lint_timer then
                    vim.fn.timer_stop(lint_timer)
                end
                lint_timer = vim.fn.timer_start(150, function()
                    lint.try_lint()
                    lint_timer = nil
                end)
            end

            -- Immediate lint function
            local function lint_now()
                lint.try_lint()
            end

            -- Create autocommand group
            local group = vim.api.nvim_create_augroup("LintConfig", { clear = true })

            -- Lint on save and insert leave (immediate)
            vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
                group = group,
                callback = lint_now,
                desc = "Lint on save and insert leave",
            })

            -- Lint on text changes (debounced)
            vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
                group = group,
                callback = lint_debounced,
                desc = "Lint on text changes (debounced)",
            })

            -- Lint when entering buffer
            vim.api.nvim_create_autocmd("BufEnter", {
                group = group,
                callback = lint_now,
                desc = "Lint when entering buffer",
            })

            -- Manual lint keymap
            vim.keymap.set("n", "<leader>ll", lint_now, {
                desc = "Lint current buffer",
                silent = true,
            })

            -- Toggle linting keymap
            vim.keymap.set("n", "<leader>lt", function()
                local enabled = vim.g.lint_enabled ~= false
                vim.g.lint_enabled = not enabled
                if enabled then
                    vim.diagnostic.reset()
                    vim.notify("Linting disabled", vim.log.levels.INFO)
                else
                    lint_now()
                    vim.notify("Linting enabled", vim.log.levels.INFO)
                end
            end, {
                desc = "Toggle linting",
                silent = true,
            })

            -- Override try_lint to respect toggle
            local original_try_lint = lint.try_lint
            lint.try_lint = function(...)
                if vim.g.lint_enabled == false then
                    return
                end
                return original_try_lint(...)
            end
        end,
    },
}
