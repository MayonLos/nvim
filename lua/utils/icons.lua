local M = {}

local mi
local function ensure_setup()
  if mi then return end
  mi = require("mini.icons")
  mi.setup()
end

function M.get(category, name, fallback)
  ensure_setup()
  local ok, icon = pcall(mi.get, category, name)
  return ok and icon or fallback
end

function M.apply_diagnostic_signs()
  ensure_setup()
  vim.diagnostic.config({
    signs = {
      text = {
        [vim.diagnostic.severity.ERROR] = M.get("diagnostics", "Error", ""),
        [vim.diagnostic.severity.WARN]  = M.get("diagnostics", "Warn",  ""),
        [vim.diagnostic.severity.INFO]  = M.get("diagnostics", "Info",  ""),
        [vim.diagnostic.severity.HINT]  = M.get("diagnostics", "Hint",  ""),
      },
    },
  })
end

return M
