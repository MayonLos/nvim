return {
	"saghen/blink.cmp",
	version = "1.*",
	lazy = false,
	dependencies = {
		"rafamadriz/friendly-snippets",
	},
	opts_extend = { "sources.default" },

	opts = function()
		local keymaps = {
			insert = {
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide" },
				["<CR>"] = { "accept", "fallback" },
				["<Up>"] = { "select_prev", "fallback" },
				["<Down>"] = { "select_next", "fallback" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
				["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
				["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
				["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
			},
			cmdline = {
				["<Tab>"] = { "show_and_insert", "select_next" },
				["<S-Tab>"] = { "show_and_insert", "select_prev" },
				["<CR>"] = { "accept_and_enter", "fallback" },
			},
		}

		local sources = {
			default = { "lsp", "path", "snippets" },
			providers = {
				lsp = {
					module = "blink.cmp.sources.lsp",
					fallbacks = { "buffer" },
				},
				buffer = {
					module = "blink.cmp.sources.buffer",
					min_keyword_length = 3,
					max_items = 10,
					score_offset = -1,
				},
				snippets = {
					module = "blink.cmp.sources.snippets",
					min_keyword_length = 2,
					score_offset = -1,
				},
				markdown = {
					name = "RenderMarkdown",
					module = "render-markdown.integ.blink",
					fallbacks = { "lsp" },
				},
			},
			per_filetype = {
				markdown = { inherit_defaults = true, "markdown" },
			},
		}

		local disabled_filetypes = {
			"oil",
			"NvimTree",
			"DressingInput",
			"copilot-chat",
		}

		local function enabled()
			return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype)
		end

		return {
			keymap = vim.tbl_extend("force", { preset = "none" }, keymaps.insert),
			enabled = enabled,
			appearance = { nerd_font_variant = "mono" },
			signature = { enabled = true },
			cmdline = {
				completion = {
					list = {
						selection = { preselect = false, auto_insert = true },
					},
				},
				keymap = keymaps.cmdline,
			},
			completion = {
				documentation = { auto_show = true },
				keyword = { range = "prefix" },
				list = { selection = { preselect = false, auto_insert = false } },
				ghost_text = { enabled = true },
			},
			sources = sources,
			fuzzy = { implementation = "prefer_rust_with_warning" },
		}
	end,
}
