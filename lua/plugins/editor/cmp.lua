return {
	{
		"saghen/blink.cmp",
		event = { "InsertEnter", "CmdlineEnter" }, -- Load on InsertEnter and CmdlineEnter for cmdline completion
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
						ghost_text = { enabled = true },
						list = { selection = { preselect = false, auto_insert = false } },
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
					default = { "lsp", "path", "snippets", "buffer", "copilot" },
					providers = {
						copilot = {
							name = "Copilot",
							module = "blink-copilot",
							fallbacks = { "lsp" },
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
				},
				fuzzy = { implementation = "prefer_rust_with_warning" },
			})

			-- Autocommands for Copilot integration
			vim.api.nvim_create_autocmd("User", {
				pattern = "BlinkCmpMenuOpen",
				callback = function()
					vim.b.copilot_suggestion_hidden = true
				end,
			})
			vim.api.nvim_create_autocmd("User", {
				pattern = "BlinkCmpMenuClose",
				callback = function()
					vim.b.copilot_suggestion_hidden = false
				end,
			})
		end,
		opts_extend = { "sources.default" },
	},

	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot", -- Allow manual trigger via :Copilot
		event = { "InsertEnter" }, -- Load on InsertEnter
		config = function()
			require("copilot").setup({
				suggestion = {
					enabled = true,
					auto_trigger = true,
					keymap = {
						accept = "<C-y>", -- Changed to avoid conflict with blink.cmp's <Tab>
						next = "<M-]>",
						prev = "<M-[>",
						dismiss = "<C-e>", -- Align with blink.cmp's hide key
					},
				},
				filetypes = { ["*"] = true },
			})
		end,
	},

	{
		"fang2hou/blink-copilot",
		dependencies = { "saghen/blink.cmp", "zbirenbaum/copilot.lua" },
		event = { "InsertEnter" }, -- Load with blink.cmp and copilot.lua
		config = function()
			require("blink-copilot").setup({})
		end,
	},
}
