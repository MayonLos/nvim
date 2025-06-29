return {
  {
    'MeanderingProgrammer/render-markdown.nvim',
    ft = {"markdown", "llm"},
    dependencies = {
      'nvim-treesitter/nvim-treesitter',
      'echasnovski/mini.icons',
      "saghen/blink.cmp",
    },
    opts = {
      heading = { position = 'inline' },
      completions = { blink = { enabled = true } },
    },
  }
}
