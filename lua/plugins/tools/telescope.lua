return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "make",
				cond = vim.fn.executable("make") == 1,
			},
		},
		keys = {
			{
				"<leader>ff",
				function()
					require("telescope.builtin").find_files()
				end,
				desc = "Find Files",
			},
			{
				"<leader>fg",
				function()
					require("telescope.builtin").live_grep()
				end,
				desc = "Live Grep",
			},
			{
				"<leader>fb",
				function()
					require("telescope.builtin").buffers()
				end,
				desc = "Buffers",
			},
			{
				"<leader>fo",
				function()
					require("telescope.builtin").oldfiles()
				end,
				desc = "Old Files",
			},
			{
				"<leader>fh",
				function()
					require("telescope.builtin").help_tags()
				end,
				desc = "Help Tags",
			},
			{
				"<leader>ft",
				function()
					vim.cmd("ThemePicker")
				end,
				desc = "Theme Picker",
			},

			{
				"<leader>fr",
				function()
					require("telescope.builtin").resume()
				end,
				desc = "Resume Last Telescope",
			},
		},
		opts = function()
			local actions = require("telescope.actions")

			return {
				defaults = {
					layout_strategy = "horizontal",
					layout_config = {
						horizontal = {
							prompt_position = "top",
							preview_width = 0.55,
							height = 0.9,
							width = 0.9,
						},
						vertical = {
							prompt_position = "top",
							preview_height = 0.8,
							width = 0.9,
						},
						center = {
							prompt_position = "top",
							height = 0.5,
							width = 0.5,
						},
						cursor = {
							width = 0.4,
							height = 0.3,
						},
					},
					sorting_strategy = "ascending",
					path_display = { "truncate" },
					file_ignore_patterns = { "%.git/", "node_modules/", "%.venv/", "__pycache__/" },

					mappings = {
						i = {
							["<C-j>"] = actions.move_selection_next,
							["<C-k>"] = actions.move_selection_previous,
							["<C-y>"] = function(prompt_bufnr)
								local entry = require("telescope.actions.state").get_selected_entry()
								if entry then
									local val = entry.path or entry.value
									vim.fn.setreg("+", val)
									vim.notify("Copied to clipboard: " .. val, vim.log.levels.INFO)
								end
							end,
						},
					},
				},
				pickers = {
					find_files = {
						hidden = true,
						find_command = { "fd", "--type", "f", "--strip-cwd-prefix" },
					},
					live_grep = {
						additional_args = { "--hidden" },
					},
					buffers = {
						sort_lastused = true,
						ignore_current_buffer = false,
						sort_mru = true,
						show_all_buffers = true,
					},
				},
			}
		end,
		config = function(_, opts)
			local telescope = require("telescope")
			telescope.setup(opts)

			pcall(telescope.load_extension, "fzf")

			local theme_file = vim.fn.stdpath("config") .. "/lua/user/last_theme.lua"
			vim.fn.mkdir(vim.fn.fnamemodify(theme_file, ":h"), "p")

			local function ensure_colorscheme_loaded(name)
				if name:match("^catppuccin") then
					require("lazy").load({ plugins = { "catppuccin" } })
				end
			end

			vim.api.nvim_create_user_command("ThemePicker", function()
				require("telescope.builtin").colorscheme({
					enable_preview = true,
					attach_mappings = function(prompt_bufnr, map)
						local actions = require("telescope.actions")
						local state = require("telescope.actions.state")
						local function apply_theme()
							local entry = state.get_selected_entry()
							if entry and entry.value then
								local name = entry.value
								ensure_colorscheme_loaded(name)
								vim.fn.writefile({ "return " .. string.format("%q", name) }, theme_file)
								vim.schedule(function()
									pcall(vim.cmd.colorscheme, name)
								end)
							end
							actions.close(prompt_bufnr)
						end
						map("i", "<CR>", apply_theme)
						map("n", "<CR>", apply_theme)
						return true
					end,
				})
			end, {})
		end,
	},
}
