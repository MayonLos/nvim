return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		-- Minimal yet distinct sign symbols
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "▁" },
			topdelete = { text = "▔" },
			changedelete = { text = "▒" },
			untracked = { text = "┆" },
		},

		-- Enhanced functionality
		signcolumn = true, -- Always show sign column
		numhl = true, -- Highlight line numbers
		linehl = false, -- Don't highlight entire line
		word_diff = false, -- Disable word diff by default

		watch_gitdir = {
			interval = 1000, -- Faster git dir updates
			follow_files = true,
		},
		attach_to_untracked = true, -- Show signs for untracked files
		current_line_blame = false, -- Disable blame by default
		current_line_blame_opts = {
			virt_text = true,
			virt_text_pos = "right_align",
			delay = 500,
			ignore_whitespace = true,
		},
		max_file_length = 10000, -- Better performance for large files
		update_debounce = 150, -- More responsive updates

		-- Key mappings
		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns
			local function map(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "Git: " .. desc })
			end

			-- Navigation
			map("n", "]h", gs.next_hunk, "Next hunk")
			map("n", "[h", gs.prev_hunk, "Previous hunk")

			-- Hunk operations
			map({ "n", "v" }, "<leader>ghs", gs.stage_hunk, "Stage hunk")
			map({ "n", "v" }, "<leader>ghr", gs.reset_hunk, "Reset hunk")
			map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo stage hunk")
			map("n", "<leader>ghp", gs.preview_hunk, "Preview hunk")

			-- File operations
			map("n", "<leader>gS", gs.stage_buffer, "Stage buffer")
			map("n", "<leader>gR", gs.reset_buffer, "Reset buffer")

			-- Diff operations
			map("n", "<leader>gtd", gs.toggle_deleted, "Toggle deleted lines")
			map("n", "<leader>gdd", gs.diffthis, "Diff against index")
			map("n", "<leader>gdc", function()
				gs.diffthis("HEAD")
			end, "Diff against HEAD")
			map("n", "<leader>gdD", function()
				gs.diffthis("~")
			end, "Diff against last commit")

			-- Blame and history
			map("n", "<leader>gbb", gs.toggle_current_line_blame, "Toggle line blame")
			map("n", "<leader>gbB", function()
				gs.blame_line({ full = true })
			end, "Show full blame")
			map("n", "<leader>ghh", gs.select_hunk, "Select current hunk")

			-- Advanced features
			map("n", "<leader>gqf", gs.setqflist, "Open hunks in quickfix")
			map("n", "<leader>gql", function()
				gs.setloclist()
			end, "Open hunks in loclist")
			map("n", "<leader>gwd", gs.toggle_word_diff, "Toggle word diff")
			map("n", "<leader>gsc", gs.toggle_signs, "Toggle signs")

			-- Text object for hunks
			map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select hunk")
		end,
	},
}
