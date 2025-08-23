local o, fn = vim.opt, vim.fn

-- ── UI ────────────────────────────────────────────────────────────────────────
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

vim.o.winborder = "rounded"

-- ── Indent ───────────────────────────────────────────────────────────────────
o.expandtab = true
o.tabstop = 4
o.shiftwidth = 4
o.smartindent = true

-- ── Search ───────────────────────────────────────────────────────────────────
o.ignorecase = true
o.smartcase = true
o.incsearch = true
o.hlsearch = true

-- ── Files / Undo ─────────────────────────────────────────────────────────────
o.confirm = true
o.clipboard = "unnamedplus"
local undodir = (vim.fn.has "nvim-0.10" == 1 and fn.stdpath "state" or fn.stdpath "data") .. "/undo"
if fn.isdirectory(undodir) == 0 then
	fn.mkdir(undodir, "p")
end
o.undodir = undodir
o.undofile = true

-- ── Encoding ─────────────────────────────────────────────────────────────────
o.fileencodings = { "ucs-bom", "utf-8", "gb18030", "gbk", "gb2312", "latin1" }

-- ── Folding（Tree-sitter）────────────────────────────────────────────────────
o.foldmethod = "expr"
o.foldexpr = "v:lua.vim.treesitter.foldexpr()"
o.foldenable = true
o.foldlevel = 99
o.foldlevelstart = 99
o.foldminlines = 3
o.foldnestmax = 10
o.foldtext = ""

-- ── Fillchars ────────────────────────────────────────────────────────────────
o.fillchars = {
	fold = "·",
	eob = " ",
}

-- ── Performance / Behavior ───────────────────────────────────────────────────
o.updatetime = 250
o.timeoutlen = 300
o.completeopt = { "menu", "menuone", "noselect" }
o.shortmess:append { W = true, I = true, c = true, C = true, s = true }
o.backspace = { "indent", "eol", "start" }
