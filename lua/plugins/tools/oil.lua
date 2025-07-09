return {
	"stevearc/oil.nvim",
	cmd = "Oil",
	keys = {
		{ "<leader>e", "<cmd>Oil --float<cr>", desc = "Oil (floating file explorer)" },
		{ "-", "<cmd>Oil<cr>", desc = "Open parent directory" },
	},
	opts = {
		default_file_explorer = true, -- Take over directory buffers
		delete_to_trash = true, -- Use system trash
		skip_confirm_for_simple_edits = true,
		view_options = {
			show_hidden = true,
			natural_order = true, -- Improved number sorting
			sort = {
				{ "type", "asc" },
				{ "name", "asc" },
			},
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
			preview_split = "right", -- Preview on right side
		},
		win_options = {
			signcolumn = "yes",
		},
		keymaps = {
			["q"] = "actions.close",
			["<CR>"] = "actions.select",
			["<C-s>"] = "actions.select_split",
			["<C-v>"] = "actions.select_vsplit",
			["<C-t>"] = "actions.select_tab",
			["<BS>"] = "actions.parent",
			["~"] = "actions.tcd", -- cd to home
			["g."] = "actions.toggle_hidden", -- Toggle dotfiles
			["g?"] = "actions.show_help",
		},
		-- Use git integration for better VCS handling
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
			preview_method = "fast_scratch", -- Better performance
		},
	},
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"MunifTanjim/nui.nvim", -- Recommended for enhanced UI
	},
	init = function()
		-- Automatically close oil when opening a file
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "oil",
			callback = function()
				vim.keymap.set("n", "<Esc>", "<cmd>Oil<CR>", { buffer = true })
			end,
		})
	end,
}
