return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		lazy = false, -- Load immediately
		config = function()
			-- Setup Catppuccin with Telescope integration and transparent background
			require("catppuccin").setup {
				flavour = "frappe",
				background = { light = "latte", dark = "frappe" },
				transparent_background = true, -- Enable full transparency
				float = { transparent = true, solid = false }, -- Transparent floats
				show_end_of_buffer = false,
				term_colors = true,
				dim_inactive = { enabled = false, shade = "dark", percentage = 0.15 },
				no_italic = false,
				no_bold = false,
				no_underline = false,
				styles = {
					comments = { "italic" },
					conditionals = { "italic" },
					loops = {},
					functions = {},
					keywords = {},
					strings = {},
					variables = {},
					numbers = {},
					booleans = {},
					properties = {},
					types = {},
					operators = {},
				},
				auto_integrations = true, -- Auto-detect and enable integrations
				integrations = {
					cmp = true,
					gitsigns = true,
					nvimtree = true,
					treesitter = true,
					notify = true,
				},
			}

			-- Apply colorscheme immediately
			vim.cmd.colorscheme "catppuccin"
		end,
	},
}
