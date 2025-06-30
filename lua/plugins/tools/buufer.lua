return {
	"echasnovski/mini.bufremove",
	version = false,
	event = "VeryLazy",

	config = function()
		vim.keymap.set("n", "<leader>bd", function()
			require("mini.bufremove").delete(0, false)
		end, { desc = "Delete buffer (smart)" })

		vim.keymap.set("n", "<leader>bD", function()
			require("mini.bufremove").delete(0, true)
		end, { desc = "Force delete buffer" })
	end,
}
