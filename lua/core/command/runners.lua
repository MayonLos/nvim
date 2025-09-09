---@class CodeRunner
-- This file provides backwards compatibility while using the new optimized modular system
local M = require("core.command.runners.init")

-- Re-export for any external code that might access these directly
-- All functionality is now handled by the optimized modules

return M
