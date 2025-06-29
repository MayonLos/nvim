return {
 {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        integrations = {
          cmp        = true,
          telescope  = true,
          notify     = true,
          noice      = true,
          which_key  = true,
          mini       = true,
        },
      })
      -- 启动自动读取主题
      local theme_file = vim.fn.stdpath("config") .. "/lua/user/last_theme.lua"
      local ok, saved = pcall(dofile, theme_file)
      local colorscheme = ok and type(saved) == "string" and #saved > 0 and saved or "catppuccin-frappe"
      -- 用 schedule 避免 lazy.nvim 抢先设置无效
      vim.schedule(function()
        pcall(vim.cmd.colorscheme, colorscheme)
      end)
    end,
  },
}
