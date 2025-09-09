return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		spec = {
			{ mode = { "n", "v" }, "<leader>f", group = "Find/File" },
			{ mode = { "n", "v" }, "<leader>a", group = "AI" },
			{ mode = { "n", "v" }, "<leader>b", group = "Buffer" },
			{ mode = { "n", "v" }, "<leader>c", group = "Comment" },
			{ mode = { "n", "v" }, "<leader>e", group = "Explorer" },
			{ "g", group = "Goto" },
			{ "z", group = "Fold" },
			{ "]", group = "Next" },
			{ "[", group = "Previous" },
			{ "<C-w>", group = "Window" },
		},
		icons = {
			breadcrumb = "»",
			separator = "➜",
			group = "+",
			mappings = false,
		},
	},
	config = function(_, opts)
		local wk = require("which-key")
		wk.setup(opts)
	end,
}
