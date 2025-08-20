return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	cmd = { "ConformInfo", "Format", "FormatToggle", "FormatBufferToggle", "FormatStatus" },
	keys = {
		{ "<leader>pf", "<cmd>Format<cr>", desc = "Format buffer manually" },
		{
			"<leader>pi",
			function()
				require("conform").format {
					formatters = { "injected" },
					timeout_ms = 5000,
					lsp_format = "fallback",
				}
			end,
			mode = { "n", "v" },
			desc = "Format injected languages",
		},
		{ "<leader>pt", "<cmd>FormatToggle<cr>", desc = "Toggle global autoformat" },
		{ "<leader>pb", "<cmd>FormatBufferToggle<cr>", desc = "Toggle buffer autoformat" },
		{ "<leader>ps", "<cmd>FormatStatus<cr>", desc = "Show format status" },
	},
	dependencies = { "mason-org/mason.nvim" },

	config = function()
		local conform = require "conform"
		vim.g.autoformat_enabled = true

		conform.setup {
			default_format_opts = { timeout_ms = 5000, lsp_format = "fallback" },
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "isort", "black" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				markdown = { "prettierd", "prettier", stop_after_first = true },
				sh = { "shfmt" },
				["_"] = { "trim_whitespace" },
			},
			formatters = {
				stylua = {
					prepend_args = { "--indent-width", "4", "--column-width", "120", "--call-parentheses", "None" },
				},
				shfmt = { prepend_args = { "-i", "4", "-ci", "-bn" } },
				clang_format = {
					prepend_args = {
						"--style={"
							.. "BasedOnStyle: LLVM, IndentWidth: 4, TabWidth: 4, UseTab: Never, "
							.. "ColumnLimit: 120, AlignConsecutiveAssignments: Consecutive, "
							.. "AlignConsecutiveDeclarations: Consecutive, "
							.. "AllowShortFunctionsOnASingleLine: Empty, "
							.. "AllowShortIfStatementsOnASingleLine: Never, "
							.. "AllowShortLoopsOnASingleLine: false, "
							.. "BreakBeforeBraces: Attach, SpaceAfterCStyleCast: true"
							.. "}",
					},
				},
				prettier = {
					prepend_args = {
						"--tab-width",
						"2",
						"--print-width",
						"100",
						"--single-quote",
						"true",
						"--trailing-comma",
						"es5",
						"--semi",
						"true",
						"--bracket-spacing",
						"true",
						"--arrow-parens",
						"avoid",
					},
				},
				prettierd = {
					prepend_args = {
						"--tab-width",
						"2",
						"--print-width",
						"100",
						"--single-quote",
						"true",
						"--trailing-comma",
						"es5",
						"--semi",
						"true",
						"--bracket-spacing",
						"true",
						"--arrow-parens",
						"avoid",
					},
				},
				black = { prepend_args = { "--line-length", "100" } },
				isort = { prepend_args = { "--profile", "black" } },
				injected = {
					options = {
						ignore_errors = true,
						lang_to_formatters = { json = { "jq" }, sql = { "sqlfluff" } },
					},
				},
			},

			format_on_save = function(bufnr)
				local name = vim.api.nvim_buf_get_name(bufnr)
				local skip =
					{ "/node_modules/", "/vendor/", "/build/", "/dist/", "/target/", "/.git/", "%.min%.", "%.lock$" }
				for _, pat in ipairs(skip) do
					if name:match(pat) then
						return
					end
				end
				if not vim.g.autoformat_enabled then
					return
				end
				if vim.b.autoformat_enabled == false then
					return
				end
				return { timeout_ms = 5000, lsp_format = "fallback" }
			end,

			log_level = vim.log.levels.WARN,
			notify_on_error = true,
			notify_no_formatters = false,
		}

		vim.api.nvim_create_user_command("FormatToggle", function()
			vim.g.autoformat_enabled = not vim.g.autoformat_enabled
			vim.notify(
				("Global autoformat %s"):format(vim.g.autoformat_enabled and "✅ enabled" or "❌ disabled"),
				vim.log.levels.INFO,
				{ title = "Conform" }
			)
		end, {})

		vim.api.nvim_create_user_command("Format", function(args)
			local o = { timeout_ms = 5000, lsp_format = "fallback" }
			if args.range ~= 0 then
				o.range = { args.line1, args.line2 }
			end
			conform.format(o)
		end, { range = true })

		vim.api.nvim_create_user_command("FormatBufferToggle", function()
			if vim.b.autoformat_enabled == nil then
				vim.b.autoformat_enabled = true
			end
			vim.b.autoformat_enabled = not vim.b.autoformat_enabled
			vim.notify(
				("Buffer autoformat %s"):format(vim.b.autoformat_enabled and "✅ enabled" or "❌ disabled"),
				vim.log.levels.INFO,
				{ title = "Conform" }
			)
		end, {})

		vim.api.nvim_create_user_command("FormatStatus", function()
			local g = vim.g.autoformat_enabled and "✅ enabled" or "❌ disabled"
			local b = (vim.b.autoformat_enabled ~= false) and "✅ enabled" or "❌ disabled"
			vim.notify(
				("Autoformat Status:\n• Global: %s\n• Buffer: %s"):format(g, b),
				vim.log.levels.INFO,
				{ title = "Conform" }
			)
		end, {})
	end,
}
