local o = vim.opt

-- ============================================================================
-- UI 外观
-- ============================================================================
o.termguicolors = true
o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = "yes"
o.showmode = false
o.laststatus = 3
o.cmdheight = 1
o.pumheight = 15

-- ============================================================================
-- 窗口与滚动
-- ============================================================================
o.scrolloff = 8
o.sidescrolloff = 8
o.splitright = true
o.splitbelow = true
o.mouse = "a"

-- ============================================================================
-- 编辑与缩进
-- ============================================================================
o.expandtab = true
o.tabstop = 4
o.shiftwidth = 4
o.smartindent = true
o.breakindent = true
o.backspace = { "indent", "eol", "start" }
o.virtualedit = "block" -- 在可视块模式下允许光标移动到没有文本的地方

-- ============================================================================
-- 搜索
-- ============================================================================
o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.hlsearch = false

-- ============================================================================
-- 性能优化
-- ============================================================================
o.updatetime = 250
o.timeoutlen = 400
o.ttimeoutlen = 10
o.redrawtime = 1500
o.synmaxcol = 300

-- ============================================================================
-- 文件处理
-- ============================================================================
o.swapfile = false
o.backup = false
o.writebackup = false
o.fileencodings = "ucs-bom,utf-8,gb18030,gbk,gb2312,latin1"
o.confirm = true
o.autoread = true -- 文件在外部修改时自动重新读取

-- Undo 持久化
local undodir = vim.fn.stdpath("state") .. "/undo"
if vim.fn.isdirectory(undodir) == 0 then
    vim.fn.mkdir(undodir, "p")
end
o.undodir = undodir
o.undofile = true
o.undolevels = 10000

-- ============================================================================
-- 补全与消息
-- ============================================================================
o.completeopt = { "menu", "menuone", "noselect" }
o.shortmess:append("WIcCsF")

-- ============================================================================
-- 剪贴板（延迟加载，避免启动阻塞）
-- ============================================================================
vim.schedule(function()
    if vim.fn.executable("xclip") == 1 then
        o.clipboard = "unnamedplus"
    end
end)

-- ============================================================================
-- 折叠（可选，使用 treesitter 折叠）
-- ============================================================================
o.foldmethod = "expr"
o.foldexpr = "nvim_treesitter#foldexpr()"
o.foldenable = false -- 启动时不折叠
o.foldlevel = 99

-- ============================================================================
-- 其他优化
-- ============================================================================
o.wrap = false -- 不自动换行
o.linebreak = true -- 如果开启 wrap，在合适的位置断行
o.list = true -- 显示不可见字符
o.listchars = { tab = "→ ", trail = "·", nbsp = "␣" }
o.fillchars = { eob = " " } -- 隐藏缓冲区末尾的 ~
