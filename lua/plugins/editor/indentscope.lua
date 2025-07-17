return {
    {
        "lukas-reineke/indent-blankline.nvim",
        main = "ibl",
        event = { "BufReadPost", "BufNewFile", "BufWritePre" },
        dependencies = {
            "nvim-treesitter/nvim-treesitter",
        },
        opts = function()
            -- Rainbow colors configuration
            local colors = {
                red = "#E06C75",
                yellow = "#E5C07B",
                blue = "#61AFEF",
                orange = "#D19A66",
                green = "#98C379",
                violet = "#C678DD",
                cyan = "#56B6C2",
            }

            -- Generate highlight group names
            local rainbow_highlights = {}
            for color_name, _ in pairs(colors) do
                table.insert(rainbow_highlights, "Rainbow" .. color_name:gsub("^%l", string.upper))
            end

            -- Setup rainbow highlights
            local function setup_rainbow_highlights()
                for name, hex in pairs(colors) do
                    local hl_name = "Rainbow" .. name:gsub("^%l", string.upper)
                    vim.api.nvim_set_hl(0, hl_name, {
                        fg = hex,
                        bold = false,
                        italic = false,
                    })
                end
            end

            -- Call setup immediately
            setup_rainbow_highlights()

            -- Extended exclude list for better performance
            local exclude_filetypes = {
                "help",
                "lazy",
                "dashboard",
                "starter",
                "neo-tree",
                "Trouble",
                "mason",
                "notify",
                "toggleterm",
                "lazyterm",
                "TelescopePrompt",
                "TelescopeResults",
                "alpha",
                "NvimTree",
                "packer",
                "lspinfo",
                "checkhealth",
                "man",
                "gitcommit",
                "gitrebase",
                "svn",
                "hgcommit",
            }

            local exclude_buftypes = {
                "terminal",
                "nofile",
                "quickfix",
                "prompt",
                "popup",
            }

            return {
                indent = {
                    char = "│",
                    tab_char = "│",
                    smart_indent_cap = true,
                    priority = 1,
                },
                whitespace = {
                    highlight = rainbow_highlights,
                    remove_blankline_trail = false,
                },
                scope = {
                    enabled = true,
                    char = "▎",
                    show_start = true,
                    show_end = false,
                    show_exact_scope = false,
                    injected_languages = false,
                    highlight = rainbow_highlights,
                    priority = 1024,
                    include = {
                        node_type = {
                            ["*"] = {
                                "class",
                                "return",
                                "function",
                                "method",
                                "^if",
                                "^while",
                                "^for",
                                "^object",
                                "^table",
                                "block",
                                "arguments",
                                "if_statement",
                                "else_clause",
                                "try",
                                "catch",
                                "import",
                                "operation_type",
                            },
                        },
                    },
                },
                exclude = {
                    filetypes = exclude_filetypes,
                    buftypes = exclude_buftypes,
                },
            }
        end,
        config = function(_, opts)
            -- Setup the plugin with configuration
            require("ibl").setup(opts)

            -- Register hooks after setup
            local hooks = require("ibl.hooks")

            -- Hook for highlight setup - reapply on colorscheme changes
            hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
                local colors = {
                    red = "#E06C75",
                    yellow = "#E5C07B",
                    blue = "#61AFEF",
                    orange = "#D19A66",
                    green = "#98C379",
                    violet = "#C678DD",
                    cyan = "#56B6C2",
                }

                for name, hex in pairs(colors) do
                    local hl_name = "Rainbow" .. name:gsub("^%l", string.upper)
                    vim.api.nvim_set_hl(0, hl_name, {
                        fg = hex,
                        bold = false,
                        italic = false,
                    })
                end
            end)

            -- Hook for scope highlighting from extmarks
            hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)

            -- Performance optimization: Clear inactive buffers
            hooks.register(hooks.type.WHITESPACE, function(_, bufnr, _, whitespace_tbl)
                -- Limit whitespace processing for very large files
                if vim.api.nvim_buf_line_count(bufnr) > 5000 then
                    return {}
                end
                return whitespace_tbl
            end)
        end,
    },
}
