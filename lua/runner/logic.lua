local utils   = require("utils.filepath")
local runners = require("runner.runners").runners
local ui      = require("runner.ui")

local M = {}

---@param list string[]
---@return string[]
local function shellescape_list(list)
  local esc = {}
  for _, v in ipairs(list) do
    esc[#esc + 1] = vim.fn.shellescape(v)
  end
  return esc
end

function M.compile_and_run()
  -- 自动保存当前缓冲区（忽略只读报错）
  if vim.bo.modified then pcall(vim.cmd.write) end

  local file   = utils.get_file_info()
  local runner = runners[file.ext]

  if not runner then
    vim.notify(("Unsupported file type: %s"):format(file.ext), vim.log.levels.ERROR)
    return
  end

  -- 编译命令
  local cmd_parts = {
    "cd",                     vim.fn.shellescape(file.dir),
    "&&",                     runner.cmd,
    unpack(shellescape_list(runner.args(file))),
  }

  -- 追加运行命令（如果定义）
  if runner.run then
    local run_cmd = type(runner.run) == "function" and runner.run(file) or runner.run
    cmd_parts[#cmd_parts + 1] = "&&"
    cmd_parts[#cmd_parts + 1] = run_cmd
  end

  ui.open_floating_terminal(table.concat(cmd_parts, " "))
end

return M

