return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			"mason-org/mason.nvim",
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
				lua_ls = {},
			},
		},

		config = function(_, opts)
			-- Initialize Mason
			require("mason").setup()

			-- Apply diagnostic signs
			require("utils.icons").apply_diagnostic_signs()

			-- Shared capabilities
			local capabilities = vim.tbl_deep_extend(
				"force",
				require("blink.cmp").get_lsp_capabilities(),
				{ inlayHint = { enable = true } }
			)

			-- LSP attachment handler
			local on_attach = function(client, bufnr)
				-- Enable inlay hints if supported
				if client.server_capabilities.inlayHintProvider then
					vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
				end

				-- Keybindings configuration
				local keymap_opts = { buffer = bufnr, desc = "" }
				local bind = function(mode, lhs, rhs, desc)
					keymap_opts.desc = desc
					vim.keymap.set(mode, lhs, rhs, keymap_opts)
				end

				bind("n", "<leader>ld", "<cmd>Lspsaga goto_definition<CR>", "Go to definition")
				bind("n", "<leader>lt", "<cmd>Lspsaga goto_type_definition<CR>", "Go to type definition")
				bind("n", "<leader>lp", "<cmd>Lspsaga peek_definition<CR>", "Peek definition")
				bind("n", "<leader>lh", "<cmd>Lspsaga hover_doc<CR>", "Hover documentation")
				bind("n", "<leader>lr", "<cmd>Lspsaga rename<CR>", "Rename symbol")
				bind("n", "<leader>la", "<cmd>Lspsaga code_action<CR>", "Code actions")
				bind(
					"n",
					"<leader>ls",
					"<cmd>Lspsaga show_workspace_diagnostics<CR>",
					"Workspace diagnostics"
				)
			end

			-- Configure LSP servers
			for server, config in pairs(opts.servers) do
				require("lspconfig")[server].setup(vim.tbl_deep_extend("force", {
					on_attach = on_attach,
					capabilities = capabilities,
				}, config))
			end
		end,
	},
}
