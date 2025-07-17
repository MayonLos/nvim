return {
    {
        "saghen/blink.cmp",
        event = { "InsertEnter", "CmdlineEnter" },
        dependencies = { "rafamadriz/friendly-snippets" },
        build = "cargo build --release",
        version = "1.*",
        opts_extend = { "sources.default" },
        config = function()
            -- ===============================
            -- 键位映射配置
            -- ===============================
            local keymaps = {
                -- 插入模式键位映射
                insert = {
                    ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
                    ["<C-e>"] = { "hide" },
                    ["<CR>"] = { "accept", "fallback" },
                    ["<Up>"] = { "select_prev", "fallback" },
                    ["<Down>"] = { "select_next", "fallback" },
                    ["<C-b>"] = { "scroll_documentation_up", "fallback" },
                    ["<C-f>"] = { "scroll_documentation_down", "fallback" },
                    ["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
                    ["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
                    ["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
                },

                -- 命令行模式键位映射
                cmdline = {
                    ["<Tab>"] = { "show_and_insert", "select_next" },
                    ["<S-Tab>"] = { "show_and_insert", "select_prev" },
                    ["<CR>"] = { "accept_and_enter", "fallback" },
                },
            }

            -- ===============================
            -- 补全源配置
            -- ===============================
            local sources = {
                -- 默认补全源
                default = { "lsp", "path", "snippets", "buffer" },

                -- 自定义补全源提供者
                providers = {
                    markdown = {
                        name = "RenderMarkdown",
                        module = "render-markdown.integ.blink",
                        fallbacks = { "lsp" },
                    },
                },

                -- 按文件类型配置补全源
                per_filetype = {
                    markdown = {
                        inherit_defaults = true,
                        "markdown",
                    },
                },
            }

            -- ===============================
            -- 禁用补全的文件类型
            -- ===============================
            local disabled_filetypes = {
                "oil",
                "NvimTree",
                "DressingInput",
                "copilot-chat",
            }

            -- ===============================
            -- 补全功能配置
            -- ===============================
            local completion_config = {
                -- 文档配置
                documentation = {
                    auto_show = true,
                },

                -- 关键字匹配配置
                keyword = {
                    range = "full",
                },

                -- 列表选择配置
                list = {
                    selection = {
                        preselect = true,
                        auto_insert = false,
                    },
                },

                -- 幽灵文本配置
                ghost_text = {
                    enabled = true,
                },
            }

            -- ===============================
            -- 命令行补全配置
            -- ===============================
            local cmdline_config = {
                completion = {
                    list = {
                        selection = {
                            preselect = false,
                            auto_insert = true,
                        },
                    },
                },
                keymap = keymaps.cmdline,
            }

            -- ===============================
            -- 外观配置
            -- ===============================
            local appearance_config = {
                nerd_font_variant = "mono",
            }

            -- ===============================
            -- 启用条件判断
            -- ===============================
            local function is_enabled()
                return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype)
            end

            -- ===============================
            -- 主配置
            -- ===============================
            require("blink.cmp").setup({
                -- 键位映射
                keymap = vim.tbl_extend("force", { preset = "none" }, keymaps.insert),

                -- 启用条件
                enabled = is_enabled,

                -- 外观配置
                appearance = appearance_config,

                -- 函数签名
                signature = { enabled = true },

                -- 命令行配置
                cmdline = cmdline_config,

                -- 补全功能配置
                completion = completion_config,

                -- 补全源配置
                sources = sources,

                -- 模糊匹配引擎
                fuzzy = {
                    implementation = "prefer_rust_with_warning",
                },
            })
        end,
    },
}
