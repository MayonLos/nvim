
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  event   = "VeryLazy",
  opts    = {
    size            = 15,
    direction       = "horizontal",
    hide_numbers    = true,
    shade_terminals = false,
    start_in_insert = true,
    auto_scroll     = true,
    float_opts      = { border = "rounded" },
  },

  config = function(_, opts)
    require("toggleterm").setup(opts)

    local Term = require("toggleterm.terminal").Terminal
    local float   = Term:new({ hidden = true, direction = "float" })
    local vert    = Term:new({ hidden = true, direction = "vertical",   size = 40 })
    local split   = Term:new({ hidden = true, direction = "horizontal", size = 15 })
    local lazygit = Term:new({ cmd = "lazygit", hidden = true, direction = "float" })

    local map, kopt = vim.keymap.set, { noremap = true, silent = true }
    map({ "n", "t" }, "<leader>tf", function() float:toggle()   end, vim.tbl_extend("force", kopt, { desc = "Terminal Float"     }))
    map({ "n", "t" }, "<leader>tv", function() vert:toggle()    end, vim.tbl_extend("force", kopt, { desc = "Terminal Vertical"  }))
    map({ "n", "t" }, "<leader>tt", function() split:toggle()   end, vim.tbl_extend("force", kopt, { desc = "Terminal Split"     }))
    map({ "n", "t" }, "<leader>tg", function() lazygit:toggle() end, vim.tbl_extend("force", kopt, { desc = "Terminal Lazygit"   }))

    local function term_keys()
      local o = { buffer = 0 }
      vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], o)
      vim.keymap.set("t", "jk",   [[<C-\><C-n>]], o)
    end
    vim.api.nvim_create_autocmd("TermOpen", { pattern = "term://*", callback = term_keys })
  end,
}

