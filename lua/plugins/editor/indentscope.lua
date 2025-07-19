return {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    event = { "BufReadPost", "BufNewFile", "BufWritePre" },
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
    },
    opts = function()
        local colors = {
            level1 = "#4B5563",
            level2 = "#6B7280",
            level3 = "#9CA3AF",
            level4 = "#D1D5DB",
            scope = "#45475A",
            error = "#EF4444",
            warning = "#F59E0B",
        }

        local indent_highlights = {
            "IBLIndent1",
            "IBLIndent2",
            "IBLIndent3",
            "IBLIndent4",
        }

        local scope_highlights = {
            "IBLScope",
            "IBLScopeError",
            "IBLScopeWarning",
        }

        local function setup_highlights()
            vim.api.nvim_set_hl(0, "IBLIndent1", { fg = colors.level1 })
            vim.api.nvim_set_hl(0, "IBLIndent2", { fg = colors.level2 })
            vim.api.nvim_set_hl(0, "IBLIndent3", { fg = colors.level3 })
            vim.api.nvim_set_hl(0, "IBLIndent4", { fg = colors.level4 })

            -- Scope highlights
            vim.api.nvim_set_hl(0, "IBLScope", { fg = colors.scope, bold = true })
            vim.api.nvim_set_hl(0, "IBLScopeError", { fg = colors.error, bold = true })
            vim.api.nvim_set_hl(0, "IBLScopeWarning", { fg = colors.warning, bold = true })
        end

        setup_highlights()

        -- Comprehensive exclude list for modern development workflow
        local exclude_filetypes = {
            -- Documentation and help
            "help",
            "man",
            "markdown",
            "text",
            "txt",

            -- Plugin managers and tools
            "lazy",
            "packer",
            "mason",
            "lspinfo",
            "null-ls-info",

            -- Start screens and dashboards
            "dashboard",
            "starter",
            "alpha",
            "startify",

            -- File explorers
            "neo-tree",
            "NvimTree",
            "oil",
            "dirvish",
            "netrw",

            -- Terminal and REPL
            "toggleterm",
            "lazyterm",
            "terminal",
            "fterm",

            -- Search and selection
            "TelescopePrompt",
            "TelescopeResults",
            "TelescopePreview",
            "fzf",
            "ctrlp",

            -- Debugging and diagnostics
            "Trouble",
            "trouble",
            "qf",
            "loclist",

            -- Git integration
            "gitcommit",
            "gitrebase",
            "fugitive",
            "gitconfig",
            "DiffviewFiles",
            "DiffviewFileHistory",

            -- Language servers and diagnostics
            "lsp-installer",
            "lspinfo",
            "mason",
            "null-ls-info",

            -- Note taking and organization
            "org",
            "orgagenda",
            "vimwiki",

            -- System and utility
            "checkhealth",
            "notify",
            "noice",
            "aerial",
            "undotree",
            "vista",
            "tagbar",
            "outline",
            "symbols-outline",
        }

        local exclude_buftypes = {
            "terminal",
            "nofile",
            "quickfix",
            "prompt",
            "popup",
            "acwrite",
        }

        return {
            indent = {
                char = "▏", -- Modern thin line (similar to VS Code)
                tab_char = "▏",
                smart_indent_cap = true,
                priority = 1,
                repeat_linebreak = true,
            },
            whitespace = {
                highlight = indent_highlights,
                remove_blankline_trail = true, -- Clean appearance
            },
            scope = {
                enabled = true,
                char = "▎", -- Slightly thicker for active scope
                show_start = false, -- Remove horizontal start line
                show_end = false,
                show_exact_scope = true, -- More precise scope detection
                injected_languages = true, -- Support embedded languages
                highlight = scope_highlights,
                priority = 1024,
                include = {
                    node_type = {
                        ["*"] = {
                            -- Core structural elements
                            "class",
                            "struct",
                            "interface",
                            "enum",
                            "union",
                            "function",
                            "method",
                            "constructor",
                            "destructor",
                            "closure",
                            "arrow_function",
                            "lambda",

                            -- Control flow
                            "^if",
                            "^while",
                            "^for",
                            "^do",
                            "^switch",
                            "else_clause",
                            "elif_clause",
                            "elseif_clause",
                            "case",
                            "default",
                            "when",

                            -- Exception handling
                            "try",
                            "catch",
                            "finally",
                            "except",
                            "rescue",
                            "ensure",
                            "defer",

                            -- Data structures
                            "object",
                            "table",
                            "array",
                            "list",
                            "dict",
                            "map",
                            "set",
                            "tuple",
                            "record",
                            "block",
                            "body",
                            "compound_statement",

                            -- Functions and calls
                            "arguments",
                            "parameters",
                            "argument_list",
                            "parameter_list",
                            "call_expression",

                            -- Statements
                            "if_statement",
                            "while_statement",
                            "for_statement",
                            "return_statement",
                            "expression_statement",
                            "assignment",
                            "declaration",

                            -- Modules and imports
                            "import",
                            "export",
                            "module",
                            "namespace",
                            "package",
                            "use",
                            "include",
                            "require",
                        },

                        -- Language-specific optimizations
                        lua = {
                            "chunk",
                            "do_statement",
                            "repeat_statement",
                            "local_function",
                            "function_call",
                            "table_constructor",
                        },
                        python = {
                            "with_statement",
                            "match_statement",
                            "async_with_statement",
                            "list_comprehension",
                            "dictionary_comprehension",
                            "set_comprehension",
                            "generator_expression",
                        },
                        javascript = {
                            "object_pattern",
                            "array_pattern",
                            "template_literal",
                            "jsx_element",
                            "jsx_fragment",
                            "async_function",
                        },
                        typescript = {
                            "interface_declaration",
                            "type_alias_declaration",
                            "namespace_declaration",
                            "generic_type",
                        },
                        rust = {
                            "impl_item",
                            "trait_item",
                            "macro_invocation",
                            "match_expression",
                            "closure_expression",
                        },
                        go = {
                            "type_declaration",
                            "method_declaration",
                            "select_statement",
                            "type_switch_statement",
                        },
                        cpp = {
                            "class_specifier",
                            "namespace_definition",
                            "template_declaration",
                            "lambda_expression",
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
        local ok, ibl = pcall(require, "ibl")
        if not ok then
            vim.notify("Failed to load indent-blankline.nvim", vim.log.levels.ERROR)
            return
        end

        ibl.setup(opts)

        local hooks = require("ibl.hooks")

        -- Re-apply highlights on colorscheme changes
        hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
            local colors = {
                level1 = "#4B5563",
                level2 = "#6B7280",
                level3 = "#9CA3AF",
                level4 = "#D1D5DB",
                scope = "#3B82F6",
                error = "#EF4444",
                warning = "#F59E0B",
            }

            vim.api.nvim_set_hl(0, "IBLIndent1", { fg = colors.level1 })
            vim.api.nvim_set_hl(0, "IBLIndent2", { fg = colors.level2 })
            vim.api.nvim_set_hl(0, "IBLIndent3", { fg = colors.level3 })
            vim.api.nvim_set_hl(0, "IBLIndent4", { fg = colors.level4 })
            vim.api.nvim_set_hl(0, "IBLScope", { fg = colors.scope, bold = true })
            vim.api.nvim_set_hl(0, "IBLScopeError", { fg = colors.error, bold = true })
            vim.api.nvim_set_hl(0, "IBLScopeWarning", { fg = colors.warning, bold = true })
        end)

        -- Enhanced scope highlighting without horizontal lines
        hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)

        -- Smart performance optimization based on file characteristics
        hooks.register(hooks.type.WHITESPACE, function(_, bufnr, _, whitespace_tbl)
            local line_count = vim.api.nvim_buf_line_count(bufnr)
            local file_size = vim.api.nvim_buf_get_offset(bufnr, line_count)

            -- Aggressive optimization for very large files
            if line_count > 15000 or file_size > 1048576 then -- > 1MB
                return {}
            elseif line_count > 8000 or file_size > 524288 then -- > 512KB
                -- Sample every 3rd line for large files
                local reduced_tbl = {}
                for i = 1, #whitespace_tbl, 3 do
                    reduced_tbl[#reduced_tbl + 1] = whitespace_tbl[i]
                end
                return reduced_tbl
            elseif line_count > 3000 then
                -- Sample every 2nd line for medium files
                local reduced_tbl = {}
                for i = 1, #whitespace_tbl, 2 do
                    reduced_tbl[#reduced_tbl + 1] = whitespace_tbl[i]
                end
                return reduced_tbl
            end

            return whitespace_tbl
        end)

        -- Modern IDE-style commands and keymaps
        vim.api.nvim_create_user_command("IndentLinesToggle", function()
            local enabled = require("ibl.config").get_config(0).enabled
            require("ibl").setup_buffer(0, { enabled = not enabled })
            vim.notify(
                string.format("Indent lines %s", enabled and "disabled" or "enabled"),
                vim.log.levels.INFO
            )
        end, { desc = "Toggle indent lines for current buffer" })

        vim.api.nvim_create_user_command("IndentScopeToggle", function()
            local config = require("ibl.config").get_config(0)
            local scope_enabled = config.scope and config.scope.enabled
            require("ibl").setup_buffer(0, {
                scope = { enabled = not scope_enabled },
            })
            vim.notify(
                string.format("Scope highlighting %s", scope_enabled and "disabled" or "enabled"),
                vim.log.levels.INFO
            )
        end, { desc = "Toggle scope highlighting for current buffer" })

        -- Context-aware auto-configuration
        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "json", "jsonc", "yaml", "yml" },
            callback = function()
                -- Disable scope for data files (no logical scope)
                require("ibl").setup_buffer(0, {
                    scope = { enabled = false },
                })
            end,
            desc = "Disable scope highlighting for data files",
        })

        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "python" },
            callback = function()
                -- Python-specific optimization: highlight significant indentation
                require("ibl").setup_buffer(0, {
                    indent = { char = "▏", smart_indent_cap = true },
                    scope = { show_exact_scope = true },
                })
            end,
            desc = "Python-specific indent line configuration",
        })

        -- Memory cleanup for inactive buffers
        vim.api.nvim_create_autocmd("BufWinLeave", {
            callback = function(args)
                -- Clean up resources when buffer is no longer visible
                local bufnr = args.buf
                if vim.api.nvim_buf_is_valid(bufnr) then
                    require("ibl").debounced_refresh(bufnr)
                end
            end,
            desc = "Cleanup indent-blankline resources for hidden buffers",
        })
    end,
}
