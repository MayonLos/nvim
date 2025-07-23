-- Core Settings for Neovim

local opt = vim.opt
local o = vim.o
local fn = vim.fn

-- Visual & UI
opt.termguicolors = true -- Enable true color support
opt.number = true -- Show line numbers
opt.relativenumber = true -- Show relative line numbers

-- Indentation
opt.expandtab = true -- Convert tabs to spaces
opt.tabstop = 4 -- Tab width
opt.shiftwidth = 4 -- Indent width
opt.softtabstop = 4 -- Soft tab width
opt.smartindent = true -- Smart auto-indenting
opt.autoindent = true -- Copy indent from current line

-- Search
opt.ignorecase = true -- Case insensitive search
opt.smartcase = true -- Override ignorecase if uppercase present
opt.hlsearch = true -- Highlight search results
opt.incsearch = true -- Incremental search

-- File handling
opt.confirm = true -- Confirm before exit with unsaved changes
opt.clipboard = "unnamedplus" -- Use system clipboard
opt.undofile = true -- Persistent undo
opt.undodir = fn.stdpath "data" .. "/undo"
opt.undolevels = 10000 -- Max undo changes
opt.undoreload = 10000 -- Max lines for undo reload

-- File navigation
opt.path:append "**" -- Recursive file search
opt.suffixesadd:append ".lua" -- Auto add .lua extension for gf

-- Encoding
opt.fileencodings = {
	"utf-8",
	"gb18030",
	"gbk",
	"cp936",
	"big5",
	"shiftjis",
	"latin1",
}
opt.encoding = "utf-8"

-- Advanced Code Folding
o.foldmethod = "expr" -- Expression-based folding
o.foldexpr = "nvim_treesitter#foldexpr()" -- Tree-sitter syntax folding
o.foldenable = true -- Enable folding globally
o.foldlevel = 99 -- Start with all folds open
o.foldlevelstart = 99 -- Initial fold level for new files
o.foldminlines = 3 -- Minimum lines required for folding
o.foldnestmax = 10 -- Maximum fold nesting depth
o.foldtext = "" -- Clean fold text display

-- Enhanced folding appearance
opt.fillchars = {
	fold = "·", -- Subtle fill character
	eob = " ", -- End of buffer
}

-- Performance & Behavior
opt.updatetime = 250 -- Faster updates
opt.timeoutlen = 300 -- Key sequence timeout
opt.splitright = true -- Vertical splits to right
opt.splitbelow = true -- Horizontal splits below
opt.cursorline = true -- Highlight current line
opt.scrolloff = 8 -- Keep lines visible above/below cursor
opt.sidescrolloff = 8 -- Keep columns visible left/right
opt.mouse = "a" -- Mouse support
opt.showmode = false -- Hide mode (shown in statusline)
opt.showcmd = true -- Show incomplete commands
opt.wildmenu = true -- Enhanced command completion
opt.completeopt = { "menu", "menuone", "noselect" }
opt.backspace = { "indent", "eol", "start" }
opt.showmatch = true -- Show matching brackets
opt.matchtime = 2 -- Bracket match time
