return {
	"dstein64/nvim-scrollview",
	event = { "BufReadPost", "BufNewFile" },
	config = function()
		vim.o.mouse = "a"
		require("scrollview").setup({
			excluded_filetypes = { "NvimTree", "neo-tree", "TelescopePrompt", "alpha", "dashboard" },
			current_only = true,
			base = "right",
			column = 1,
			winblend = 75,
			signs_on_startup = { "search", "marks", "git", "folds", "keywords" },
			diagnostics_severities = {},
			scrollview_priority = 100,
			handle = { text = "█" },
			handle_color = "CursorLine",
			marks = { max_signs = 200 },
		})
	end,
}
