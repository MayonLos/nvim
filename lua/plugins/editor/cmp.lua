return {
	{
		"saghen/blink.cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = { "rafamadriz/friendly-snippets" },
		build = "cargo build --release",
		version = "1.*",
		config = function()
			require("blink.cmp").setup({
				keymap = {
					preset = "none",
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
				enabled = function()
					return not vim.tbl_contains({}, vim.bo.filetype)
				end,
				appearance = {
					nerd_font_variant = "mono",
				},
				signature = { enabled = true },
				cmdline = {
					completion = {
						list = { selection = { preselect = false, auto_insert = true } },
					},
					keymap = {
						["<Tab>"] = { "show_and_insert", "select_next" },
						["<S-Tab>"] = { "show_and_insert", "select_prev" },
						["<CR>"] = { "accept_and_enter", "fallback" },
					},
				},
				completion = {
					documentation = { auto_show = true },
					keyword = { range = "full" },
					list = { selection = { preselect = true, auto_insert = false } },
					ghost_text = { enabled = true },
				},
				sources = {
					default = { "lsp", "path", "snippets", "buffer" },
					providers = {
						markdown = {
							name = "RenderMarkdown",
							module = "render-markdown.integ.blink",
							fallbacks = { "lsp" },
						},
					},
					per_filetype = {
						markdown = { inherit_defaults = true, "markdown" },
					},
				},
				fuzzy = { implementation = "prefer_rust_with_warning" },
			})
		end,
		opts_extend = { "sources.default" },
	},
}
