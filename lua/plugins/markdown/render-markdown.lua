return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown", "llm", "codecompanion" },
	opts = {},
	config = function(_, opts)
		require("render-markdown").setup(opts)
	end,
}
