local opt = vim.opt
local fn = vim.fn

-- UI
opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.signcolumn = "yes"

-- Indentation
opt.expandtab = true
opt.tabstop = 4
opt.shiftwidth = 4
opt.smartindent = true

-- Search
opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

-- File handling
opt.confirm = true
opt.clipboard = "unnamedplus"
opt.undofile = true
opt.undodir = fn.stdpath "data" .. "/undo"

-- Encoding
opt.encoding = "utf-8"
opt.fileencodings = { "utf-8", "gb18030", "gbk", "cp936", "big5", "shiftjis", "latin1" }

-- Folding (Tree-sitter)
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldenable = true
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldminlines = 3
opt.foldnestmax = 10
opt.foldtext = ""

-- Fillchars
opt.fillchars = { fold = "·", eob = " " }

-- Performance & behavior
opt.updatetime = 250
opt.timeoutlen = 300
opt.splitright = true
opt.splitbelow = true
opt.mouse = "a"
opt.showmode = false
opt.completeopt = { "menu", "menuone", "noselect" }
opt.backspace = { "indent", "eol", "start" }
