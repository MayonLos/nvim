return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = { "nvim-treesitter/nvim-treesitter" },

	opts = function()
		-- Optimized color scheme - more modern visual effect
		local colors = {
			indent = {
				"#374151", -- Softer gray
				"#4B5563",
				"#6B7280",
				"#9CA3AF",
			},
			scope = "#60A5FA", -- Brighter blue for scope
			scope_error = "#F87171", -- Error state
			scope_warn = "#FBBF24", -- Warning state
		}

		-- Performance-optimized exclude list
		local exclude_ft = {
			"help",
			"man",
			"markdown",
			"text",
			"txt",
			"lazy",
			"packer",
			"mason",
			"lspinfo",
			"dashboard",
			"alpha",
			"startify",
			"neo-tree",
			"NvimTree",
			"oil",
			"netrw",
			"toggleterm",
			"terminal",
			"TelescopePrompt",
			"TelescopeResults",
			"Trouble",
			"qf",
			"gitcommit",
			"fugitive",
			"notify",
			"aerial",
			"outline",
			"undotree",
			"tagbar",
			"vista",
			"checkhealth",
			"lsp-installer",
			"null-ls-info",
			"DiffviewFiles",
			"org",
			"noice",
		}

		local exclude_bt = {
			"terminal",
			"nofile",
			"quickfix",
			"prompt",
			"popup",
			"acwrite",
		}

		-- Smart highlight group setup
		local function setup_highlights()
			-- Gradient indent lines
			for i, color in ipairs(colors.indent) do
				vim.api.nvim_set_hl(0, "IBLIndent" .. i, { fg = color })
			end

			-- Scope highlight
			vim.api.nvim_set_hl(0, "IBLScope", {
				fg = colors.scope,
				bold = true,
				nocombine = true,
			})
			vim.api.nvim_set_hl(0, "IBLScopeError", {
				fg = colors.scope_error,
				bold = true,
			})
			vim.api.nvim_set_hl(0, "IBLScopeWarn", {
				fg = colors.scope_warn,
				bold = true,
			})
		end

		setup_highlights()

		return {
			enabled = true,
			debounce = 200, -- Performance: reduce update frequency
			viewport_buffer = {
				min = 30, -- Optimized viewport buffer
				max = 500,
			},

			indent = {
				char = "▏",
				tab_char = "▏",
				smart_indent_cap = true,
				priority = 2,
				repeat_linebreak = true,
			},

			whitespace = {
				highlight = { "IBLIndent1", "IBLIndent2", "IBLIndent3", "IBLIndent4" },
				remove_blankline_trail = true,
			},

			scope = {
				enabled = true,
				char = "▎",
				show_start = false,
				show_end = false,
				show_exact_scope = true,
				injected_languages = true,
				highlight = { "IBLScope" },
				priority = 1024,
				-- Optimized node type detection
				include = {
					node_type = {
						["*"] = {
							"class",
							"function",
							"method",
							"if_statement",
							"while_statement",
							"for_statement",
							"try_statement",
							"block",
							"compound_statement",
							"object",
							"table",
						},
						lua = { "chunk", "do_statement", "function_call", "table_constructor" },
						python = { "with_statement", "match_statement", "async_with_statement" },
						javascript = { "object_pattern", "jsx_element", "async_function" },
						typescript = { "interface_declaration", "type_alias_declaration" },
						rust = { "impl_item", "trait_item", "match_expression" },
						go = { "type_declaration", "select_statement" },
						cpp = { "class_specifier", "namespace_definition", "template_declaration" },
					},
				},
			},

			exclude = {
				filetypes = exclude_ft,
				buftypes = exclude_bt,
			},
		}
	end,

	config = function(_, opts)
		local ibl = require "ibl"
		local hooks = require "ibl.hooks"

		ibl.setup(opts)

		-- Smart color theme adaptation
		hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
			local bg = vim.o.background
			local colors = bg == "dark"
					and {
						indent = { "#374151", "#4B5563", "#6B7280", "#9CA3AF" },
						scope = "#60A5FA",
					}
				or {
					indent = { "#E5E7EB", "#D1D5DB", "#9CA3AF", "#6B7280" },
					scope = "#3B82F6",
				}

			for i, color in ipairs(colors.indent) do
				vim.api.nvim_set_hl(0, "IBLIndent" .. i, { fg = color })
			end
			vim.api.nvim_set_hl(0, "IBLScope", { fg = colors.scope, bold = true })
		end)

		-- Enhanced scope highlighting
		hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)

		-- Smart performance optimization
		hooks.register(hooks.type.WHITESPACE, function(_, bufnr, _, whitespace_tbl)
			local stats = vim.api.nvim_buf_get_changedtick(bufnr)
			local line_count = vim.api.nvim_buf_line_count(bufnr)

			-- Large file optimization strategy
			if line_count > 10000 then
				return {} -- Disable for very large files
			elseif line_count > 5000 then
				-- Sample display, reduce computation load
				local sampled = {}
				for i = 1, #whitespace_tbl, 2 do
					sampled[#sampled + 1] = whitespace_tbl[i]
				end
				return sampled
			end

			return whitespace_tbl
		end)

		-- Convenient commands
		vim.api.nvim_create_user_command("IBLToggle", function()
			local config = require("ibl.config").get_config(0)
			ibl.setup_buffer(0, { enabled = not config.enabled })
			vim.notify("Indent lines " .. (config.enabled and "disabled" or "enabled"))
		end, { desc = "Toggle indent lines" })

		vim.api.nvim_create_user_command("IBLScopeToggle", function()
			local config = require("ibl.config").get_config(0)
			local scope_enabled = config.scope and config.scope.enabled
			ibl.setup_buffer(0, { scope = { enabled = not scope_enabled } })
			vim.notify("Scope highlighting " .. (scope_enabled and "disabled" or "enabled"))
		end, { desc = "Toggle scope highlighting" })

		-- Smart filetype adaptation
		local ft_configs = {
			json = { scope = { enabled = false } },
			yaml = { scope = { enabled = false } },
			python = {
				indent = { smart_indent_cap = true },
				scope = { show_exact_scope = true },
			},
			markdown = { enabled = false },
		}

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				local ft = args.match
				local config = ft_configs[ft]
				if config then
					ibl.setup_buffer(0, config)
				end
			end,
			desc = "Apply filetype-specific indent line settings",
		})

		-- Memory cleanup optimization
		vim.api.nvim_create_autocmd({ "BufDelete", "BufWipeout" }, {
			callback = function(args)
				if vim.api.nvim_buf_is_valid(args.buf) then
					pcall(ibl.debounced_refresh, args.buf)
				end
			end,
			desc = "Cleanup indent-blankline resources",
		})

		-- On-demand loading optimization
		vim.api.nvim_create_autocmd("VimResized", {
			callback = function()
				vim.schedule(function()
					ibl.refresh_all()
				end)
			end,
			desc = "Refresh indent lines on window resize",
		})
	end,
}
