return {
	"lukas-reineke/indent-blankline.nvim",
	main = "ibl",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = { "nvim-treesitter/nvim-treesitter" },

	opts = function()
		local hooks = require "ibl.hooks"

		local function palette()
			local bg = vim.o.background
			if bg == "light" then
				return {
					indent = { "#D1D5DB", "#9CA3AF", "#6B7280", "#4B5563" },
					scope = "#2563EB",
				}
			end
			return {
				indent = { "#3C4556", "#4B5563", "#6B7280", "#9CA3AF" },
				scope = "#60A5FA",
			}
		end

		local indent_hl = { "IBLIndent1", "IBLIndent2", "IBLIndent3", "IBLIndent4" }
		local scope_hl = "IBLScope"

		-- react to colorscheme changes
		hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
			local colors = palette()
			for i, c in ipairs(colors.indent) do
				vim.api.nvim_set_hl(0, "IBLIndent" .. i, { fg = c, nocombine = true })
			end
			vim.api.nvim_set_hl(0, scope_hl, { fg = colors.scope, bold = true, nocombine = true })
		end)

		-- treesitter-based scope detection
		hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)

		local exclude_ft = {
			"help",
			"man",
			"markdown",
			"text",
			"lazy",
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
			"Outline",
			"undotree",
			"checkhealth",
		}

		local exclude_bt = { "terminal", "nofile", "quickfix", "prompt", "popup", "acwrite" }

		return {
			enabled = true,
			debounce = 150,
			viewport_buffer = { min = 30, max = 400 },

			indent = {
				char = "▏",
				tab_char = "▏",
				smart_indent_cap = true,
				priority = 2,
				highlight = indent_hl,
			},

			whitespace = {
				highlight = indent_hl,
				remove_blankline_trail = true,
			},

			scope = {
				enabled = true,
				char = "▎",
				show_start = false,
				show_end = false,
				show_exact_scope = true,
				injected_languages = true,
				highlight = { scope_hl },
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

		-- Toggle commands
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

		-- light tweaks per filetype
		local ft_configs = {
			json = { scope = { enabled = false } },
			yaml = { scope = { enabled = false } },
			markdown = { enabled = false },
		}

		vim.api.nvim_create_autocmd("FileType", {
			callback = function(args)
				local cfg = ft_configs[args.match]
				if cfg then
					ibl.setup_buffer(args.buf, cfg)
				end
			end,
			desc = "Indent lines: filetype adjustments",
		})

		-- soften cost on very large files by thinning whitespace data
		hooks.register(hooks.type.WHITESPACE, function(_, bufnr, _, whitespace_tbl)
			local line_count = vim.api.nvim_buf_line_count(bufnr)
			if line_count > 10000 then
				return {}
			elseif line_count > 5000 then
				local sampled = {}
				for i = 1, #whitespace_tbl, 2 do
					sampled[#sampled + 1] = whitespace_tbl[i]
				end
				return sampled
			end
			return whitespace_tbl
		end)
	end,
}
