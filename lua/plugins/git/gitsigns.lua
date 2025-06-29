return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },

  opts = {
    signs = { add = { text = "┃" }, change = { text = "┃" }, delete = { text = "_" },
              topdelete = { text = "‾" }, changedelete = { text = "~" }, untracked = { text = "┆" } },
    current_line_blame = false,
    signcolumn = true,
    on_attach = function(bufnr)
      local gs  = package.loaded.gitsigns
      local map = function(mode, lhs, rhs, desc)
        vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "GitSigns: " .. desc })
      end

      map("n", "]h", gs.next_hunk,  "Next hunk")
      map("n", "[h", gs.prev_hunk,  "Prev hunk")

      map({ "n", "v" }, "<leader>ghs", ":Gitsigns stage_hunk<CR>",  "Stage hunk")
      map({ "n", "v" }, "<leader>ghr", ":Gitsigns reset_hunk<CR>",  "Reset hunk")
      map("n",          "<leader>ghp", gs.preview_hunk,              "Preview hunk")
      map("n",          "<leader>ghb", function() gs.blame_line { full = true } end, "Blame line (full)")
      map("n",          "<leader>ghd", gs.diffthis,                  "Diff this file")
      map("n",          "<leader>ghD", function() gs.diffthis("~") end, "Diff vs ~")

      map("n", "<leader>gS", gs.stage_buffer,  "Stage buffer")
      map("n", "<leader>gR", gs.reset_buffer,  "Reset buffer")

      map("n", "<leader>gtb", gs.toggle_current_line_blame, "Toggle line blame")
      map("n", "<leader>gtw", gs.toggle_word_diff,          "Toggle word diff")

      map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Select hunk")
    end,
  },
}

