return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
  config = function()
    local autopairs = require("nvim-autopairs")
    local Rule = require("nvim-autopairs.rule")

    autopairs.setup({
      check_ts = true,
      enable_check_bracket_line = false,
      disable_filetype = { "TelescopePrompt" },
    })

    autopairs.add_rules({
      Rule("`", "`", "markdown"):with_pair(function()
        return false
      end),
    })
  end,
}
