return {
	{
		"MeanderingProgrammer/render-markdown.nvim",
		ft = { "markdown", "llm" },
		dependencies = {
			"nvim-treesitter/nvim-treesitter",
			"nvim-tree/nvim-web-devicons",
			"saghen/blink.cmp",
		},
		opts = {
			heading = { position = "inline" },
			completions = { blink = { enabled = true } },
		},
	},
}
