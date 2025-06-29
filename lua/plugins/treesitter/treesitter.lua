return {
  "nvim-treesitter/nvim-treesitter",
  event = { "BufReadPost", "BufNewFile" },
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup {
      ensure_installed = {
        "vim", "vimdoc","c", "cpp", "lua", "python", 
        "bash","markdown", "markdown_inline",
      },
      auto_install = true,
      highlight = {
        enable = true,
        disable = function(lang, buf)
          local black = { rust = true }
          if black[lang] then return true end
          local max = 100 * 1024
          local ok, s = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
          return ok and s and s.size > max
        end,
      },
      incremental_selection = { enable = true },
      indent = { enable = true },
    }
  end,
}
