--Core Settings
-- color
vim.opt.termguicolors = true
-- number
vim.opt.number = true
vim.opt.relativenumber = true
-- tap
vim.opt.expandtab = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.smartindent = true
-- case
vim.opt.ignorecase = true
vim.opt.smartcase = true
-- confirm when exit
vim.opt.confirm = true
-- clipboard
vim.opt.clipboard = "unnamedplus"
-- undo
vim.opt.undofile = true
vim.opt.undodir = vim.fn.stdpath("data") .. "/undo"
-- gf
vim.opt.path:append("**")
vim.opt.suffixesadd:append(".lua")
-- encoding
vim.opt.fileencodings = {
	"utf-8",
	"gb18030",
	"gbk",
	"cp936",
	"big5",
	"shiftjis",
	"latin1",
}
