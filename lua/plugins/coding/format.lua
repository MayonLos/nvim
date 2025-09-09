return {
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>f",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = { "n", "v" },
			desc = "Format buffer",
		},
	},
	opts = {
		default_format_opts = {
			timeout_ms = 3000,
			async = false,
			quiet = false,
			lsp_fallback = true,
		},

		formatters_by_ft = {
			lua = { "stylua" },
			python = { "black" },
			c = { "clang_format" },
			cpp = { "clang_format" },
			javascript = { "prettierd", "prettier", stop_after_first = true },
			typescript = { "prettierd", "prettier", stop_after_first = true },
			json = { "prettierd", "prettier", stop_after_first = true },
			yaml = { "prettierd", "prettier", stop_after_first = true },
			markdown = { "prettierd", "prettier", stop_after_first = true },
			sh = { "shfmt" },
			["_"] = { "trim_whitespace" },
		},

		format_on_save = function(bufnr)
			local bufname = vim.api.nvim_buf_get_name(bufnr)
			local skip_dirs = { "/node_modules/", "/.git/", "/build/", "/dist/" }

			for _, dir in ipairs(skip_dirs) do
				if bufname:match(dir) then
					return nil
				end
			end

			return {
				timeout_ms = 3000,
				lsp_fallback = true,
			}
		end,

		formatters = {
			stylua = {
				prepend_args = {
					"--indent-type=Tabs",
					"--column-width=100",
				},
			},
			black = {
				prepend_args = {
					"--line-length=88",
					"--fast",
				},
			},
			clang_format = {
				prepend_args = {
					"--style={BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never, ColumnLimit: 100}",
				},
			},
			shfmt = {
				prepend_args = {
					"-i=2",
					"-ci",
				},
			},
		},

		notify_on_error = true,
	},
}
