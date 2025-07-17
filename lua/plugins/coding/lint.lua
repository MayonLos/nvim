return {
    {
        "mfussenegger/nvim-lint",
        event = { "BufReadPre", "BufNewFile" },
        config = function()
            local lint = require("lint")
            local lint_utils = require("utils.lint")

            -- Setup linters
            lint_utils.setup_linters()

            -- Create lint function with debouncing
            local lint_debounce_timer = nil
            local function debounced_lint()
                if lint_debounce_timer then
                    vim.fn.timer_stop(lint_debounce_timer)
                end
                lint_debounce_timer = vim.fn.timer_start(100, function()
                    lint_utils.trigger()
                    lint_debounce_timer = nil
                end)
            end

            -- Create autocommand group
            local group = vim.api.nvim_create_augroup("LintAutogroup", { clear = true })

            -- Lint on file events
            vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave" }, {
                group = group,
                callback = lint_utils.trigger,
                desc = "Lint on file save and insert leave",
            })

            -- Lint on text changes (debounced)
            vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
                group = group,
                callback = debounced_lint,
                desc = "Lint on text changes (debounced)",
            })

            -- Manual lint keymap
            vim.keymap.set("n", "<leader>ll", lint_utils.trigger, {
                desc = "Lint current buffer",
                silent = true,
            })
        end,
    },
}
