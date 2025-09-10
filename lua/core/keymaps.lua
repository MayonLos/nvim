local M = {}

function M.setup()
	local map = vim.keymap.set
	local function k(mode, lhs, rhs, desc, extra)
		local o =
			vim.tbl_extend("force", { silent = true, noremap = true, desc = desc }, extra or {})
		map(mode, lhs, rhs, o)
	end

	-- Basic
	k("n", "<C-s>", "<cmd>w<cr>", "Save")
	k("i", "<C-s>", "<Esc><cmd>w<cr>a", "Save (insert)")
	k("n", "<leader>h", "<cmd>nohlsearch<cr>", "Clear search highlight")

	-- Window navigation
	k("n", "<C-h>", "<C-w>h", "Focus left")
	k("n", "<C-j>", "<C-w>j", "Focus down")
	k("n", "<C-k>", "<C-w>k", "Focus up")
	k("n", "<C-l>", "<C-w>l", "Focus right")

	-- Split/Window
	k("n", "<leader>wh", "<cmd>split<cr>", "Split horizontal")
	k("n", "<leader>wv", "<cmd>vsplit<cr>", "Split vertical")
	k("n", "<leader>w=", "<C-w>=", "Equalize windows")

	-- ====== Window resize: temporary mode (<leader>wr to enter/exit) ======
	local resize_mode = { active = false, mapped = {} }

	local function delta_str(n)
		return (n >= 0) and ("+" .. n) or ("-" .. -n)
	end
	local function resize_h(step)
		local n = (vim.v.count1 or 1) * step
		vim.cmd("resize " .. delta_str(n))
	end
	local function resize_w(step)
		local n = (vim.v.count1 or 1) * step
		vim.cmd("vertical resize " .. delta_str(n))
	end
	local function unmap_resize_keys()
		for _, lhs in ipairs(resize_mode.mapped) do
			pcall(vim.keymap.del, "n", lhs)
		end
		resize_mode.mapped = {}
		resize_mode.active = false
		vim.notify("Resize mode OFF", vim.log.levels.INFO, { title = "Windows" })
	end

	local function toggle_resize_mode()
		if resize_mode.active then
			return unmap_resize_keys()
		end
		resize_mode.active = true

		local function tm(lhs, fn, desc)
			vim.keymap.set(
				"n",
				lhs,
				fn,
				{ silent = true, noremap = true, nowait = true, desc = "[Resize] " .. desc }
			)
			table.insert(resize_mode.mapped, lhs)
		end

		tm("h", function()
			resize_w(-3)
		end, "Width -")
		tm("l", function()
			resize_w(3)
		end, "Width +")
		tm("j", function()
			resize_h(-2)
		end, "Height -")
		tm("k", function()
			resize_h(2)
		end, "Height +")
		tm("_", function()
			vim.cmd("wincmd _")
		end, "Max height")
		tm("|", function()
			vim.cmd("wincmd |")
		end, "Max width")
		tm("=", function()
			vim.cmd("wincmd =")
		end, "Equalize")
		tm("q", unmap_resize_keys, "Quit")
		tm("<Esc>", unmap_resize_keys, "Quit")

		vim.notify(
			"Resize mode: h/l width -/+ · j/k height -/+ · _/| maximize · = equalize · q/Esc quit (supports numeric prefix)",
			vim.log.levels.INFO,
			{ title = "Windows" }
		)
	end

	k("n", "<leader>wr", toggle_resize_mode, "Resize mode (toggle)")

	-- Terminal
	k("t", "<Esc>", [[<C-\><C-n>]], "Terminal → normal")
end

return M
