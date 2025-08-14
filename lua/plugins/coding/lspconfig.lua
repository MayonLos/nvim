return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"mason-org/mason.nvim", -- LSP server installer
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

			-- LaTeX LSP configuration
			texlab = {
				settings = {
					texlab = {
						build = {
							executable = "latexmk",
							args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
							onSave = true,
						},
						chktex = {
							onEdit = false,
							onOpenAndSave = true,
						},
						diagnosticsDelay = 300,
						formatterLineLength = 80,
						forwardSearch = {
							executable = nil, -- Configure based on your PDF viewer
							args = {},
						},
						latexFormatter = "latexindent",
						latexindent = {
							modifyLineBreaks = false,
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

		-- on_attach: minimal setup, mostly using defaults
		local on_attach = function(client, bufnr)
			if client.server_capabilities.inlayHintProvider and opts.inlay_hints.enabled then
				vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			end

			-- Only add essential non-default keybindings
			local function bind(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, {
					buffer = bufnr,
					desc = desc,
					silent = true,
					noremap = true,
				})
			end

			-- LaTeX specific keybindings (not available by default)
			if client.name == "texlab" then
				bind("n", "<leader>lb", function()
					vim.lsp.buf.execute_command {
						command = "texlab.build",
						arguments = { vim.uri_from_bufnr(bufnr) },
					}
				end, "Build LaTeX document")
				bind("n", "<leader>lv", function()
					vim.lsp.buf.execute_command {
						command = "texlab.forwardSearch",
						arguments = { vim.uri_from_bufnr(bufnr) },
					}
				end, "Forward search (SyncTeX)")
			end

			-- Inlay hints toggle (useful utility)
			bind("n", "<leader>lh", function()
				vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }, { bufnr = bufnr })
			end, "Toggle inlay hints")

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

			-- Disable built-in formatting for certain servers (use external formatters)
			local disable_formatting = { "lua_ls", "pyright" }
			if vim.tbl_contains(disable_formatting, client.name) then
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

		-- LaTeX specific commands
		vim.api.nvim_create_user_command("LatexBuild", function()
			local clients = vim.lsp.get_clients { name = "texlab" }
			if #clients > 0 then
				vim.lsp.buf.execute_command {
					command = "texlab.build",
					arguments = { vim.uri_from_bufnr(0) },
				}
			else
				vim.notify("TexLab LSP not attached", vim.log.levels.WARN)
			end
		end, { desc = "Build current LaTeX document" })

		-- LSP defaults
		vim.lsp.set_log_level "WARN"
		vim.opt.updatetime = 250
		vim.opt.signcolumn = "yes"
	end,
}
