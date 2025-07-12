return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			require("catppuccin").setup({
				integrations = {
					diffview = true,
					gitsigns = true,
					mason = true,
					neogit = true,
					noice = true,
					dap = true,
					dap_ui = true,
					native_lsp = {
						enabled = true,
						virtual_text = {
							errors = { "italic" },
							hints = { "italic" },
							warnings = { "italic" },
							information = { "italic" },
							ok = { "italic" },
						},
						underlines = {
							errors = { "underline" },
							hints = { "underline" },
							warnings = { "underline" },
							information = { "underline" },
							ok = { "underline" },
						},
						inlay_hints = {
							background = true,
						},
					},
					notify = true,
					treesitter = true,
					ufo = true,
					overseer = true,
					render_markdown = true,
					telescope = {
						enabled = true,
						-- style = "nvchad"
					},
					lsp_trouble = true,
					which_key = true,
					rainbow_delimiters = true,
				},
			})
			local theme_file = vim.fn.stdpath("config") .. "/lua/user/last_theme.lua"
			local ok, saved = pcall(dofile, theme_file)
			local colorscheme = ok and type(saved) == "string" and #saved > 0 and saved or "catppuccin-frappe"
			vim.schedule(function()
				pcall(vim.cmd.colorscheme, colorscheme)
			end)
		end,
	},
}
