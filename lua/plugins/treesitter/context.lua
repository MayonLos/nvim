return {
	"nvim-treesitter/nvim-treesitter-context",
	event = { "BufReadPost", "BufNewFile" },
	keys = function()
		return require("core.keymaps").plugin("treesitter-context")
	end,
	opts = {
		enable = true,
		max_lines = 4,
		min_window_height = 0,
		line_numbers = true,
		multiline_threshold = 20,
		trim_scope = "outer",
		mode = "cursor",
		separator = nil,
		zindex = 20,
	},
	config = function(_, opts)
		require("treesitter-context").setup(opts)
	end,
}
