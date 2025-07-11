return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		signs = {
			add = { text = "▎" },
			change = { text = "▎" },
			delete = { text = "▁" },
			topdelete = { text = "▔" },
			changedelete = { text = "▒" },
			untracked = { text = "┆" },
		},
		signcolumn = true,
		numhl = true,
		watch_gitdir = { interval = 1000 },
		attach_to_untracked = true,
		max_file_length = 10000,
		update_debounce = 150,

		on_attach = function(bufnr)
			local gs = package.loaded.gitsigns
			local map = function(mode, lhs, rhs, desc)
				vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "Git: " .. desc })
			end

			map("n", "<leader>gn", gs.next_hunk, "Next Hunk")
			map("n", "<leader>gp", gs.prev_hunk, "Prev Hunk")
			map({ "n", "v" }, "<leader>gs", gs.stage_hunk, "Stage Hunk")
			map({ "n", "v" }, "<leader>gr", gs.reset_hunk, "Reset Hunk")
			map("n", "<leader>gu", gs.undo_stage_hunk, "Undo Stage")
			map("n", "<leader>gb", gs.toggle_current_line_blame, "Toggle Blame")
			map("n", "<leader>gd", gs.preview_hunk, "Preview Hunk")
		end,
	},
}
