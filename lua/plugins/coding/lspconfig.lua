return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"mason.nvim", -- LSP server installer
		"saghen/blink.cmp", -- Completion capabilities for LSP
		"nvim-tree/nvim-web-devicons", -- Icons support
	},
	opts = {
		servers = {
			-- C/C++ LSP configuration
			clangd = {
				capabilities = { inlayHint = { enable = true } },
				settings = {
					clangd = {
						InlayHints = {
							Enabled = true,
							ParameterNames = true,
							DeducedTypes = true,
						},
						completion = { CompletionStyle = "detailed" },
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

			-- Python LSP configuration
			pyright = {
				settings = {
					python = {
						analysis = {
							typeCheckingMode = "basic",
							autoSearchPaths = true,
							useLibraryCodeForTypes = true,
							autoImportCompletions = true,
						},
					},
				},
			},

			-- Markdown LSP configuration
			marksman = {
				settings = {
					marksman = {
						completion = {
							wiki = { style = "title" },
						},
					},
				},
			},

			-- Lua LSP configuration (optimized for Neovim)
			lua_ls = {
				settings = {
					Lua = {
						runtime = {
							version = "LuaJIT",
							path = vim.split(package.path, ";"),
						},
						diagnostics = {
							globals = { "vim" },
							disable = { "missing-fields" },
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
							arrayIndex = "Disable",
						},
						format = {
							enable = false, -- External formatter like conform.nvim
						},
					},
				},
			},
		},

		-- Global LSP features
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
		-- Initialize Mason (LSP installer)
		require("mason").setup()

		-- Apply custom diagnostic signs if available
		local has_icons, icons = pcall(require, "utils.icons")
		if has_icons then
			icons.apply_diagnostic_signs()
		end

		-- Apply diagnostic UI settings
		vim.diagnostic.config(opts.diagnostics)

		-- Merge capabilities with completion plugin
		local capabilities = vim.tbl_deep_extend(
			"force",
			vim.lsp.protocol.make_client_capabilities(),
			require("blink.cmp").get_lsp_capabilities(),
			{ inlayHint = { enable = opts.inlay_hints.enabled } }
		)

		-- on_attach: sets keybindings and behavior after LSP attaches
		local on_attach = function(client, bufnr)
			if client.server_capabilities.inlayHintProvider and opts.inlay_hints.enabled then
				vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			end

			-- Keybindings helper
			local function bind(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, {
					buffer = bufnr,
					desc = desc,
					silent = true,
					noremap = true,
				})
			end

			-- LSP keymaps for navigation, diagnostics, formatting, etc.
			bind("n", "K", vim.lsp.buf.hover, "Hover documentation")
			bind("n", "<leader>k", vim.lsp.buf.signature_help, "Signature help")
			bind("n", "<leader>ld", vim.lsp.buf.definition, "Go to definition")
			bind("n", "<leader>lD", vim.lsp.buf.declaration, "Go to declaration")
			bind("n", "<leader>li", vim.lsp.buf.implementation, "Go to implementation")
			bind("n", "<leader>lt", vim.lsp.buf.type_definition, "Go to type definition")
			bind("n", "<leader>lr", vim.lsp.buf.references, "Find references")
			bind("n", "<leader>lrn", vim.lsp.buf.rename, "Rename symbol")
			bind({ "n", "v" }, "<leader>la", vim.lsp.buf.code_action, "Code actions")
			bind("n", "<leader>lf", function()
				local conform_ok, conform = pcall(require, "conform")
				if conform_ok then
					conform.format { timeout_ms = 3000, lsp_format = "fallback" }
				else
					vim.lsp.buf.format { async = true }
				end
			end, "Format document")
			bind("n", "<leader>le", vim.diagnostic.open_float, "Show diagnostic")
			bind("n", "<leader>lq", vim.diagnostic.setloclist, "Diagnostic list")
			bind("n", "<leader>lw", vim.diagnostic.setqflist, "Workspace diagnostics")
			bind("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
			bind("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
			bind("n", "<leader>lwa", vim.lsp.buf.add_workspace_folder, "Add workspace folder")
			bind("n", "<leader>lwr", vim.lsp.buf.remove_workspace_folder, "Remove workspace folder")
			bind("n", "<leader>lwl", function()
				print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
			end, "List workspace folders")
			bind("n", "<leader>lh", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }, { bufnr = bufnr })
			end, "Toggle inlay hints")
			bind("n", "<leader>ls", function()
				local clients = vim.lsp.get_clients { bufnr = bufnr }
				if #clients == 0 then
					print "No LSP clients attached to buffer"
					return
				end
				for _, client in ipairs(clients) do
					print("LSP: " .. client.name .. " (ID: " .. client.id .. ")")
				end
			end, "Show LSP status")
			bind("n", "<leader>lo", vim.lsp.buf.document_symbol, "Document symbols")
			bind("n", "<leader>lS", vim.lsp.buf.workspace_symbol, "Workspace symbols")
			bind("n", "<leader>lci", vim.lsp.buf.incoming_calls, "Incoming calls")
			bind("n", "<leader>lco", vim.lsp.buf.outgoing_calls, "Outgoing calls")

			-- Highlight symbol under cursor
			if client.server_capabilities.documentHighlightProvider then
				local group = vim.api.nvim_create_augroup("lsp_document_highlight_" .. bufnr, { clear = true })
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

			-- Disable built-in formatting if using external formatter
			if client.name ~= "clangd" then
				client.server_capabilities.documentFormattingProvider = false
				client.server_capabilities.documentRangeFormattingProvider = false
			end
		end

		-- Set up all servers from opts.servers
		for server, config in pairs(opts.servers) do
			local server_config = vim.tbl_deep_extend("force", {
				on_attach = on_attach,
				capabilities = capabilities,
			}, config)

			require("lspconfig")[server].setup(server_config)
		end

		-- Enhance default hover and signature help UI
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

		-- Custom LSP commands for convenience
		vim.api.nvim_create_user_command("LspRestart", function()
			vim.cmd "LspStop"
			vim.defer_fn(function()
				vim.cmd "LspStart"
			end, 500)
		end, { desc = "Restart LSP servers" })

		vim.api.nvim_create_user_command("LspLog", function()
			vim.cmd("edit " .. vim.lsp.get_log_path())
		end, { desc = "Open LSP log file" })

		vim.api.nvim_create_user_command("LspInfo", function()
			vim.cmd "LspInfo"
		end, { desc = "Show LSP client information" })

		-- LSP defaults
		vim.lsp.set_log_level "WARN"
		vim.opt.updatetime = 250
		vim.opt.signcolumn = "yes"
	end,
}
