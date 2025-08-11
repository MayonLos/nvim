return {
	"stevearc/oil.nvim",
	lazy = false, -- Officially recommended not to lazy load
	dependencies = { "nvim-tree/nvim-web-devicons" }, -- Optional: file icons
	keys = {
		{ "<leader>e", "<CMD>Oil --float<CR>", desc = "Open Oil file explorer (floating window)" },
	},
	config = function()
		require("oil").setup {
			default_file_explorer = true,
			view_options = {
				show_hidden = true, -- Show hidden files
			},
			float = {
				padding = 2,
				max_width = 0,
				max_height = 0,
				border = "rounded",
				win_options = { winblend = 0 },
			},
			keymaps = {
				["<CR>"] = "actions.select",
				["q"] = { "actions.close", mode = "n" },
				["<esc>"] = { "actions.close", mode = "n" },
				["-"] = { "actions.parent", mode = "n" },
				["g."] = { "actions.toggle_hidden", mode = "n" },
			},
			use_default_keymaps = false, -- Disable default keymaps to avoid conflicts
		}
	end,
}
