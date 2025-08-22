return {
	"saghen/blink.cmp",
	version = "1.*",
	lazy = false,
	dependencies = {
		"rafamadriz/friendly-snippets",
	},

	opts_extend = { "sources.default" },

	opts = function()
		local disabled_filetypes = { "oil", "NvimTree", "DressingInput", "copilot-chat" }

		return {
			enabled = function()
				return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype)
			end,

			keymap = {
				preset = "enter",
				["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "cancel", "fallback" },
				["<Up>"] = { "select_prev", "fallback" },
				["<Down>"] = { "select_next", "fallback" },
				["<C-b>"] = { "scroll_documentation_up", "fallback" },
				["<C-f>"] = { "scroll_documentation_down", "fallback" },
				["<Tab>"] = { "snippet_forward", "fallback" },
				["<S-Tab>"] = { "snippet_backward", "fallback" },
				["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
			},

			appearance = { nerd_font_variant = "mono" },

			snippets = { preset = "default" },

			completion = {
				keyword = { range = "prefix" },
				list = { selection = { preselect = false, auto_insert = false } },
				documentation = { auto_show = true, auto_show_delay_ms = 300 },
				ghost_text = { enabled = true },
			},

			signature = { enabled = true },

			cmdline = {
				keymap = {
					preset = "inherit",
					["<CR>"] = { "accept_and_enter", "fallback" },
					["<Tab>"] = { "show_and_insert", "select_next" },
					["<S-Tab>"] = { "show_and_insert", "select_prev" },
				},
				completion = { menu = { auto_show = false } },
			},

			fuzzy = { implementation = "prefer_rust_with_warning" },

			sources = {
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
				},
				per_filetype = {
					markdown = { inherit_defaults = true },
				},
			},
		}
	end,
}
