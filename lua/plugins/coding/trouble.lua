return {
    {
        "folke/trouble.nvim",
        cmd = "Trouble",
        opts = {
            focus = true,
            auto_preview = false,
            restore = true,
            follow = true,
            indent_guides = true,
            max_items = 200,
            multiline = true,
            pinned = false,
            warn_no_results = false,
            open_no_results = false,
            win = { position = "bottom" },
            preview = {
                type = "main",
                scratch = true,
            },
        },
        keys = {
            {
                "<leader>xx",
                "<cmd>Trouble diagnostics toggle<cr>",
                desc = "Toggle diagnostics (Trouble)",
            },
            {
                "<leader>xX",
                "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
                desc = "Toggle buffer diagnostics (Trouble)",
            },
            {
                "<leader>xs",
                "<cmd>Trouble symbols toggle<cr>",
                desc = "Toggle symbols (Trouble)",
            },
            {
                "<leader>xl",
                "<cmd>Trouble lsp toggle win.position=right<cr>",
                desc = "Toggle LSP references (Trouble)",
            },
            {
                "<leader>xL",
                "<cmd>Trouble loclist toggle<cr>",
                desc = "Toggle location list (Trouble)",
            },
            {
                "<leader>xQ",
                "<cmd>Trouble qflist toggle<cr>",
                desc = "Toggle quickfix list (Trouble)",
            },
            {
                "<leader>xn",
                function()
                    require("trouble").next({ skip_groups = true, jump = true })
                end,
                desc = "Next trouble item",
            },
            {
                "<leader>xp",
                function()
                    require("trouble").prev({ skip_groups = true, jump = true })
                end,
                desc = "Previous trouble item",
            },
        },
    },
}
