return {
  {
    "echasnovski/mini.move",
    event = "VeryLazy",
    version = false,
    keys = {
      { "<M-h>", mode = { "n", "v" }, desc = "Move Left" },
      { "<M-l>", mode = { "n", "v" }, desc = "Move Right" },
      { "<M-j>", mode = { "n", "v" }, desc = "Move Down" },
      { "<M-k>", mode = { "n", "v" }, desc = "Move Up" },
    },
    config = function()
      require("mini.move").setup()
    end,
  }
}
