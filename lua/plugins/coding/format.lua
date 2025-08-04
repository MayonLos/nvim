return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	cmd = { "ConformInfo", "Format", "FormatToggle", "FormatBufferToggle", "FormatStatus" },
	keys = {
		{
			"<leader>pf",
			"<cmd>Format<cr>",
			desc = "Format buffer manually",
		},
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
		{
			"<leader>pt",
			"<cmd>FormatToggle<cr>",
			desc = "Toggle global autoformat",
		},
		{
			"<leader>pb",
			"<cmd>FormatBufferToggle<cr>",
			desc = "Toggle buffer autoformat",
		},
		{
			"<leader>ps",
			"<cmd>FormatStatus<cr>",
			desc = "Show format status",
		},
	},
	dependencies = { "mason.nvim" },
	config = function()
		local conform = require "conform"

		-- Global autoformat state (enabled by default)
		vim.g.autoformat_enabled = true

		conform.setup {
			default_format_opts = {
				timeout_ms = 5000,
				lsp_format = "fallback", -- Use LSP as fallback if no formatter available
			},
			formatters_by_ft = {
				-- Core languages you use
				lua = { "stylua" },
				python = { "isort", "black" },
				c = { "clang_format" },
				cpp = { "clang_format" },
				markdown = { "prettierd", "prettier", stop_after_first = true },

				-- Generic fallback for whitespace cleanup
				["_"] = { "trim_whitespace" },
			},

			formatters = {
				-- Stylua configuration
				stylua = {
					prepend_args = {
						"--indent-width",
						"4",
						"--column-width",
						"120",
						"--quote-style",
						"AutoPreferDouble",
						"--call-parentheses",
						"None",
					},
				},

				-- Shell formatter
				shfmt = {
					prepend_args = {
						"-i",
						"4", -- 4 space indentation
						"-ci", -- indent switch cases
						"-bn", -- binary ops like && and | may start a line
					},
				},

				-- C/C++ formatter with modern 4-space indentation
				clang_format = {
					prepend_args = {
						"--style={"
							.. "BasedOnStyle: LLVM, "
							.. "IndentWidth: 4, "
							.. "TabWidth: 4, "
							.. "ColumnLimit: 120, "
							.. "UseTab: Never, "
							.. "AlignConsecutiveAssignments: Consecutive, "
							.. "AlignConsecutiveDeclarations: Consecutive, "
							.. "AllowShortFunctionsOnASingleLine: Empty, "
							.. "AllowShortIfStatementsOnASingleLine: Never, "
							.. "AllowShortLoopsOnASingleLine: false, "
							.. "BreakBeforeBraces: Attach, "
							.. "SpaceAfterCStyleCast: true"
							.. "}",
					},
				},

				-- Prettier configuration
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

				-- Python
				black = {
					prepend_args = {
						"--line-length",
						"100",
					},
				},
				isort = {
					prepend_args = {
						"--profile",
						"black",
					},
				},

				-- Go formatter
				goimports = {
					prepend_args = { "-local", "" }, -- Set your module prefix here
				},

				-- Injected language support
				injected = {
					options = {
						ignore_errors = true,
						lang_to_formatters = {
							json = { "jq" },
							sql = { "sqlfluff" },
						},
					},
				},
			},

			format_on_save = function(bufnr)
				local bufname = vim.api.nvim_buf_get_name(bufnr)

				-- Skip formatting for certain patterns
				local skip_patterns = {
					"/node_modules/",
					"%.min%.",
					"/vendor/",
					"/build/",
					"/dist/",
					"%.lock$",
				}

				for _, pattern in ipairs(skip_patterns) do
					if bufname:match(pattern) then
						return
					end
				end

				-- Check global toggle
				if not vim.g.autoformat_enabled then
					return
				end

				-- Check buffer-local toggle (defaults to true if not set)
				if vim.b.autoformat_enabled == false then
					return
				end

				return {
					timeout_ms = 5000,
					lsp_format = "fallback",
				}
			end,

			log_level = vim.log.levels.WARN,
			notify_on_error = true,
			notify_no_formatters = false,
		}

		-- Enhanced user commands
		vim.api.nvim_create_user_command("FormatToggle", function()
			vim.g.autoformat_enabled = not vim.g.autoformat_enabled
			local status = vim.g.autoformat_enabled and "✅ enabled" or "❌ disabled"
			vim.notify(string.format("Global autoformat %s", status), vim.log.levels.INFO, { title = "Conform Format" })
		end, { desc = "Toggle global autoformat on save" })

		vim.api.nvim_create_user_command("Format", function(args)
			local opts = { timeout_ms = 5000, lsp_format = "fallback" }
			if args.range ~= 0 then
				opts.range = { args.line1, args.line2 }
			end
			conform.format(opts)
		end, {
			desc = "Format current buffer or range",
			range = true,
		})

		vim.api.nvim_create_user_command("FormatBufferToggle", function()
			-- Fix: Correctly initialize buffer state
			if vim.b.autoformat_enabled == nil then
				vim.b.autoformat_enabled = true
			end
			vim.b.autoformat_enabled = not vim.b.autoformat_enabled
			local status = vim.b.autoformat_enabled and "✅ enabled" or "❌ disabled"
			vim.notify(string.format("Buffer autoformat %s", status), vim.log.levels.INFO, { title = "Conform Format" })
		end, { desc = "Toggle autoformat for current buffer" })

		-- Show current formatting status
		vim.api.nvim_create_user_command("FormatStatus", function()
			local global_status = vim.g.autoformat_enabled and "✅ enabled" or "❌ disabled"
			-- Fix: Correctly display buffer status
			local buffer_enabled = vim.b.autoformat_enabled ~= false
			local buffer_status = buffer_enabled and "✅ enabled" or "❌ disabled"

			vim.notify(
				string.format("Autoformat Status:\n• Global: %s\n• Buffer: %s", global_status, buffer_status),
				vim.log.levels.INFO,
				{ title = "Conform Format" }
			)
		end, { desc = "Show current autoformat status" })
	end,
}
