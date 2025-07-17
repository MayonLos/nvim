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
            bashls = {},
            clangd = {
                capabilities = { inlayHint = { enable = true } },
                settings = {
                    clangd = {
                        InlayHints = {
                            Enabled = true,
                            ParameterNames = true,
                            DeducedTypes = true,
                        },
                    },
                },
            },
            pyright = {},
            marksman = {},
            lua_ls = {
                settings = {
                    Lua = {
                        runtime = { version = "LuaJIT" },
                        diagnostics = { globals = { "vim" } },
                        workspace = {
                            library = vim.api.nvim_get_runtime_file("", true),
                            checkThirdParty = false,
                        },
                        telemetry = { enable = false },
                    },
                },
            },
        },
        -- Global LSP settings
        inlay_hints = { enabled = true },
        diagnostics = {
            virtual_text = true,
            signs = true,
            underline = true,
            update_in_insert = false,
            float = {
                focusable = false,
                style = "minimal",
                border = "rounded",
                source = "always",
                header = "",
                prefix = "",
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

            -- Core LSP key mappings (non-telescope)
            bind("n", "K", vim.lsp.buf.hover, "Hover documentation")
            bind("n", "<leader>k", vim.lsp.buf.signature_help, "Signature help")
            bind("n", "<leader>lrn", vim.lsp.buf.rename, "Rename symbol")
            bind({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "Code actions")
            bind("n", "<leader>lf", function()
                vim.lsp.buf.format({ async = true })
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

            -- Document highlighting
            if client.server_capabilities.documentHighlightProvider then
                local group = vim.api.nvim_create_augroup("lsp_document_highlight", { clear = false })
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

            -- Auto-format on save
            -- Use new API to check method support
            if client:supports_method("textDocument/formatting") then
                vim.api.nvim_create_autocmd("BufWritePre", {
                    group = vim.api.nvim_create_augroup("lsp_format_on_save", { clear = false }),
                    buffer = bufnr,
                    callback = function()
                        if vim.g.autoformat_enabled ~= false then
                            vim.lsp.buf.format({ async = false })
                        end
                    end,
                })
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

        -- Modern LSP configuration - using new API
        local lsp_config = {
            handlers = {
                ["textDocument/hover"] = function(err, result, ctx, config)
                    config = config or {}
                    config.border = "rounded"
                    config.max_width = 80
                    config.max_height = 20
                    return vim.lsp.handlers["textDocument/hover"](err, result, ctx, config)
                end,
                ["textDocument/signatureHelp"] = function(err, result, ctx, config)
                    config = config or {}
                    config.border = "rounded"
                    config.max_width = 80
                    config.max_height = 20
                    return vim.lsp.handlers["textDocument/signatureHelp"](err, result, ctx, config)
                end,
            },
        }

        -- Apply configuration to all LSP clients
        for server, _ in pairs(opts.servers) do
            vim.lsp.config(server, lsp_config)
        end

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

        vim.api.nvim_create_user_command("LspInfo", function()
            vim.cmd("LspInfo")
        end, { desc = "Show LSP information" })

        -- Global LSP settings
        vim.lsp.set_log_level("WARN")
        vim.opt.updatetime = 250
        vim.opt.signcolumn = "yes"
    end,
}
