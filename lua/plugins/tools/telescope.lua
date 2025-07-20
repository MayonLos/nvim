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
	keys = {
		-- File operations
		{ "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
		{ "<leader>fF", "<cmd>Telescope find_files hidden=true no_ignore=true<cr>", desc = "Find All Files" },
		{ "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Live Grep" },
		{ "<leader>fw", "<cmd>Telescope grep_string<cr>", desc = "Grep Word Under Cursor" },
		{ "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
		{ "<leader>fo", "<cmd>Telescope oldfiles<cr>", desc = "Recent Files" },
		{ "<leader>fr", "<cmd>Telescope resume<cr>", desc = "Resume Last Search" },

		-- LSP & Navigation
		{ "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols" },
		{ "<leader>fS", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", desc = "Workspace Symbols" },
		{ "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
		{ "<leader>fj", "<cmd>Telescope jumplist<cr>", desc = "Jump List" },
		{ "<leader>fm", "<cmd>Telescope marks<cr>", desc = "Marks" },

		-- Git
		{ "<leader>gc", "<cmd>Telescope git_commits<cr>", desc = "Git Commits" },
		{ "<leader>gC", "<cmd>Telescope git_bcommits<cr>", desc = "Buffer Git Commits" },

		-- Vim internals
		{ "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help Tags" },
		{ "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
		{ "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Commands" },
		{ "<leader>ft", "<cmd>ThemePicker<cr>", desc = "Theme Picker" },

		-- Current directory search
		{
			"<leader>f.",
			function()
				require("telescope.builtin").find_files {
					cwd = vim.fn.expand "%:p:h",
					prompt_title = "Find Files (Current Directory)",
				}
			end,
			desc = "Find Files in Current Directory",
		},
	},

	config = function()
		local telescope = require "telescope"
		local actions = require "telescope.actions"
		local action_state = require "telescope.actions.state"

		-- Custom action: copy file path to clipboard
		local function copy_to_clipboard(prompt_bufnr)
			local entry = action_state.get_selected_entry()
			if entry then
				local value = entry.path or entry.value or entry.display
				vim.fn.setreg("+", value)
				vim.notify("Copied: " .. vim.fn.fnamemodify(value, ":t"), vim.log.levels.INFO)
			end
		end

		telescope.setup {
			defaults = {
				-- UI customization
				prompt_prefix = "🔍 ",
				selection_caret = "➤ ",
				entry_prefix = "  ",
				multi_icon = "✓",

				-- Layout configuration
				layout_strategy = "horizontal",
				layout_config = {
					horizontal = {
						prompt_position = "top",
						preview_width = 0.6,
						width = 0.9,
						height = 0.9,
					},
					vertical = {
						prompt_position = "top",
						preview_height = 0.6,
						width = 0.9,
						height = 0.9,
					},
				},

				-- Sorting and display
				sorting_strategy = "ascending",
				path_display = { "truncate" },
				dynamic_preview_title = true,
				results_title = false,

				-- File patterns to ignore
				file_ignore_patterns = {
					"%.git/",
					"node_modules/",
					"%.venv/",
					"__pycache__/",
					"%.pyc",
					"%.class",
					"%.o",
					"%.so",
					"%.dll",
					"%.exe",
					"%.zip",
					"%.tar%.gz",
					"%.DS_Store",
					"%.swp",
					"%.log",
					"dist/",
					"build/",
					"target/",
					"%.min%.js",
					"%.min%.css",
					"package-lock.json",
					"yarn.lock",
				},

				-- Key mappings
				mappings = {
					i = {
						-- Navigation
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,
						["<C-n>"] = actions.cycle_history_next,
						["<C-p>"] = actions.cycle_history_prev,

						-- Actions
						["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
						["<C-y>"] = copy_to_clipboard,
						["<C-t>"] = actions.select_tab,
						["<C-d>"] = actions.delete_buffer,
						["<C-u>"] = false, -- Clear input
						["<C-/>"] = actions.which_key,
					},
					n = {
						-- Navigation
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,

						-- Actions
						["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
						["<C-y>"] = copy_to_clipboard,
						["<C-t>"] = actions.select_tab,
						["<C-d>"] = actions.delete_buffer,
						["?"] = actions.which_key,
						["q"] = actions.close,
						["<esc>"] = actions.close,
					},
				},

				-- Performance settings
				cache_picker = {
					num_pickers = 10,
					limit_entries = 1000,
				},

				winblend = 0,
			},

			-- Picker-specific configurations
			pickers = {
				find_files = {
					hidden = true,
					find_command = vim.fn.executable "fd" == 1
							and { "fd", "--type", "f", "--strip-cwd-prefix", "--exclude", ".git" }
						or { "find", ".", "-type", "f", "-not", "-path", "*/.git/*" },
					theme = "dropdown",
					previewer = false,
					layout_config = { width = 0.6, height = 0.6 },
				},

				live_grep = {
					additional_args = function()
						return vim.fn.executable "rg" == 1 and { "--hidden", "--glob", "!.git/*" } or {}
					end,
					theme = "ivy",
				},

				grep_string = {
					additional_args = function()
						return vim.fn.executable "rg" == 1 and { "--hidden", "--glob", "!.git/*" } or {}
					end,
					theme = "ivy",
				},

				buffers = {
					sort_lastused = true,
					sort_mru = true,
					show_all_buffers = false,
					theme = "dropdown",
					previewer = false,
					layout_config = { width = 0.6, height = 0.6 },
					mappings = {
						i = { ["<C-d>"] = actions.delete_buffer },
						n = { ["<C-d>"] = actions.delete_buffer },
					},
				},

				oldfiles = {
					theme = "dropdown",
					previewer = false,
					layout_config = { width = 0.6, height = 0.6 },
				},

				help_tags = { theme = "ivy" },
				keymaps = { theme = "ivy" },
				commands = { theme = "ivy" },

				colorscheme = {
					enable_preview = true,
					theme = "dropdown",
					layout_config = { width = 0.5, height = 0.7 },
				},

				diagnostics = {
					theme = "ivy",
					layout_config = { preview_width = 0.6 },
				},

				git_commits = { theme = "ivy" },
				git_bcommits = { theme = "ivy" },
			},

			-- Extensions configuration
			extensions = {
				fzf = {
					fuzzy = true,
					override_generic_sorter = true,
					override_file_sorter = true,
					case_mode = "smart_case",
				},
				["ui-select"] = {
					require("telescope.themes").get_dropdown {
						layout_config = { width = 0.6, height = 0.6 },
					},
				},
			},
		}

		-- Load extensions
		pcall(telescope.load_extension, "fzf")
		pcall(telescope.load_extension, "ui-select")

		-- Theme persistence functionality
		local theme_file = vim.fn.stdpath "data" .. "/nvim_colorscheme"

		-- Function to ensure colorscheme plugin is loaded
		local function ensure_colorscheme_loaded(name)
			local colorscheme_plugins = {
				catppuccin = "catppuccin",
				tokyonight = "tokyonight.nvim",
				gruvbox = "gruvbox.nvim",
				kanagawa = "kanagawa.nvim",
				["rose-pine"] = "rose-pine",
				onedark = "onedark.nvim",
				nord = "nord.nvim",
				dracula = "dracula.nvim",
			}

			-- Try to match and load the appropriate plugin
			for pattern, plugin in pairs(colorscheme_plugins) do
				if name:match(pattern) then
					pcall(require("lazy").load, { plugins = { plugin } })
					break
				end
			end
		end

		-- Function to save current colorscheme
		local function save_colorscheme(name)
			local file = io.open(theme_file, "w")
			if file then
				file:write(name)
				file:close()
			end
		end

		-- Function to load saved colorscheme
		local function load_saved_colorscheme()
			local file = io.open(theme_file, "r")
			if file then
				local theme = file:read("*all"):gsub("%s+", "") -- Remove whitespace
				file:close()
				if theme and theme ~= "" then
					ensure_colorscheme_loaded(theme)
					vim.schedule(function()
						local success = pcall(vim.cmd.colorscheme, theme)
						if success then
							vim.g.colors_name = theme -- Ensure vim knows the current colorscheme
						end
					end)
				end
			end
		end

		-- Create ThemePicker command
		vim.api.nvim_create_user_command("ThemePicker", function()
			require("telescope.builtin").colorscheme {
				enable_preview = true,
				theme = "dropdown",
				layout_config = { width = 0.5, height = 0.7 },
				attach_mappings = function(prompt_bufnr, map)
					local function apply_theme()
						local entry = action_state.get_selected_entry()
						if entry and entry.value then
							local name = entry.value
							ensure_colorscheme_loaded(name)

							vim.schedule(function()
								local success = pcall(vim.cmd.colorscheme, name)
								if success then
									vim.g.colors_name = name
									save_colorscheme(name)
									vim.notify("Applied and saved theme: " .. name, vim.log.levels.INFO)
								else
									vim.notify("Failed to apply theme: " .. name, vim.log.levels.ERROR)
								end
							end)
						end
						actions.close(prompt_bufnr)
					end

					map("i", "<CR>", apply_theme)
					map("n", "<CR>", apply_theme)
					return true
				end,
			}
		end, { desc = "Pick and apply colorscheme with persistence" })

		-- Note: Theme loading on startup is handled by the catppuccin config
		-- to avoid conflicts and ensure proper initialization order

		-- Save colorscheme when it changes (backup method)
		vim.api.nvim_create_autocmd("ColorScheme", {
			pattern = "*",
			callback = function()
				local current_scheme = vim.g.colors_name
				if current_scheme then
					save_colorscheme(current_scheme)
				end
			end,
		})
	end,
}
