return {
	{
		"neovim/nvim-lspconfig",
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			{ "saghen/blink.cmp" },
			{ "nvim-tree/nvim-web-devicons" },
		},

		opts = {
			servers = {
				bashls = {},
				clangd = {},
				pyright = {},
				marksman = {},
				lua_ls = {},
			},
		},

		config = function(_, opts)
			require("mason").setup()

			if pcall(require, "utils.icons") then
				require("utils.icons").apply_diagnostic_signs()
			end

			local on_attach = function(_, bufnr)
				local map = function(lhs, rhs, desc)
					vim.keymap.set("n", "<leader>l" .. lhs, rhs, {
						buffer = bufnr,
						desc = desc and ("LSP: " .. desc) or nil,
					})
				end

				map("d", vim.lsp.buf.definition, "Goto Definition")
				map("k", vim.lsp.buf.hover, "Hover Doc")
				map("i", vim.lsp.buf.implementation, "Goto Implementation")
				map("s", vim.lsp.buf.signature_help, "Signature Help")
				map("r", vim.lsp.buf.rename, "Rename")
				map("a", vim.lsp.buf.code_action, "Code Action")
				map("R", vim.lsp.buf.references, "References")
			end

			local lspconfig = require("lspconfig")
			local capabilities = require("blink.cmp").get_lsp_capabilities()

			for name, config in pairs(opts.servers) do
				lspconfig[name].setup(vim.tbl_deep_extend("force", {
					capabilities = capabilities,
					on_attach = on_attach,
				}, config or {}))
			end
		end,
	},
}
