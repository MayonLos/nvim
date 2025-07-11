return {
	{
		"NeogitOrg/neogit",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
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
