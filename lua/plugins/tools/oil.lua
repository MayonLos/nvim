return {
	{
		"stevearc/oil.nvim",
		cmd = "Oil",
		keys = {
			{ "<leader>e", "<cmd>Oil --float<cr>", desc = "Oil (floating file explorer)" },
			{ "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
		},
		opts = {
			default_file_explorer = true,
			delete_to_trash = true,
			skip_confirm_for_simple_edits = true,
			constrain_cursor = false,
			view_options = {
				show_hidden = true,
				natural_order = "fast",
				sort = { { "type", "asc" }, { "name", "asc" } },
			},
			float = {
				padding = 2,
				max_width = 80,
				max_height = 30,
				border = "rounded",
				win_options = {
					winblend = 10,
					winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
				},
				preview_split = "right",
			},
			win_options = {
				signcolumn = "yes",
				cursorline = false,
				cursorcolumn = false,
			},
			keymaps = {
				["q"] = "actions.close",
				["<CR>"] = "actions.select",
				["<C-s>"] = { "actions.select", opts = { vertical = true } },
				["<C-v>"] = { "actions.select", opts = { horizontal = true } },
				["<C-t>"] = { "actions.select", opts = { tab = true } },
				["<BS>"] = "actions.parent",
				["~"] = "actions.tcd",
				["g."] = "actions.toggle_hidden",
				["g?"] = "actions.show_help",
			},
			git = {
				add = function(path)
					return true
				end,
				mv = function(src, dest)
					return true
				end,
				rm = function(path)
					return true
				end,
			},
			preview_win = {
				preview_method = "fast_scratch",
				update_on_cursor_moved = false,
			},
			watch_for_changes = false,
			cleanup_delay_ms = 1000,
		},
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
		},
		config = function(_, opts)
			require("oil").setup(opts)
		end,
	},
	{
		"JezerM/oil-lsp-diagnostics.nvim",
		dependencies = { "stevearc/oil.nvim" },
		event = "VeryLazy",
		opts = {
			update_delay = 500,
		},
	},
}
