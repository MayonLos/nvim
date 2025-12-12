return {
	"folke/trouble.nvim",
	cmd = { "Trouble" },
	keys = function()
		return require("core.keymaps").plugin("trouble")
	end,
	opts = {},
}
