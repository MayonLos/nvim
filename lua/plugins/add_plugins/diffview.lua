return {
	{
		"sindrets/diffview.nvim",
		lazy = true,
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewToggle", "DiffviewRefresh" },
		config = function()
			require("diffview").setup({
				enhanced_diff_hl = true,
				use_icons = true,
			})
		end,
	},
}
