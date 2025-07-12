return {
	{
		"HiPhish/rainbow-delimiters.nvim",
		dependencies = { "nvim-treesitter/nvim-treesitter" }, -- Required for Tree-sitter support
		event = { "BufReadPre", "BufNewFile" }, -- Lazy loading on buffer events
		config = function()
			-- Defer setup to reduce startup impact
			vim.schedule(function()
				local rainbow_delimiters = require("rainbow-delimiters.setup")
				rainbow_delimiters.setup({
					highlight = {
						"RainbowDelimiterRed",
						"RainbowDelimiterYellow",
						"RainbowDelimiterBlue",
						"RainbowDelimiterOrange",
						"RainbowDelimiterGreen",
						"RainbowDelimiterViolet",
						"RainbowDelimiterCyan",
					},
				})
			end)
		end,
		-- Conditionally load only when Tree-sitter is available
		cond = function()
			return pcall(require, "nvim-treesitter")
		end,
	},
}
