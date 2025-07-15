return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	cmd = { "ConformInfo", "Format", "FormatToggle" },
	keys = {
		{
			"<leader>lf",
			function()
				vim.cmd("Format")
			end,
			desc = "Format buffer (Conform)",
		},
		{
			"<leader>lF",
			function()
				require("conform").format({
					formatters = { "injected" },
					timeout_ms = 3000,
					lsp_format = "never",
				})
			end,
			mode = { "n", "v" },
			desc = "Format Injected Langs",
		},
	},
	dependencies = { "mason-org/mason.nvim" },

	config = function()
		local conform = require("conform")
		vim.g.autoformat_enabled = true

		conform.setup({
			default_format_opts = {
				timeout_ms = 3000,
				lsp_format = "never",
			},

			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				sh = { "shfmt" },
				markdown = { "prettier" },
				json = { "prettier" },
				yaml = { "prettier" },
				html = { "prettier" },
				css = { "prettier" },
				javascript = { "prettier" },
				typescript = { "prettier" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				["*"] = { "trim_whitespace" },
			},

			formatters = {
				stylua = {
					prepend_args = { "--indent-width", "2", "--column-width", "100" },
				},
				shfmt = {
					prepend_args = { "-i", "2", "-ci" },
				},
				clang_format = {
					prepend_args = {
						"--style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4}",
						"-assume-filename",
						"$FILENAME",
					},
				},
				prettier = {
					prepend_args = { "--tab-width", "2", "--print-width", "100" },
				},
				injected = {
					options = { ignore_errors = true },
				},
			},

			format_on_save = function(bufnr)
				if vim.g.autoformat_enabled then
					return { bufnr = bufnr }
				end
			end,

			log_level = vim.log.levels.WARN,
			notify_on_error = true,
			notify_no_formatters = true,
		})

		vim.api.nvim_create_user_command("FormatToggle", function()
			vim.g.autoformat_enabled = not vim.g.autoformat_enabled
			local msg = "Autoformat " .. (vim.g.autoformat_enabled and "Enabled" or "Disabled")
			vim.notify(msg, vim.log.levels.INFO, { title = "conform.nvim" })
		end, {})

		vim.api.nvim_create_user_command("Format", function()
			conform.format()
		end, {})
	end,
}
