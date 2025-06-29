
return {
  {
    "stevearc/dressing.nvim",
    lazy = true,
    dependencies = {
      "nvim-telescope/telescope.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
    },
    init = function()
      vim.ui.select = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.select(...)
      end
      vim.ui.input = function(...)
        require("lazy").load({ plugins = { "dressing.nvim" } })
        return vim.ui.input(...)
      end
    end,
    opts = function()
      local dropdown = require("telescope.themes").get_dropdown
      return {
        input = {
          enabled = true,
          border = "rounded",
          prefer_width = 40,
          win_options = { winblend = 0 },
        },
        select = {
          enabled = true,
          backend = { "telescope", "builtin" },
          telescope = dropdown({
            previewer = false,
            prompt_title = false,
          }),
        },
      }
    end,
  },
}

