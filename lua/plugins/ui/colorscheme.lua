return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        transparent_background = true,
        integrations = {
          cmp = true,
          telescope = true,
          notify = true,
          noice = true,
          which_key = true,
          mini = true,
        }
      })
      vim.cmd.colorscheme("catppuccin-frappe")
    end
  }
}
