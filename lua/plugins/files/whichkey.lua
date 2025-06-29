return {
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    keys = { "<leader>" },
    config = function()
      local wk = require("which-key")
      wk.setup({})
      wk.add({
        { "<leader>f", group = "file" },
        { "<leader>s", group = "session/split" },
        { "<leader>g", group = "git" },
        { "<leader>l", group = "lsp" },
        { "<leader>x", group = "diagnostics" },
        { "<leader>m", group = "markdown" },
        { "<leader>a", group = "AI" },
        { "<leader>t", group = "terminal" }
      })
    end
  }
}
