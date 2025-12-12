return {
	"folke/which-key.nvim",
	event = "VeryLazy",
	opts = {
		spec = {
			{ mode = { "n", "v" }, "<leader>a", group = "AI" },
			{ mode = { "n", "v" }, "<leader>b", group = "Buffer" },
			{ mode = { "n", "v" }, "<leader>d", group = "Debug" },
			{ mode = { "n", "v" }, "<leader>e", group = "Explorer" },
			{ mode = { "n", "v" }, "<leader>f", group = "Find/Search" },
			{ mode = { "n", "v" }, "<leader>l", group = "LSP/Code" },
			{ mode = { "n", "v" }, "<leader>t", group = "Todo/Tasks" },
			{ mode = { "n", "v" }, "<leader>u", group = "Undo/History" },
			{ mode = { "n", "v" }, "<leader>w", group = "Window" },
			{ mode = { "n", "v" }, "<leader>x", group = "Diagnostics" },
			{ "g", group = "Goto" },
			{ "z", group = "Fold" },
			{ "]", group = "Next" },
			{ "[", group = "Previous" },
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
