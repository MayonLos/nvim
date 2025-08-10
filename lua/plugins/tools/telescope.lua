return {
	"nvim-telescope/telescope.nvim",
	tag = "0.1.8",
	cmd = "Telescope",
	dependencies = {
		"nvim-lua/plenary.nvim",
		{
			"nvim-telescope/telescope-fzf-native.nvim",
			build = "make",
			cond = function()
				return vim.fn.executable "make" == 1
			end,
		},
		{
			"nvim-telescope/telescope-ui-select.nvim",
			config = function()
				require("telescope").load_extension "ui-select"
			end,
		},
	},

	keys = function()
		local builtin = require "telescope.builtin"

		return {
			-- File related
			{ "<leader>ff", builtin.find_files, desc = "Find Files" },
			{ "<leader>fg", builtin.live_grep, desc = "Live Grep" },
			{ "<leader>fb", builtin.buffers, desc = "Buffers" },
			{ "<leader>fr", builtin.oldfiles, desc = "Recent Files" },
			{ "<leader>fw", builtin.grep_string, desc = "Grep Word" },

			-- LSP
			{ "gd", builtin.lsp_definitions, desc = "Go to Definition" },
			{ "gr", builtin.lsp_references, desc = "References" },
			{ "<leader>ds", builtin.lsp_document_symbols, desc = "Document Symbols" },
			{ "<leader>ws", builtin.lsp_workspace_symbols, desc = "Workspace Symbols" },
			{ "<leader>dd", builtin.diagnostics, desc = "Diagnostics" },

			-- Git
			{ "<leader>gc", builtin.git_commits, desc = "Git Commits" },
			{ "<leader>gb", builtin.git_branches, desc = "Git Branches" },
			{ "<leader>gs", builtin.git_status, desc = "Git Status" },

			-- Vim
			{ "<leader>vh", builtin.help_tags, desc = "Help Tags" },
			{ "<leader>vk", builtin.keymaps, desc = "Keymaps" },
			{ "<leader>vc", builtin.commands, desc = "Commands" },

			-- Shortcuts
			{ "<C-p>", builtin.find_files, desc = "Find Files" },
		}
	end,

	config = function()
		local telescope = require "telescope"
		local actions = require "telescope.actions"
		local action_state = require "telescope.actions.state"

		-- Simple copy path function
		local copy_path = function(prompt_bufnr)
			local entry = action_state.get_selected_entry()
			if entry then
				local path = entry.path or entry.value or tostring(entry)
				vim.fn.setreg("+", path)
				actions.close(prompt_bufnr)
				vim.notify("Copied: " .. vim.fn.fnamemodify(path, ":t"))
			end
		end

		telescope.setup {
			defaults = {
				-- Minimal UI
				prompt_prefix = " ",
				selection_caret = " ",
				entry_prefix = " ",
				multi_icon = "",

				-- Layout config
				layout_strategy = "horizontal",
				layout_config = {
					horizontal = {
						prompt_position = "top",
						preview_width = 0.55,
						width = 0.9,
						height = 0.8,
					},
				},
				sorting_strategy = "ascending",

				-- Path display - fix indentation issue
				path_display = { "truncate" },
				dynamic_preview_title = true,

				-- File ignore patterns
				file_ignore_patterns = {
					"%.git/",
					"node_modules/",
					"__pycache__/",
					"%.pyc",
					"dist/",
					"build/",
					"target/",
					"%.lock",
				},

				-- Preview config
				preview = {
					filesize_limit = 5,
					timeout = 250,
				},

				-- Simplified key mappings
				mappings = {
					i = {
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,
						["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
						["<C-y>"] = copy_path,
						["<C-s>"] = actions.select_horizontal,
						["<C-v>"] = actions.select_vertical,
						["<C-t>"] = actions.select_tab,
						["<C-u>"] = actions.preview_scrolling_up,
						["<C-d>"] = actions.preview_scrolling_down,
						["<C-/>"] = actions.which_key,
						["<ESC>"] = actions.close,
					},
					n = {
						["j"] = actions.move_selection_next,
						["k"] = actions.move_selection_previous,
						["q"] = actions.close,
						["<ESC>"] = actions.close,
						["<C-y>"] = copy_path,
						["s"] = actions.select_horizontal,
						["v"] = actions.select_vertical,
						["t"] = actions.select_tab,
						["<C-u>"] = actions.preview_scrolling_up,
						["<C-d>"] = actions.preview_scrolling_down,
						["?"] = actions.which_key,
					},
				},

				-- Color config
				color_devicons = true,
				use_less = true,
				set_env = { ["COLORTERM"] = "truecolor" },
			},

			pickers = {
				find_files = {
					hidden = false,
					no_ignore = false,
				},
				live_grep = {
					only_sort_text = true,
				},
				buffers = {
					show_all_buffers = true,
					sort_lastused = true,
					theme = "dropdown",
					previewer = false,
					mappings = {
						i = {
							["<C-d>"] = actions.delete_buffer + actions.move_to_top,
						},
					},
				},
				oldfiles = {
					only_cwd = true,
				},
				git_files = {
					show_untracked = true,
				},
				lsp_references = {
					trim_text = true,
					show_line = false,
				},
				diagnostics = {
					theme = "ivy",
					initial_mode = "normal",
					layout_config = {
						preview_cutoff = 9999,
					},
				},
			},

			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
				["ui-select"] = {
					require("telescope.themes").get_dropdown {
						winblend = 10,
						width = 0.5,
						previewer = false,
					},
				},
			},
		}

		-- Safely load extensions
		pcall(telescope.load_extension, "fzf")
		pcall(telescope.load_extension, "ui-select")
	end,
}
