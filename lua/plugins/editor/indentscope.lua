return {
	{
		"lukas-reineke/indent-blankline.nvim",
		main = "ibl",
		event = { "BufReadPre", "BufNewFile", "VeryLazy" },
		config = function()
			local colors = {
				red = "#E06C75",
				yellow = "#E5C07B",
				blue = "#61AFEF",
				orange = "#D19A66",
				green = "#98C379",
				violet = "#C678DD",
				cyan = "#56B6C2",
			}
			local highlight = {
				"RainbowRed",
				"RainbowYellow",
				"RainbowBlue",
				"RainbowOrange",
				"RainbowGreen",
				"RainbowViolet",
				"RainbowCyan",
			}
			local hooks = require("ibl.hooks")
			-- Register highlight setup to define custom highlight groups
			hooks.register(hooks.type.HIGHLIGHT_SETUP, function()
				for name, hex in pairs(colors) do
					vim.api.nvim_set_hl(0, "Rainbow" .. name:gsub("^%l", string.upper), { fg = hex })
				end
			end)
			-- Register scope highlight from extmark to sync with delimiters
			hooks.register(hooks.type.SCOPE_HIGHLIGHT, hooks.builtin.scope_highlight_from_extmark)
			require("ibl").setup({
				indent = { char = "│" },
				scope = {
					enabled = true,
					show_start = true,
					show_end = false,
					injected_languages = false,
					highlight = { "Function", "Label" },
					priority = 500,
				},
				exclude = {
					filetypes = { "help", "lazy", "dashboard", "starter", "neo-tree", "Trouble" },
					buftypes = { "terminal", "nofile" },
				},
			})
		end,
	},
}
