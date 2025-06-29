local M = {}

-- 通用警告 & 调试标志
local common_flags = { "-g", "-Wall" }

---@param dst table  @目标表
---@param src table  @源表
local function extend(dst, src)
  for _, v in ipairs(src) do dst[#dst + 1] = v end
  return dst
end

---@param file table @{ dir, name, ext, base }
---@param std  string @C/C++ 标准
local function make_args(file, std)
  return extend(
    { file.name, "-std=" .. std },
    extend(vim.deepcopy(common_flags), { "-lm", "-o", file.base })
  )
end

M.runners = {
  c = {
    cmd  = "gcc",
    args = function(file) return make_args(file, "c17") end,
    run  = function(file) return "./" .. file.base end,
  },

  cpp = {
    cmd  = "g++",
    args = function(file) return make_args(file, "c++23") end,
    run  = function(file) return "./" .. file.base end,
  },

  py = {
    cmd  = "python3",
    args = function(file) return { file.name } end, -- termopen 自动执行
  },
}

return M

