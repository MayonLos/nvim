return {
	"romgrk/barbar.nvim",
	version = "^1.0.0",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"lewis6991/gitsigns.nvim",
	},
	init = function()
		vim.g.barbar_auto_setup = false
	end,
	opts = {
		animation = true,
		tabpages = true,
		focus_on_close = "left",
		insert_at_end = false,
		maximum_length = 30,
		minimum_padding = 1,
		maximum_padding = 1,

		icons = {
			preset = "default",
			buffer_index = false,
			buffer_number = false,
			button = "",
			modified = { button = "●" },
			pinned = { button = "", filename = true },
			separator = { left = "▎", right = "" },
			filetype = { enabled = true, custom_colors = false },
		},

		sidebar_filetypes = {
			NvimTree = true,
			undotree = { text = "UndoTree", align = "center" },
			Outline = { text = "Symbols", align = "right" },
		},

		sort = {
			ignore_case = true,
		},
	},
}
