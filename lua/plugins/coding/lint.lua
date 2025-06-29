return {
  {
    "rshkarin/mason-nvim-lint",
    event = "BufReadPre",
    dependencies = {
      "mason-org/mason.nvim",
      "mfussenegger/nvim-lint",
    },
    opts = {
      automatic_installation = true,

    },
  },

  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPre", "BufWritePost" },
    config = function()
      local lint_utils = require("utils.lint")
      lint_utils.setup_linters()

      vim.api.nvim_create_autocmd(
        { "BufWritePost", "InsertLeave", "TextChanged" },
        {
          callback = function()
            vim.defer_fn(lint_utils.trigger, 100)
          end,
        }
      )

      vim.keymap.set("n", "<leader>ll", lint_utils.trigger,
        { desc = "Run linters (nvim-lint)" })
    end,
  },
}
