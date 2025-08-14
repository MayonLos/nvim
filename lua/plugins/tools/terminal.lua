return {
	"akinsho/toggleterm.nvim",
	version = "*",
	keys = {
		{ "<leader>tf", desc = "Terminal Float" },
		{ "<leader>tv", desc = "Terminal Vertical" },
		{ "<leader>tt", desc = "Terminal Split" },
		{ "<leader>tg", desc = "Terminal Lazygit" },
		{ "<leader>tn", desc = "Terminal Node" },
		{ "<leader>tp", desc = "Terminal Python" },
		{ "<C-\\>", desc = "Terminal Toggle", mode = { "n", "t" } },
	},
	cmd = {
		"ToggleTerm",
		"TermExec",
		"ToggleTermSendCurrentLine",
		"ToggleTermSendVisualLines",
		"ToggleTermSendVisualSelection",
	},
	opts = function()
		local function pct(v, total)
			return math.floor(total * v)
		end
		return {
			size = function(term)
				if term.direction == "horizontal" then
					return 15
				elseif term.direction == "vertical" then
					return pct(0.4, vim.o.columns)
				end
			end,
			direction = "horizontal",
			hide_numbers = true,
			shade_terminals = false,
			start_in_insert = true,
			auto_scroll = true,
			persist_size = true,
			persist_mode = true,
			close_on_exit = true,
			shell = vim.o.shell,
			float_opts = {
				border = "rounded",
				width = function()
					return pct(0.8, vim.o.columns)
				end,
				height = function()
					return pct(0.8, vim.o.lines)
				end,
				winblend = 0,
			},
			winbar = { enabled = false },
		}
	end,

	config = function(_, opts)
		require("toggleterm").setup(opts)

		local Terminal = require("toggleterm.terminal").Terminal
		local terms = {}

		local function with_callbacks(cfg, key)
			cfg = vim.tbl_deep_extend("force", {
				on_open = function()
					vim.cmd "startinsert!"
				end,
				on_close = function()
					pcall(vim.cmd, "stopinsert!")
				end,
				on_exit = function()
					terms[key] = nil
				end,
			}, cfg or {})
			return cfg
		end

		local function get_or_create(key, cfg)
			if not terms[key] then
				terms[key] = Terminal:new(with_callbacks(cfg or {}, key))
			end
			return terms[key]
		end

		local function toggle(key, cfg)
			return function()
				if key == "lazygit" and vim.fn.executable "lazygit" == 0 then
					return vim.notify("lazygit not found in PATH", vim.log.levels.WARN)
				end
				get_or_create(key, cfg):toggle()
			end
		end

		local mapdefs = {
			{ "<leader>tf", "float", { direction = "float" }, "Terminal Float" },
			{ "<leader>tv", "vertical", { direction = "vertical" }, "Terminal Vertical" },
			{ "<leader>tt", "split", { direction = "horizontal" }, "Terminal Split" },
			{
				"<leader>tg",
				"lazygit",
				{ direction = "float", cmd = "lazygit", close_on_exit = true },
				"Terminal Lazygit",
			},
			{
				"<leader>tn",
				"node",
				{ direction = "float", cmd = "node", close_on_exit = true },
				"Terminal Node",
			},
			{
				"<leader>tp",
				"python",
				{ direction = "float", cmd = "python3", close_on_exit = true },
				"Terminal Python",
			},
			{ "<C-\\>", "main", { direction = "float" }, "Terminal Toggle" },
		}

		local mapopts = { noremap = true, silent = true }
		for _, def in ipairs(mapdefs) do
			local lhs, key, cfg, desc = unpack(def)
			vim.keymap.set({ "n", "t" }, lhs, toggle(key, cfg), vim.tbl_extend("force", mapopts, { desc = desc }))
		end

		local aug = vim.api.nvim_create_augroup("ToggleTermCustom", { clear = true })
		vim.api.nvim_create_autocmd("TermOpen", {
			group = aug,
			pattern = "term://*",
			callback = function()
				local buf = 0
				local o = { buffer = buf, silent = true }
				vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], o)
				vim.keymap.set("t", "jk", [[<C-\><C-n>]], o)
				vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], o)
				vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], o)
				vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], o)
				vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], o)
				vim.keymap.set("t", "<C-q>", [[<C-\><C-n>:q<CR>]], o)

				vim.opt_local.number = false
				vim.opt_local.relativenumber = false
				vim.opt_local.signcolumn = "no"
				vim.opt_local.foldcolumn = "0"
				vim.opt_local.spell = false
				vim.cmd "startinsert!"
			end,
		})

		vim.api.nvim_create_autocmd("VimResized", {
			group = aug,
			callback = function()
				vim.cmd "wincmd ="
			end,
		})

		-- 实用命令
		vim.api.nvim_create_user_command("TerminalSendLine", function()
			vim.cmd "ToggleTermSendCurrentLine"
		end, { desc = "Send current line to terminal" })

		vim.api.nvim_create_user_command("TerminalSendSelection", function()
			vim.cmd "ToggleTermSendVisualSelection"
		end, { range = true, desc = "Send selection to terminal" })

		vim.api.nvim_create_user_command("TerminalClear", function()
			for k, t in pairs(terms) do
				pcall(function()
					t:close()
				end)
				terms[k] = nil
			end
		end, { desc = "Clear all terminals" })
	end,
}
