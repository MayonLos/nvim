return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		spec = {
			-- Normal and visual mode groups
			{ mode = { "n", "v" }, "<leader>f", group = "Find/File" },
			{ mode = { "n", "v" }, "<leader>g", group = "Git" },
			{ mode = { "n", "v" }, "<leader>h", group = "Hunk" },
			{ mode = { "n", "v" }, "<leader>a", group = "AI" },
			{ mode = { "n", "v" }, "<leader>t", group = "Terminal/Toggle" },
			{ mode = { "n", "v" }, "<leader>b", group = "Buffer" },
			{ mode = { "n", "v" }, "<leader>c", group = "Comment" },
			{ mode = { "n", "v" }, "<leader>e", group = "Explorer" },

			-- Common vim operations
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
		local wk = require "which-key"
		wk.setup(opts)
	end,
}
