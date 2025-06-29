local M = {}
function M.get_file_info()

local file = {
    path = vim.fn.expand("%:p"),
    name = vim.fn.expand("%:t"),
    base = vim.fn.expand("%:t:r"),
    ext = vim.fn.expand("%:e"):lower(),
    dir = vim.fn.expand("%:p:h"),
}

return file
end

return M
