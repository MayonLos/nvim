return {
	"ibhagwan/fzf-lua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	cmd = "FzfLua",
	keys = {
		{ "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find Files" },
		{ "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live Grep" },
		{ "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
		{ "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent Files" },
		{ "<leader>fh", "<cmd>FzfLua helptags<cr>", desc = "Help" },
		{ "<leader>gs", "<cmd>FzfLua git_status<cr>", desc = "Git Status" },
		{ "<leader>gc", "<cmd>FzfLua git_commits<cr>", desc = "Git Commits" },
		{ "<leader>f.", "<cmd>FzfLua blines<cr>", desc = "Buffer Lines" },
	},
	opts = {},
	config = function(_, opts)
		local fzf = require "fzf-lua"
		fzf.setup(opts)
		fzf.register_ui_select()
	end,
}
