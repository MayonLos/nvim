return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		cmd = { "Neotree" },
		keys = {
			{ "<leader>ee", "<cmd>Neotree toggle<cr>", desc = "Neo-tree: Toggle" },
			{ "<leader>ef", "<cmd>Neotree focus<cr>", desc = "Neo-tree: Focus explorer" },
			{ "<leader>eg", "<cmd>Neotree git_status<cr>", desc = "Neo-tree: Git status" },
			{ "<leader>eb", "<cmd>Neotree buffers<cr>", desc = "Neo-tree: Buffers" },
			{ "<leader>es", "<cmd>Neotree document_symbols<cr>", desc = "Neo-tree: Document symbols" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim",
			{
				"s1n7ax/nvim-window-picker",
				opts = {
					autoselect_one = true,
					include_current = false,
					filter_rules = {
						bo = {
							filetype = { "neo-tree", "neo-tree-popup", "notify" },
							buftype = { "terminal", "quickfix" },
						},
					},
				},
			},
		},

		init = function()
			vim.g.loaded_netrw = 1
			vim.g.loaded_netrwPlugin = 1
		end,

		opts = {
			close_if_last_window = true,
			popup_border_style = "rounded",
			enable_git_status = true,
			enable_diagnostics = true,

			sources = { "filesystem", "buffers", "git_status", "document_symbols" },
			source_selector = {
				winbar = true,
				content_layout = "center",
				sources = {
					{ source = "filesystem", display_name = " 󰉓 Files " },
					{ source = "buffers", display_name = " 󰈚 Buffers " },
					{ source = "git_status", display_name = " 󰊢 Git " },
					{ source = "document_symbols", display_name = " 󰘦 LSP " },
				},
			},

			default_component_configs = {
				indent = { padding = 1, indent_size = 2, with_markers = true },
				icon = { folder_closed = "", folder_open = "", folder_empty = "󰜌", default = "󰈚" },
				modified = { symbol = "●" },
				name = { trailing_slash = false, use_git_status_colors = true },
				git_status = {
					symbols = {
						added = " ",
						modified = " ",
						deleted = " ",
						renamed = " ",
						untracked = " ",
						ignored = " ",
						unstaged = " ",
						staged = " ",
						conflict = " ",
					},
				},
				diagnostics = { symbols = { hint = "󰌶 ", info = " ", warn = " ", error = " " } },
			},

			filesystem = {
				bind_to_cwd = true,
				follow_current_file = { enabled = true, leave_dirs_open = false },
				group_empty_dirs = true,
				use_libuv_file_watcher = true,
				filtered_items = {
					visible = false,
					hide_dotfiles = false,
					hide_gitignored = true,
					never_show = { ".DS_Store", "thumbs.db" },
				},
				hijack_netrw_behavior = "open_current",
				window = {
					position = "left",
					width = 32,
					mappings = {
						["<cr>"] = "open_with_window_picker",
						["l"] = "focus_preview",
						["h"] = "close_node",
						["H"] = "toggle_hidden",
						["P"] = "toggle_preview",
						["a"] = { "add", config = { show_path = "relative" } },
						["A"] = "add_directory",
						["d"] = "delete",
						["r"] = "rename",
						["y"] = "copy_to_clipboard",
						["x"] = "cut_to_clipboard",
						["p"] = "paste_from_clipboard",
						["c"] = "copy",
						["m"] = "move",
						["R"] = "refresh",
						["q"] = "close_window",
						["?"] = "show_help",
					},
				},
			},

			buffers = {
				follow_current_file = { enabled = true },
				group_empty_dirs = true,
				show_unloaded = true,
				window = {
					mappings = {
						["bd"] = "buffer_delete",
						["<cr>"] = "open_with_window_picker",
					},
				},
			},

			git_status = {
				window = { position = "float" },
			},

			event_handlers = {
				{
					event = "neo_tree_buffer_enter",
					handler = function(_)
						vim.opt_local.relativenumber = true
					end,
				},
			},
		},

		config = function(_, opts)
			pcall(function()
				require("catppuccin").setup { integrations = { neotree = true } }
			end)
			require("neo-tree").setup(opts)
		end,
	},
}
