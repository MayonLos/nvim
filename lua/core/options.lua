local o, fn = vim.opt, vim.fn
o.termguicolors = true
o.number = true
o.relativenumber = true
o.cursorline = true
o.signcolumn = "yes"
o.scrolloff = 8
o.sidescrolloff = 8
o.showmode = false
o.splitright = true
o.splitbelow = true
o.mouse = "a"
o.winborder = "rounded"
o.laststatus = 3
o.cmdheight = 1
o.redrawtime = 300
o.ttimeoutlen = 10
o.expandtab = true
o.tabstop = 4
o.shiftwidth = 4
o.smartindent = true
o.breakindent = true
o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.hlsearch = false
o.confirm = true
o.clipboard = "unnamedplus"
o.swapfile = false
o.backup = false
local undodir = (vim.fn.has("nvim-0.10") == 1 and fn.stdpath("state") or fn.stdpath("data"))
	.. "/undo"
if fn.isdirectory(undodir) == 0 then
	fn.mkdir(undodir, "p")
end
o.undodir = undodir
o.undofile = true
o.fileencodings = { "ucs-bom", "utf-8", "gb18030", "gbk", "gb2312", "latin1" }
o.updatetime = 250
o.timeoutlen = 500
o.completeopt = { "menu", "menuone", "noselect" }
o.shortmess:append("WIcCsF")
o.backspace = { "indent", "eol", "start" }
o.ttyfast = true
o.lazyredraw = false
o.synmaxcol = 500
