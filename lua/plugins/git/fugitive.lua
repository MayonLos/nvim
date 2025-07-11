return {
	"tpope/vim-fugitive",
	cmd = { "Git", "G" },
	keys = {
		{ "<leader>gS", "<cmd>Git<CR>", desc = "Git Status" },
		{ "<leader>gC", "<cmd>Git commit<CR>", desc = "Git Commit" },
		{ "<leader>gP", "<cmd>Git push<CR>", desc = "Git Push" },
		{ "<leader>gL", "<cmd>Git pull<CR>", desc = "Git Pull" },
		{ "<leader>gD", "<cmd>Gdiffsplit<CR>", desc = "Git Diff" },
	},
}
