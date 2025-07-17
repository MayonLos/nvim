return {
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"sindrets/diffview.nvim",
		},
		cmd = { "Neogit" },
		keys = {
			{ "<leader>gg", "<cmd>Neogit<cr>", desc = "Open Neogit" },
		},
		config = function()
			require("neogit").setup({
				disable_commit_confirmation = false,
				integrations = {
					diffview = true,
					telescope = true,
				},
				kind = "tab",
			})
		end,
	},
}
