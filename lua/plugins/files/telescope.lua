return {
	-- Core Telescope
	{
		"nvim-telescope/telescope.nvim",
		version = false,
		cmd = "Telescope",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
			"nvim-telescope/telescope-ui-select.nvim",
			"debugloop/telescope-undo.nvim",
			{
				"ryanmsnyder/toggleterm-manager.nvim",
				dependencies = { "akinsho/toggleterm.nvim" },
			},
		},
		keys = {
			{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
			{ "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
			{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
			{ "<leader>fo", "<cmd>Telescope oldfiles<cr>", desc = "Old Files" },
			{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
			{ "<leader>ft", "<cmd>ThemePicker<cr>", desc = "Theme Picker" },
			{ "<leader>tm", "<cmd>Telescope toggleterm_manager<cr>", desc = "Term Manager" },
			{ "<leader>fu", "<cmd>Telescope undo<cr>", desc = "Undo History" },
			{ "<leader>fr", "<cmd>Telescope resume<cr>", desc = "Resume Last Search" },
			{ "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Commands" },
			{ "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
		},
		opts = {
			defaults = {
				layout_strategy = "horizontal",
				layout_config = {
					horizontal = {
						preview_width = 0.55,
						prompt_position = "top",
						height = 0.9,
						width = 0.9,
					},
				},
				sorting_strategy = "ascending",
				winblend = 5,
				border = true,
				borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
				path_display = { "truncate" },
				file_ignore_patterns = {
					"%.git/",
					"node_modules/",
					"%.venv/",
					"__pycache__/",
					"%.class",
					"%.jar",
					"%.o",
					"%.out",
					"%.lock",
				},
				mappings = {
					i = {
						["<C-j>"] = "move_selection_next",
						["<C-k>"] = "move_selection_previous",
						["<C-s>"] = "select_horizontal",
						["<C-v>"] = "select_vertical",
						["<C-t>"] = "select_tab",
						["<C-u>"] = "preview_scrolling_up",
						["<C-d>"] = "preview_scrolling_down",
						["<C-q>"] = "send_selected_to_qflist",
					},
					n = {
						["<C-s>"] = "select_horizontal",
						["<C-v>"] = "select_vertical",
						["<C-t>"] = "select_tab",
					},
				},
				dynamic_preview_title = true,
				set_env = { COLORTERM = "truecolor" },
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
				},
			},
			extensions = {
				["ui-select"] = require("telescope.themes").get_dropdown({ previewer = false }),
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
				undo = {
					use_delta = true,
					side_by_side = true,
					vim_diff_opts = { ctxlen = vim.o.scrolloff },
					entry_format = "state #$ID, $STAT, $TIME",
				},
			},
		},
		config = function(_, opts)
			local t = require("telescope")
			t.setup(opts)
			for _, ext in ipairs({ "fzf", "ui-select", "undo", "toggleterm_manager" }) do
				pcall(t.load_extension, ext)
			end

			-- Theme Picker command
			local theme_file = vim.fn.stdpath("config") .. "/lua/user/last_theme.lua"
			vim.fn.mkdir(vim.fn.fnamemodify(theme_file, ":h"), "p", "0755")

			local function ensure_colorscheme(name)
				if name:match("^catppuccin") then
					require("lazy").load({ plugins = { "catppuccin" } })
				elseif name:match("^tokyonight") then
					require("lazy").load({ plugins = { "tokyonight" } })
				end
			end

			vim.api.nvim_create_user_command("ThemePicker", function()
				local last = vim.fn.filereadable(theme_file) == 1 and loadfile(theme_file)() or "default"
				require("telescope.builtin").colorscheme({
					enable_preview = true,
					default = last,
					attach_mappings = function(bufnr, map)
						local actions = require("telescope.actions")
						local action_state = require("telescope.actions.state")
						local function set_theme()
							local entry = action_state.get_selected_entry()
							if not entry then
								return
							end
							local name = entry.value
							vim.fn.writefile({ "return " .. vim.inspect(name) }, theme_file)
							ensure_colorscheme(name)
							vim.schedule(function()
								vim.cmd.colorscheme(name)
							end)
							actions.close(bufnr)
						end
						map("i", "<CR>", set_theme)
						map("n", "<CR>", set_theme)
						map("i", "<C-p>", function()
							local entry = action_state.get_selected_entry()
							if entry then
								ensure_colorscheme(entry.value)
								pcall(vim.cmd.colorscheme, entry.value)
							end
						end)
						return true
					end,
				})
			end, {})
		end,
	},
}
