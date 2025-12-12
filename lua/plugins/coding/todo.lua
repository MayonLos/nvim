return {
	"folke/todo-comments.nvim",
	dependencies = { "nvim-lua/plenary.nvim" },
	keys = function()
		return require("core.keymaps").plugin("todo")
	end,
	opts = {},
}
