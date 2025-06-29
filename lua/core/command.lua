local M = {}

local runner = require("runner")

function M.setup()
  vim.api.nvim_create_user_command("RunCode",runner.run, { desc = "Run current file" })

end

return M
