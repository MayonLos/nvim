return {
	"MeanderingProgrammer/render-markdown.nvim",
	ft = { "markdown", "llm", "codecompanion" },
	config = function()
		require("render-markdown").setup {
			completions = { blink = { enabled = true } },
		}
	end,
}
