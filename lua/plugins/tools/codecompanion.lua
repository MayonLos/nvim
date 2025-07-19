return {
    "olimorris/codecompanion.nvim",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "nvim-treesitter/nvim-treesitter",
        {
            "echasnovski/mini.diff",
            config = function()
                require("mini.diff").setup({
                    source = require("mini.diff").gen_source.none(),
                })
            end,
        },
    },
    opts = {
        strategies = {
            chat = {
                keymaps = {
                    send = {
                        modes = {
                            n = "<CR>",
                            i = "<C-s>",
                        },
                        opts = { desc = "Send message" },
                    },
                    close = {
                        modes = {
                            n = "q",
                            i = "<C-c>",
                        },
                        opts = { desc = "Close chat" },
                    },
                },
            },
        },
        log_level = "DEBUG",
        display = {
            action_palette = {
                width = 95,
                height = 10,
                prompt = "Prompt ",
                provider = "telescope",
                opts = {
                    show_default_actions = true,
                    show_default_prompt_library = true,
                },
            },
            diff = {
                enabled = true,
                close_chat_at = 240,
                layout = "vertical",
                provider = "mini_diff",
                opts = {
                    "internal",
                    "filler",
                    "closeoff",
                    "algorithm:patience",
                    "followwrap",
                    "linematch:120",
                },
            },
        },
    },
}
