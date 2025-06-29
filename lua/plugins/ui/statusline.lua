return {
  "echasnovski/mini.statusline",
  version = false,
  event = "VeryLazy",
  config = function()
    local statusline = require("mini.statusline")

    statusline.setup({
      use_icons = true,
      set_vim_settings = false,
    })

    statusline.section_location = function()
      local line = vim.fn.line(".")
      local col  = vim.fn.virtcol(".")
      return string.format(" %d:%d", line, col)
    end

    statusline.section_filename = function()
      local name = vim.fn.expand("%:t")
      if name == "" then return "[No Name]" end
      local icon = require("mini.icons").get("file", name, { default = true }) or ""
      return string.format("%s %s", icon, name)
    end

    statusline.section_git = function()
      return vim.b.gitsigns_head and (" " .. vim.b.gitsigns_head) or ""
    end

    statusline.section_lsp = function()
      local clients = vim.lsp.get_clients({ bufnr = 0 })
      if vim.tbl_isempty(clients) then return "" end
      local names = vim.tbl_map(function(c) return c.name end, clients)
      return " " .. table.concat(names, ", ")
    end

    statusline.section_diagnostics = function()
      local e = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
      local w = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
      return (e > 0 or w > 0) and string.format(" %d  %d", e, w) or ""
    end

    statusline.section_c = function()
      return table.concat(vim.tbl_filter(function(s) return s ~= "" end, {
        statusline.section_filename(),
        statusline.section_git(),
        statusline.section_diagnostics(),
      }), " 󰇘 ")
    end

    statusline.section_x = function()
      return table.concat(vim.tbl_filter(function(s) return s ~= "" end, {
        statusline.section_lsp(),
        statusline.section_location(),
      }), " 󰇘 ")
    end
  end,
}

