return {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
        "mason.nvim",
        "saghen/blink.cmp",
        "nvim-tree/nvim-web-devicons",
    },
    opts = {
        servers = {
            -- C/C++ Language Server
            clangd = {
                capabilities = { inlayHint = { enable = true } },
                settings = {
                    clangd = {
                        InlayHints = {
                            Enabled = true,
                            ParameterNames = true,
                            DeducedTypes = true,
                        },
                        completion = {
                            CompletionStyle = "detailed",
                        },
                    },
                },
                cmd = {
                    "clangd",
                    "--background-index",
                    "--clang-tidy",
                    "--header-insertion=iwyu",
                    "--completion-style=detailed",
                    "--function-arg-placeholders",
                    "--fallback-style=llvm",
                },
            },

            -- Python Language Server
            pyright = {
                settings = {
                    python = {
                        analysis = {
                            typeCheckingMode = "basic", -- or "strict" if you prefer
                            autoSearchPaths = true,
                            useLibraryCodeForTypes = true,
                            autoImportCompletions = true,
                        },
                    },
                },
            },

            -- Markdown Language Server
            marksman = {
                settings = {
                    marksman = {
                        completion = {
                            wiki = {
                                style = "title", -- or "path"
                            },
                        },
                    },
                },
            },

            -- Lua Language Server (optimized for Neovim)
            lua_ls = {
                settings = {
                    Lua = {
                        runtime = {
                            version = "LuaJIT",
                            path = vim.split(package.path, ";"),
                        },
                        diagnostics = {
                            globals = { "vim" },
                            disable = { "missing-fields" }, -- Reduce noise
                        },
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("", true),
                            checkThirdParty = false,
                            maxPreload = 100000,
                            preloadFileSize = 10000,
                        },
                        telemetry = { enable = false },
                        hint = {
                            enable = true,
                            arrayIndex = "Disable", -- Reduce visual noise
                        },
                        format = {
                            enable = false, -- Use stylua via conform instead
                        },
                    },
                },
            },
        },

        -- Global LSP settings
        inlay_hints = { enabled = true },
        diagnostics = {
            virtual_text = {
                spacing = 4,
                source = "if_many",
                prefix = "●",
            },
            signs = true,
            underline = true,
            update_in_insert = false,
            severity_sort = true,
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
                max_width = 80,
                max_height = 20,
            },
        },
    },

    config = function(_, opts)
        -- Initialize Mason
        require("mason").setup()

        -- Apply diagnostic icons
        local has_icons, icons = pcall(require, "utils.icons")
        if has_icons then
            icons.apply_diagnostic_signs()
        end

        -- Configure diagnostics
        vim.diagnostic.config(opts.diagnostics)

        -- Shared LSP capabilities
        local capabilities = vim.tbl_deep_extend(
            "force",
            vim.lsp.protocol.make_client_capabilities(),
            require("blink.cmp").get_lsp_capabilities(),
            { inlayHint = { enable = opts.inlay_hints.enabled } }
        )

        -- Enhanced LSP attach handler
        local on_attach = function(client, bufnr)
            -- Enable inlay hints (if supported)
            if client.server_capabilities.inlayHintProvider and opts.inlay_hints.enabled then
                vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            end

            -- Key mapping helper function
            local function bind(mode, lhs, rhs, desc)
                vim.keymap.set(mode, lhs, rhs, {
                    buffer = bufnr,
                    desc = desc,
                    silent = true,
                    noremap = true,
                })
            end

            -- Core LSP key mappings
            bind("n", "K", vim.lsp.buf.hover, "Hover documentation")
            bind("n", "<leader>k", vim.lsp.buf.signature_help, "Signature help")
            bind("n", "<leader>lrn", vim.lsp.buf.rename, "Rename symbol")
            bind({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "Code actions")

            -- Use conform for formatting instead of LSP
            bind("n", "<leader>lf", function()
                local conform_ok, conform = pcall(require, "conform")
                if conform_ok then
                    conform.format({ timeout_ms = 3000, lsp_format = "fallback" })
                else
                    vim.lsp.buf.format({ async = true })
                end
            end, "Format document")

            -- Diagnostic key mappings
            bind("n", "<leader>le", vim.diagnostic.open_float, "Show diagnostic")
            bind("n", "<leader>lq", vim.diagnostic.setloclist, "Diagnostic list")
            bind("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
            bind("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")

            -- Toggle inlay hints
            bind("n", "<leader>lh", function()
                vim.lsp.inlay_hint.enable(
                    not vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr }),
                    { bufnr = bufnr }
                )
            end, "Toggle inlay hints")

            -- Document highlighting (modern approach)
            if client.server_capabilities.documentHighlightProvider then
                local group =
                    vim.api.nvim_create_augroup("lsp_document_highlight_" .. bufnr, { clear = true })
                vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
                    group = group,
                    buffer = bufnr,
                    callback = vim.lsp.buf.document_highlight,
                })
                vim.api.nvim_create_autocmd("CursorMoved", {
                    group = group,
                    buffer = bufnr,
                    callback = vim.lsp.buf.clear_references,
                })
            end

            -- Disable LSP formatting in favor of conform.nvim
            if client.name ~= "clangd" then -- Keep clangd formatting as fallback
                client.server_capabilities.documentFormattingProvider = false
                client.server_capabilities.documentRangeFormattingProvider = false
            end
        end

        -- Set up LSP servers
        for server, config in pairs(opts.servers) do
            local server_config = vim.tbl_deep_extend("force", {
                on_attach = on_attach,
                capabilities = capabilities,
            }, config)

            require("lspconfig")[server].setup(server_config)
        end

        -- Enhanced LSP handlers with better UI
        vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
            border = "rounded",
            max_width = 80,
            max_height = 20,
        })

        vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
            border = "rounded",
            max_width = 80,
            max_height = 20,
        })

        -- LSP server management commands
        vim.api.nvim_create_user_command("LspRestart", function()
            vim.cmd("LspStop")
            vim.defer_fn(function()
                vim.cmd("LspStart")
            end, 500)
        end, { desc = "Restart LSP servers" })

        vim.api.nvim_create_user_command("LspLog", function()
            vim.cmd("edit " .. vim.lsp.get_log_path())
        end, { desc = "Open LSP log file" })

        -- Global LSP settings
        vim.lsp.set_log_level("WARN")
        vim.opt.updatetime = 250
        vim.opt.signcolumn = "yes"
    end,
}
