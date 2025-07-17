return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		keys = { "<leader>" },
		config = function()
			local wk = require("which-key")
			wk.setup({})
			wk.add({
				{ "<leader>a", group = "AI" },
				{ "<leader>b", group = "buffer" },
				{ "<leader>f", group = "file" },
				{ "<leader>g", group = "git" },
				{ "<leader>l", group = "lsp" },
				{ "<leader>m", group = "markdown" },
				{ "<leader>s", group = "session/split" },
				{ "<leader>t", group = "terminal" },
				{ "<leader>x", group = "diagnostics" },
			})
		end,
	},
}
