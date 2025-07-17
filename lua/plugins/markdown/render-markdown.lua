return {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "llm", "codecompanion" },
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-tree/nvim-web-devicons",
        "saghen/blink.cmp",
    },
    opts = {
        -- Enhanced heading configuration
        heading = {
            position = "inline",
            icons = { "󰉫 ", "󰉬 ", "󰉭 ", "󰉮 ", "󰉯 ", "󰉰 " },
            backgrounds = { "RenderMarkdownH1Bg", "RenderMarkdownH2Bg", "RenderMarkdownH3Bg" },
            foregrounds = {
                "RenderMarkdownH1",
                "RenderMarkdownH2",
                "RenderMarkdownH3",
                "RenderMarkdownH4",
                "RenderMarkdownH5",
                "RenderMarkdownH6",
            },
        },

        -- Code block enhancements
        code = {
            enabled = true,
            sign = false,
            style = "full",
            position = "left",
            language_pad = 0,
            highlight = "RenderMarkdownCode",
            highlight_inline = "RenderMarkdownCodeInline",
        },

        -- Bullet point styling
        bullet = {
            icons = { "●", "○", "◆", "◇" },
            left_pad = 0,
            right_pad = 0,
            highlight = "RenderMarkdownBullet",
        },

        -- Checkbox styling
        checkbox = {
            unchecked = {
                icon = "󰄱 ",
                highlight = "RenderMarkdownUnchecked",
            },
            checked = {
                icon = "󰱒 ",
                highlight = "RenderMarkdownChecked",
            },
        },

        -- Table styling
        table = {
            style = "full",
            cell = "padded",
            border = {
                "┌",
                "┬",
                "┐",
                "├",
                "┼",
                "┤",
                "└",
                "┴",
                "┘",
                "│",
                "─",
            },
            head = "RenderMarkdownTableHead",
            row = "RenderMarkdownTableRow",
            filler = "RenderMarkdownTableFill",
        },

        -- Link styling
        link = {
            enabled = true,
            image = "󰥶 ",
            hyperlink = "󰌷 ",
            highlight = "RenderMarkdownLink",
        },

        -- Quote styling
        quote = {
            icon = "▋",
            highlight = "RenderMarkdownQuote",
        },

        -- Performance optimizations
        debounce = 100,
        max_file_size = 5.0,

        -- Completion integration
        completions = {
            blink = {
                enabled = true,
                -- Additional blink.cmp specific options
                ghost_text = {
                    enabled = true,
                    highlight = "Comment",
                },
            },
        },

        -- Window options
        win_options = {
            conceallevel = {
                default = vim.o.conceallevel,
                rendered = 3,
            },
            concealcursor = {
                default = vim.o.concealcursor,
                rendered = "",
            },
        },
    },

    -- Lazy loading configuration
    config = function(_, opts)
        require("render-markdown").setup(opts)

        -- Set up custom highlights if needed
        vim.api.nvim_create_autocmd("ColorScheme", {
            group = vim.api.nvim_create_augroup("RenderMarkdownColors", { clear = true }),
            callback = function()
                -- Custom highlight groups can be defined here
                vim.api.nvim_set_hl(0, "RenderMarkdownH1", { fg = "#ff6b6b", bold = true })
                vim.api.nvim_set_hl(0, "RenderMarkdownH2", { fg = "#4ecdc4", bold = true })
                vim.api.nvim_set_hl(0, "RenderMarkdownH3", { fg = "#45b7d1", bold = true })
            end,
        })
    end,
}
