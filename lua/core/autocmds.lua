local function setup_autocommands()
  -- Autosave
  vim.api.nvim_create_autocmd({ "InsertLeave", "TextChanged", "FocusLost" }, {
    pattern = "*",
    callback = function()
      if vim.bo.modified and vim.bo.modifiable and not vim.bo.buftype:match("^(nofile|terminal|prompt)$") then
        pcall(vim.cmd.write)
      end
    end,
    desc = "Autosave on buffer changes"
  })

  -- Yank highlight

  vim.api.nvim_create_autocmd("TextYankPost", {
    group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
    callback = function()
      vim.hl.on_yank({
        higroup = "IncSearch",
        timeout = 300,
        on_visual = true,
      })
    end,
    desc = "Highlight yanked text",
  })
end
setup_autocommands()
