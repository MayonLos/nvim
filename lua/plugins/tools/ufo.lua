return {
	"kevinhwang91/nvim-ufo",
	event = "VeryLazy",
	dependencies = { "kevinhwang91/promise-async" },

	init = function()
		vim.o.foldcolumn = "1"
		vim.o.foldlevel = 99
		vim.o.foldlevelstart = 99
		vim.o.foldenable = true

		local cur = vim.opt.fillchars:get()
		vim.opt.fillchars = vim.tbl_extend("force", cur, {
			foldopen = "",
			foldclose = "",
			fold = " ",
			foldsep = " ",
			eob = " ",
		})

		_G.UfoFoldIcon = function()
			local l = vim.v.lnum
			if vim.fn.foldclosed(l) ~= -1 then
				return ""
			end
			if vim.fn.foldlevel(l) > vim.fn.foldlevel(l - 1) then
				return ""
			end
			return " "
		end

		local function set_statuscolumn_for_current_win()
			local bt = vim.bo.buftype
			local ft = vim.bo.filetype
			local ui_ft = {
				alpha = true,
				dashboard = true,
				lazy = true,
				mason = true,
				["neo-tree"] = true,
				NvimTree = true,
				TelescopePrompt = true,
				help = true,
				man = true,
				qf = true,
				oil = true,
				Outline = true,
			}
			local is_ui = bt == "nofile"
				or bt == "terminal"
				or bt == "prompt"
				or bt == "quickfix"
				or ui_ft[ft]

			if is_ui then
				vim.opt_local.statuscolumn = ""
				vim.opt_local.number = false
				vim.opt_local.relativenumber = false
				vim.opt_local.signcolumn = "no"
				vim.opt_local.foldcolumn = "0"
			else
				local sc = table.concat({
					"%s",
					"%{%v:lua.UfoFoldIcon()%}",
					"%=%{v:relnum?v:relnum:v:lnum}",
					" ",
				})
				vim.opt_local.statuscolumn = sc
				vim.opt_local.signcolumn = "auto"
			end
		end

		local grp = vim.api.nvim_create_augroup("UfoStatuscolumnPerWin", { clear = true })
		vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "WinNew", "TermOpen" }, {
			group = grp,
			callback = set_statuscolumn_for_current_win,
		})
		vim.api.nvim_create_autocmd("ColorScheme", {
			group = grp,
			callback = function()
				vim.api.nvim_set_hl(0, "UfoColSep", { link = "WinSeparator" })
			end,
		})
	end,

	opts = {
		open_fold_hl_timeout = 150,
		preview = {
			win_config = { border = "rounded", winblend = 12, maxheight = 20 },
		},
		fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
			local newVirtText, curWidth = {}, 0
			local suffix = (" 󰁂 %d "):format(endLnum - lnum)
			local sufWidth = vim.fn.strdisplaywidth(suffix)
			local targetWidth = width - sufWidth
			for _, chunk in ipairs(virtText) do
				local text, hl = chunk[1], chunk[2]
				local w = vim.fn.strdisplaywidth(text)
				if targetWidth > curWidth + w then
					table.insert(newVirtText, { text, hl })
				else
					text = truncate(text, targetWidth - curWidth)
					table.insert(newVirtText, { text, hl })
					w = vim.fn.strdisplaywidth(text)
					if curWidth + w < targetWidth then
						suffix = suffix .. string.rep(" ", targetWidth - curWidth - w)
					end
					break
				end
				curWidth = curWidth + w
			end
			table.insert(newVirtText, { suffix, "Comment" })
			return newVirtText
		end,

		provider_selector = function(_, filetype, _)
			local prefer_ts = {
				lua = true,
				vim = true,
				vimdoc = true,
				markdown = true,
				python = true,
				json = true,
				yaml = true,
				toml = true,
				html = true,
				c = true,
				cpp = true,
			}
			if prefer_ts[filetype] then
				return { "treesitter", "indent" }
			end
			return { "lsp", "indent" }
		end,
	},

	config = function(_, opts)
		local ok, ufo = pcall(require, "ufo")
		if not ok then
			return
		end

		local grp = vim.api.nvim_create_augroup("UfoBlacklist", { clear = true })
		vim.api.nvim_create_autocmd("FileType", {
			group = grp,
			pattern = {
				"alpha",
				"dashboard",
				"help",
				"man",
				"gitcommit",
				"gitrebase",
				"neo-tree",
				"NvimTree",
				"lazy",
				"mason",
				"TelescopePrompt",
				"qf",
				"oil",
				"Outline",
			},
			callback = function()
				vim.b.ufo_disable = true
			end,
		})
		vim.api.nvim_create_autocmd("BufWinEnter", {
			group = grp,
			callback = function(args)
				local bt = vim.bo[args.buf].buftype
				if bt == "nofile" or bt == "terminal" or bt == "prompt" or bt == "quickfix" then
					vim.b[args.buf].ufo_disable = true
				end
			end,
		})

		ufo.setup(opts)

		vim.keymap.set("n", "zR", ufo.openAllFolds, { desc = "UFO: Open all folds" })
		vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "UFO: Close all folds" })
		vim.keymap.set("n", "zp", function()
			pcall(ufo.peekFoldedLinesUnderCursor)
		end, { desc = "UFO: Peek folded lines" })
		vim.keymap.set("n", "zr", function()
			ufo.openFoldsExceptKinds({ "comment", "imports" })
		end, { desc = "UFO: Open folds except comment/imports" })
		vim.keymap.set("n", "zm", function()
			ufo.closeFoldsWith(1)
		end, { desc = "UFO: Close one fold level" })
	end,
}
