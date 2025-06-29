return {
  "mbbill/undotree",
  cmd = "UndotreeToggle",
  keys = {
    {
      "<leader>u",
      "<cmd>UndotreeToggle<CR>",
      desc = "Toggle UndoTree"
    },
  },
  init = function()
    vim.g.undotree_WindowLayout = 2
    vim.g.undotree_SplitWidth = 40
    vim.g.undotree_SetFocusWhenToggle = 1
    vim.g.undotree_DiffpanelHeight = 8
  end,
}
