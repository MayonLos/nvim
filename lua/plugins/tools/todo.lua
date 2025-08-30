return {
	"folke/todo-comments.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	keys = {
		{ "<leader>ft", "<cmd>TodoFzfLua<CR>", desc = "TODOs: project (FzfLua)" },
		{
			"]t",
			function()
				require("todo-comments").jump_next()
			end,
			desc = "Next TODO comment",
		},
		{
			"[t",
			function()
				require("todo-comments").jump_prev()
			end,
			desc = "Previous TODO comment",
		},
	},
	opts = {},
}
