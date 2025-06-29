local M = {}

M.setup = function()
  vim.opt.wrap = true
  vim.opt.linebreak = true

  vim.keymap.set('n', 'j', function()
    return vim.v.count == 0 and 'gj' or 'j'
  end, {
    expr = true,
    desc = 'Move down (visual lines in wrap mode)'
  })

  vim.keymap.set('n', 'k', function()
    return vim.v.count == 0 and 'gk' or 'k'
  end, {
    expr = true,
    desc = 'Move up (visual lines in wrap mode)'
  })

end

M.setup()

return M
