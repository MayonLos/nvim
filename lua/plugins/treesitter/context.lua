return {
	"nvim-treesitter/nvim-treesitter-context",
	event = { "BufReadPost", "BufNewFile" },
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
		vim.keymap.set("n", "<leader>ut", "<cmd>TSContextToggle<cr>", { desc = "Toggle context" })
		vim.keymap.set("n", "[x", function()
			require("treesitter-context").go_to_context(vim.v.count1)
		end, { silent = true, desc = "Go to context" })
	end,
}
