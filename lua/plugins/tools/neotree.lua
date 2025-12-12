return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		cmd = "Neotree",
		keys = function()
			return require("core.keymaps").plugin("neotree")
		end,
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
		opts = function()
			-- Avante 集成
			local function add_to_avante(state)
				local node = state.tree:get_node()
				if not node then
					return
				end

				local ok, avante_utils = pcall(require, "avante.utils")
				if not ok then
					vim.notify("Avante not available", vim.log.levels.WARN)
					return
				end

				local filepath = node:get_id()
				local relative_path = avante_utils.relative_path(filepath)
				local avante = require("avante").get()
				local was_open = avante:is_open()

				if not was_open then
					require("avante.api").ask()
					avante = require("avante").get()
				end

				if avante.file_selector then
					avante.file_selector:add_selected_file(relative_path)
					if not was_open then
						avante.file_selector:remove_selected_file("neo-tree filesystem [1]")
					end
					vim.notify("Added: " .. relative_path, vim.log.levels.INFO)
				end
			end

			return {
				close_if_last_window = true,
				popup_border_style = "rounded",
				enable_git_status = true,
				enable_diagnostics = true,

				default_component_configs = {
					indent = { padding = 1, indent_size = 2, with_markers = true },
					icon = {
						folder_closed = "",
						folder_open = "",
						folder_empty = "󰜌",
						default = "󰈚",
					},
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
					diagnostics = {
						symbols = {
							hint = "󰌶",
							info = "",
							warn = "",
							error = "",
						},
					},
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

					commands = {
						avante_add = add_to_avante,
					},

					window = {
						position = "left",
						width = 32,
						mappings = {
							["<cr>"] = "open_with_window_picker",
							["l"] = "open",
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
							["oa"] = "avante_add",
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
						handler = function()
							vim.opt_local.relativenumber = true
						end,
					},
				},
			}
		end,
		config = function(_, opts)
			pcall(function()
				require("catppuccin").setup({ integrations = { neotree = true } })
			end)
			require("neo-tree").setup(opts)
		end,
	},
}
