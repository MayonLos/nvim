local M = {}

---在浮窗中打开终端并执行 `cmd`
---@param cmd  string
---@param opts? table {width,height}
function M.open_floating_terminal(cmd, opts)
  opts   = opts or {}
  local W = vim.o.columns
  local H = vim.o.lines
  local width  = opts.width  or math.min(120, math.floor(W * 0.8))
  local height = opts.height or math.min(20,  math.floor(H * 0.4))

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style    = "minimal",
    border   = "rounded",
    width    = width,
    height   = height,
    col      = math.floor((W - width)  / 2),
    row      = math.floor((H - height) / 2),
  })

  -- q / <Esc> 关闭浮窗
  for _, key in ipairs({ "q", "<Esc>" }) do
    vim.keymap.set({ "n", "t" }, key, function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
    end, { buffer = buf, nowait = true })
  end

  vim.fn.termopen(cmd, {
    on_exit = function(_, code)
      if code ~= 0 then
        vim.schedule(function()
          vim.notify(("Process exited with code %d"):format(code), vim.log.levels.ERROR)
        end)
      end
    end,
  })

  vim.cmd.startinsert()
end

return M

