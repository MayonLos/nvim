return {
	{
		"stevearc/oil.nvim",
		cmd = { "Oil" },
		keys = {
			{ "<leader>e", "<cmd>Oil --float<CR>", desc = "Oil (floating file explorer)" },
			{ "-", "<cmd>Oil<CR>", desc = "Open parent directory" },
		},
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
			"JezerM/oil-lsp-diagnostics.nvim",
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
		config = function(_, opts)
			require("oil").setup(opts)
			require("oil-lsp-diagnostics").setup({
				update_delay = 500,
			})
		end,
	},
	{
		"JezerM/oil-lsp-diagnostics.nvim",
		event = { "FileType oil" },
		config = false,
	},
}
