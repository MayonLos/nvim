return {
	{
		"neovim/nvim-lspconfig",
		event = "BufReadPre",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			{ "saghen/blink.cmp" },
			{ "echasnovski/mini.icons" },
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
			require("utils.icons").apply_diagnostic_signs()

			local on_attach = function(_, bufnr)
				local function map(lhs, rhs, desc)
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

			local capabilities = require("blink.cmp").get_lsp_capabilities()
			local lspconfig = require("lspconfig")

			for server, config in pairs(opts.servers) do
				lspconfig[server].setup(vim.tbl_deep_extend("force", {
					on_attach = on_attach,
					capabilities = capabilities,
				}, config or {}))
			end
		end,
	},
}
