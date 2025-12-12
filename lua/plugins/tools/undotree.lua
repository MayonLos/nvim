return {
	"mbbill/undotree",
	cmd = "UndotreeToggle",
	keys = function()
		return require("core.keymaps").plugin("undotree")
	end,
	init = function()
		vim.g.undotree_WindowLayout = 2
		vim.g.undotree_SplitWidth = 40
		vim.g.undotree_DiffpanelHeight = 8
		vim.g.undotree_SetFocusWhenToggle = 1
	end,
}
