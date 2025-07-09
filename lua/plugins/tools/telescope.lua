return {
	{
		"nvim-telescope/telescope.nvim",
		tag = "0.1.8",
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope-ui-select.nvim",
			"debugloop/telescope-undo.nvim",
			{
				"ryanmsnyder/toggleterm-manager.nvim",
				dependencies = "akinsho/toggleterm.nvim",
			},
		},
		keys = {
			-- Core
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

			-- Extensions
			{
				"<leader>fu",
				function()
					local ok, _ = pcall(require("telescope").load_extension, "undo")
					if ok then
						require("telescope").extensions.undo.undo()
					else
						vim.notify("telescope-undo failed to load", vim.log.levels.ERROR)
					end
				end,
				desc = "Undo History",
			},
			{
				"<leader>tm",
				function()
					local ok, _ = pcall(require("telescope").load_extension, "toggleterm_manager")
					if ok then
						require("telescope").extensions.toggleterm_manager.toggleterm_manager()
					else
						vim.notify("toggleterm_manager failed to load", vim.log.levels.ERROR)
					end
				end,
				desc = "ToggleTerm Manager",
			},

			-- Theme Picker
			{
				"<leader>ft",
				function()
					vim.cmd("ThemePicker")
				end,
				desc = "Theme Picker",
			},
		},

		opts = function()
			local actions = require("telescope.actions")
			local dropdown = require("telescope.themes").get_dropdown

			return {
				defaults = {
					layout_strategy = "horizontal",
					layout_config = {
						prompt_position = "top",
						preview_width = 0.55,
						height = 0.9,
						width = 0.9,
					},
					sorting_strategy = "ascending",
					path_display = { "truncate" },
					file_ignore_patterns = { "%.git/", "node_modules/", "%.venv/", "__pycache__/" },

					mappings = {
						i = {
							["<C-j>"] = "move_selection_next",
							["<C-k>"] = "move_selection_previous",
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

				extensions = {
					["ui-select"] = dropdown({ previewer = false, prompt_title = false }),
					undo = {
						use_delta = true,
						side_by_side = true,
						vim_diff_opts = { ctxlen = vim.o.scrolloff },
						entry_format = "state #$ID, $STAT, $TIME",
					},
				},
			}
		end,

		config = function(_, opts)
			local telescope = require("telescope")
			telescope.setup(opts)

			for _, ext in ipairs({ "ui-select", "undo", "toggleterm_manager" }) do
				local ok, err = pcall(telescope.load_extension, ext)
				if not ok then
					vim.notify(
						"Failed to load Telescope extension: " .. ext .. "\n" .. tostring(err),
						vim.log.levels.ERROR
					)
				end
			end

			-- ThemePicker 命令
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
