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
			-- 初始化 Mason
			require("mason").setup()

			-- 应用诊断标志
			require("utils.icons").apply_diagnostic_signs()

			-- 共享的 LSP 能力
			local capabilities = vim.tbl_deep_extend(
				"force",
				require("blink.cmp").get_lsp_capabilities(),
				{ inlayHint = { enable = true } }
			)

			-- LSP 附件处理
			local on_attach = function(client, bufnr)
				-- 启用内嵌提示（Inlay Hints）
				if client.server_capabilities.inlayHintProvider then
					vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
				end

				-- 快捷键配置
				local keymap_opts = { buffer = bufnr, desc = "" }
				local bind = function(mode, lhs, rhs, desc)
					keymap_opts.desc = desc
					vim.keymap.set(mode, lhs, rhs, keymap_opts)
				end

				-- 使用 Neovim 内置 LSP 功能
				bind("n", "<leader>ld", vim.lsp.buf.definition, "Go to definition")
				bind("n", "<leader>lt", vim.lsp.buf.type_definition, "Go to type definition")
				bind("n", "<leader>lh", vim.lsp.buf.hover, "Hover documentation")
				bind("n", "<leader>lr", vim.lsp.buf.rename, "Rename symbol")
				bind("n", "<leader>la", vim.lsp.buf.code_action, "Code actions")
			end

			-- 配置 LSP 服务器
			for server, config in pairs(opts.servers) do
				require("lspconfig")[server].setup(vim.tbl_deep_extend("force", {
					on_attach = on_attach,
					capabilities = capabilities,
				}, config))
			end
		end,
	},
}
