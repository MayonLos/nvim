return {
	"romgrk/barbar.nvim",
	event = "BufWinEnter",
	version = "^1.0.0",
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
		clickable = true,
		focus_on_close = "left",
		insert_at_end = false,
		maximum_padding = 1,
		minimum_padding = 1,
		maximum_length = 30,

		icons = {
			buffer_index = false,
			buffer_number = false,
			button = "",
			gitsigns = {
				added = { enabled = true, icon = "+" },
				changed = { enabled = true, icon = "~" },
				deleted = { enabled = true, icon = "-" },
			},
			modified = { button = "●" },
			pinned = { button = "", filename = true },
			separator = { left = "▎", right = "" },
			filetype = { enabled = true, custom_colors = false },
			preset = "default",
		},

		sidebar_filetypes = {
			NvimTree = true,
			undotree = { text = "undotree", align = "center" },
			Outline = { event = "BufWinLeave", text = "symbols-outline", align = "right" },
		},

		sort = {
			ignore_case = true,
		},
	},
}
