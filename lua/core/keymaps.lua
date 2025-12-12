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

-- ============================================================================
-- Plugin keymaps (returned to lazy.nvim via require("core.keymaps").plugin)
-- ============================================================================

local function comment_toggles()
	local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)

	local function api()
		return require("Comment.api")
	end

	local function leave_visual_then(fn)
		vim.api.nvim_feedkeys(esc, "nx", false)
		fn()
	end

	return {
		{ "<C-/>", function()
			api().toggle.linewise.current()
		end, mode = "n", desc = "Toggle comment" },
		{ "<C-/>", function()
			leave_visual_then(function()
				api().toggle.linewise(vim.fn.visualmode())
			end)
		end, mode = "v", desc = "Toggle comment" },
		{ "<C-/>", function()
			leave_visual_then(function()
				api().toggle.linewise.current()
			end)
			vim.cmd("startinsert!")
		end, mode = "i", desc = "Toggle comment" },
		{ "<C-_>", function()
			api().toggle.linewise.current()
		end, mode = "n", desc = "Toggle comment" },
		{ "<C-_>", function()
			leave_visual_then(function()
				api().toggle.linewise(vim.fn.visualmode())
			end)
		end, mode = "v", desc = "Toggle comment" },
		{ "<C-_>", function()
			leave_visual_then(function()
				api().toggle.linewise.current()
			end)
			vim.cmd("startinsert!")
		end, mode = "i", desc = "Toggle comment" },
		{ "gc", mode = { "n", "v" }, desc = "Toggle comment (line)" },
		{ "gb", mode = { "n", "v" }, desc = "Toggle comment (block)" },
	}
end

local plugin_keys = {
	comment = comment_toggles,

	conform = {
		{
			"<leader>lf",
			function()
				require("conform").format({ async = true, lsp_fallback = true })
			end,
			mode = { "n", "v" },
			desc = "Format buffer",
		},
	},

	trouble = {
		{ "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics list" },
	},

	todo = {
		{ "<leader>ft", "<cmd>TodoFzfLua<CR>", desc = "TODOs: project (FzfLua)" },
		{
			"]t",
			function()
				require("todo-comments").jump_next()
			end,
			desc = "Next TODO comment",
		},
		{
			"[t",
			function()
				require("todo-comments").jump_prev()
			end,
			desc = "Previous TODO comment",
		},
	},

	dap = {
		{ "<F5>", function()
			require("dap").continue()
		end, desc = "DAP Continue" },
		{ "<S-F5>", function()
			require("dap").terminate()
		end, desc = "DAP Terminate" },
		{ "<F10>", function()
			require("dap").step_over()
		end, desc = "DAP Step Over" },
		{ "<F11>", function()
			require("dap").step_into()
		end, desc = "DAP Step Into" },
		{ "<S-F11>", function()
			require("dap").step_out()
		end, desc = "DAP Step Out" },
		{ "<leader>db", function()
			require("dap").toggle_breakpoint()
		end, desc = "DAP Toggle Breakpoint" },
		{ "<leader>dB", function()
			require("dap").set_breakpoint(vim.fn.input("Condition: "))
		end, desc = "DAP Conditional Breakpoint" },
		{ "<leader>dl", function()
			require("dap").set_breakpoint(nil, nil, vim.fn.input("Log: "))
		end, desc = "DAP Log Point" },
		{ "<leader>du", function()
			require("dapui").toggle({})
		end, desc = "DAP UI Toggle" },
		{ "<leader>dr", function()
			require("dap").repl.open()
		end, desc = "DAP REPL" },
		{ "<leader>de", function()
			require("dap.ui.widgets").hover()
		end, desc = "DAP Eval (Hover)" },
		{ "<leader>dE", function()
			local w = require("dap.ui.widgets")
			w.centered_float(w.scopes)
		end, desc = "DAP Scopes Float" },
		{ "<leader>dR", function()
			local dap = require("dap")
			dap.terminate()
			vim.defer_fn(function()
				dap.run_last()
			end, 200)
		end, desc = "DAP Restart" },
	},

	toggleterm = {
		{ "<leader>ac", "<cmd>CodexTerm<cr>", mode = { "n", "t" }, desc = "AI Codex" },
		{ "<C-\\>", "<cmd>ToggleTerm<cr>", mode = { "n", "t" }, desc = "Toggle Terminal" },
	},

	undotree = {
		{
			"<leader>u",
			"<cmd>UndotreeToggle<cr>",
			desc = "Toggle UndoTree",
		},
	},

	neotree = {
		{ "<leader>ee", "<cmd>Neotree toggle<cr>", desc = "Toggle explorer" },
		{ "<leader>ef", "<cmd>Neotree focus<cr>", desc = "Focus explorer" },
	},

	fzf = {
		{ "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find Files" },
		{ "<leader>fg", "<cmd>FzfLua live_grep<cr>", desc = "Live Grep" },
		{ "<leader>fb", "<cmd>FzfLua buffers<cr>", desc = "Buffers" },
		{ "<leader>fr", "<cmd>FzfLua oldfiles<cr>", desc = "Recent Files" },
		{ "<leader>fh", "<cmd>FzfLua helptags<cr>", desc = "Help" },
		{ "<leader>f.", "<cmd>FzfLua blines<cr>", desc = "Buffer Lines" },
	},

	ufo = {
		{ "zR", function()
			require("ufo").openAllFolds()
		end, desc = "UFO: Open all folds" },
		{ "zM", function()
			require("ufo").closeAllFolds()
		end, desc = "UFO: Close all folds" },
		{ "zp", function()
			pcall(require("ufo").peekFoldedLinesUnderCursor)
		end, desc = "UFO: Peek folded lines" },
		{ "zr", function()
			require("ufo").openFoldsExceptKinds({ "comment", "imports" })
		end, desc = "UFO: Open folds except comment/imports" },
		{ "zm", function()
			require("ufo").closeFoldsWith(1)
		end, desc = "UFO: Close one fold level" },
	},

	["treesitter-context"] = {
		{ "[x", function()
			require("treesitter-context").go_to_context(vim.v.count1)
		end, mode = "n", silent = true, desc = "Go to context" },
	},

	clangd_extensions = {
		{ "<leader>lh", "<cmd>ClangdSwitchSourceHeader<cr>", desc = "Clangd: Switch header/source" },
		{ "<leader>la", "<cmd>ClangdAST<cr>", desc = "Clangd: AST" },
		{ "<leader>ls", "<cmd>ClangdSymbolInfo<cr>", desc = "Clangd: Symbol info" },
		{ "<leader>lt", "<cmd>ClangdTypeHierarchy<cr>", desc = "Clangd: Type hierarchy" },
		{ "<leader>lm", "<cmd>ClangdMemoryUsage<cr>", desc = "Clangd: Memory usage" },
	},

	bufferline = function()
		local maps = {
			{ "<Tab>", "<cmd>BufferLineCycleNext<cr>", desc = "Next buffer" },
			{ "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev buffer" },
			{ "<leader>bp", "<cmd>BufferLineTogglePin<cr>", desc = "Pin/Unpin buffer" },
			{ "<leader>bP", "<cmd>BufferLineGroupClose ungrouped<cr>", desc = "Close unpinned buffers" },
			{ "<leader>br", "<cmd>BufferLineCloseRight<cr>", desc = "Close buffers to right" },
			{ "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", desc = "Close buffers to left" },
			{ "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", desc = "Close other buffers" },
			{ "<leader>bd", "<cmd>bdelete<cr>", desc = "Close buffer" },
			{ "<leader>bD", "<cmd>bdelete!<cr>", desc = "Force close buffer" },
			{ "<leader>bmh", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer left" },
			{ "<leader>bml", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer right" },
			{ "<leader>bs", "<cmd>BufferLinePick<cr>", desc = "Pick buffer" },
			{ "<leader>bsd", "<cmd>BufferLinePickClose<cr>", desc = "Pick buffer to close" },
			{ "<leader><leader>", "<cmd>buffer #<cr>", desc = "Toggle last buffer" },
			{ "<leader>be", "<cmd>BufferLineSortByExtension<cr>", desc = "Sort by extension" },
			{ "<leader>bd", "<cmd>BufferLineSortByDirectory<cr>", desc = "Sort by directory" },
		}

		for i = 1, 9 do
			table.insert(maps, {
				"<C-" .. i .. ">",
				function()
					require("bufferline").go_to(i, true)
				end,
				desc = "Switch to buffer " .. i,
			})
		end

		return maps
	end,
}

function M.plugin(name)
	local maps = plugin_keys[name]
	if not maps then
		return {}
	end
	if type(maps) == "function" then
		return maps()
	end
	return vim.deepcopy(maps)
end

-- ============================================================================
-- LSP buffer-local keymaps (used by lspconfig on_attach)
-- ============================================================================
function M.lsp(bufnr, opts)
	opts = opts or {}

	local function k(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, {
			buffer = bufnr,
			silent = true,
			noremap = true,
			desc = "LSP: " .. desc,
		})
	end

	-- Core navigation/actions
	k("n", "K", function()
		vim.lsp.buf.hover({ focusable = false, max_width = 80, max_height = 20 })
	end, "Hover")
	k("n", "gd", vim.lsp.buf.definition, "Go to Definition")
	k("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
	k("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
	k("n", "gr", vim.lsp.buf.references, "References")

	k({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
	k("n", "<leader>cr", vim.lsp.buf.rename, "Rename")

	-- Diagnostics / inlay hints
	k("n", "<leader>ld", function()
		local disabled = vim.b[bufnr]._diag_disabled
		vim.b[bufnr]._diag_disabled = not disabled
		vim.diagnostic.enable(not disabled, { bufnr = bufnr })
	end, "Toggle Diagnostics")

	if opts.supports_inlay_hints and vim.lsp.inlay_hint then
		k("n", "<leader>li", function()
			local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
			vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
		end, "Toggle Inlay Hints")
	end

	-- Texlab extras
	if opts.client_name == "texlab" then
		local function tex_cmd(cmd)
			return function()
				local client = vim.lsp.get_client_by_id(opts.client_id or 0)
				if client then
					client:exec_cmd({ command = cmd }, { bufnr = bufnr })
				end
			end
		end
		k("n", "<leader>lb", tex_cmd("texlab.build"), "LaTeX: Build")
		k("n", "<leader>lv", tex_cmd("texlab.forwardSearch"), "LaTeX: Forward Search")
	end
end

return M
