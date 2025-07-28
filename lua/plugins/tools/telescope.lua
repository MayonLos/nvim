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
		local map = function(lhs, rhs, desc)
			return { lhs, rhs, desc = desc }
		end

		return {
			-- File
			map("<leader>ff", "<cmd>Telescope find_files<cr>", "Find Files"),
			map("<leader>fF", "<cmd>Telescope find_files hidden=true no_ignore=true<cr>", "Find All Files"),
			map("<leader>fg", "<cmd>Telescope live_grep<cr>", "Live Grep"),
			map("<leader>fw", "<cmd>Telescope grep_string<cr>", "Grep Word Under Cursor"),
			map("<leader>fb", "<cmd>Telescope buffers<cr>", "Buffers"),
			map("<leader>fo", "<cmd>Telescope oldfiles<cr>", "Recent Files"),
			map("<leader>fr", "<cmd>Telescope resume<cr>", "Resume Last Search"),
			map("<leader>f.", function()
				require("telescope.builtin").find_files {
					cwd = vim.fn.expand "%:p:h",
					prompt_title = "Find Files (Here)",
				}
			end, "Find Files in Current Directory"),

			-- LSP & Nav
			map("<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", "Document Symbols"),
			map("<leader>fS", "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>", "Workspace Symbols"),
			map("<leader>fd", "<cmd>Telescope diagnostics<cr>", "Diagnostics"),
			map("<leader>fD", "<cmd>Telescope diagnostics bufnr=0<cr>", "Buffer Diagnostics"),
			map("<leader>fj", "<cmd>Telescope jumplist<cr>", "Jump List"),
			map("<leader>fm", "<cmd>Telescope marks<cr>", "Marks"),
			map("<leader>fq", "<cmd>Telescope quickfix<cr>", "Quickfix List"),
			map("<leader>fl", "<cmd>Telescope loclist<cr>", "Location List"),

			-- Git
			map("<leader>gc", "<cmd>Telescope git_commits<cr>", "Git Commits"),
			map("<leader>gC", "<cmd>Telescope git_bcommits<cr>", "Buffer Git Commits"),

			-- Vim
			map("<leader>fh", "<cmd>Telescope help_tags<cr>", "Help Tags"),
			map("<leader>fk", "<cmd>Telescope keymaps<cr>", "Keymaps"),
			map("<leader>fc", "<cmd>Telescope commands<cr>", "Commands"),
			map("<leader>fC", "<cmd>Telescope command_history<cr>", "Command History"),
			map("<leader>f/", "<cmd>Telescope search_history<cr>", "Search History"),
			map("<leader>fR", "<cmd>Telescope registers<cr>", "Registers"),
			map("<leader>fa", "<cmd>Telescope autocommands<cr>", "Autocommands"),
			map("<leader>fH", "<cmd>Telescope highlights<cr>", "Highlights"),
			map("<leader>fv", "<cmd>Telescope vim_options<cr>", "Vim Options"),
		}
	end,

	config = function(_, opts)
		local telescope = require "telescope"
		local actions = require "telescope.actions"
		local state = require "telescope.actions.state"

		-- Copy path/value
		local copy = function(prompt_bufnr)
			local entry = state.get_selected_entry()
			if entry then
				local target = entry.path or entry.value or entry.display
				vim.fn.setreg("+", target)
				vim.notify("Copied: " .. vim.fn.fnamemodify(target, ":t"), vim.log.levels.INFO)
			end
		end

		-- Open in splits
		local split_open = function(prompt_bufnr, cmd)
			local entry = state.get_selected_entry()
			actions.close(prompt_bufnr)
			if entry then
				vim.cmd(cmd .. " " .. vim.fn.fnameescape(entry.path))
			end
		end

		telescope.setup(vim.tbl_deep_extend("force", opts, {
			defaults = {
				prompt_prefix = "  ",
				selection_caret = "➤ ",
				multi_icon = "✓",
				layout_strategy = "horizontal",
				layout_config = {
					horizontal = { prompt_position = "top", preview_width = 0.6 },
					vertical = { prompt_position = "top", preview_height = 0.6 },
				},
				sorting_strategy = "ascending",
				path_display = { "truncate" },
				file_ignore_patterns = {
					"%.git/",
					"node_modules/",
					"__pycache__/",
					"%.tmp",
					"dist/",
					"build/",
					"%.min%.js",
					"%.min%.css",
					"package%-lock.json",
					"yarn.lock",
				},
				mappings = {
					i = {
						["<C-j>"] = actions.move_selection_next,
						["<C-k>"] = actions.move_selection_previous,
						["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
						["<C-y>"] = copy,
						["<C-s>"] = function(bufnr)
							split_open(bufnr, "split")
						end,
						["<C-v>"] = function(bufnr)
							split_open(bufnr, "vsplit")
						end,
						["<C-t>"] = actions.select_tab,
						["<C-f>"] = actions.preview_scrolling_down,
						["<C-b>"] = actions.preview_scrolling_up,
						["<C-/>"] = actions.which_key,
					},
					n = {
						["q"] = actions.close,
						["<esc>"] = actions.close,
						["<C-d>"] = actions.delete_buffer,
						["<C-y>"] = copy,
						["<C-s>"] = function(bufnr)
							split_open(bufnr, "split")
						end,
						["<C-v>"] = function(bufnr)
							split_open(bufnr, "vsplit")
						end,
					},
				},
			},
		}))

		-- Load extensions
		for _, ext in ipairs { "fzf", "ui-select" } do
			pcall(telescope.load_extension, ext)
		end
	end,
}
