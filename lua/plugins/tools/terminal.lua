return {
	{
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
			local function pct(ratio, total)
				return math.floor(total * ratio)
			end
			local function usable_lines()
				return vim.o.lines - vim.o.cmdheight
			end

			return {
				size = function(term)
					if term.direction == "horizontal" then
						return 15
					elseif term.direction == "vertical" then
						return pct(0.40, vim.o.columns)
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
						return pct(0.85, vim.o.columns)
					end,
					height = function()
						return pct(0.85, usable_lines())
					end,
					winblend = 0,
				},
				winbar = { enabled = false },
			}
		end,

		config = function(_, opts)
			require("toggleterm").setup(opts)
			local Terminal = require("toggleterm.terminal").Terminal

			local function project_root()
				-- 1) LSP root
				for _, client in pairs(vim.lsp.get_clients { bufnr = 0 }) do
					local ws = client.config and client.config.workspace_folders
					local root = ws and ws[1] and ws[1].name
					if root and root ~= "" then
						return root
					end
					if client.config and client.config.root_dir and client.config.root_dir ~= "" then
						return client.config.root_dir
					end
				end
				-- 2) Git / 常见工程文件
				local bufpath = vim.api.nvim_buf_get_name(0)
				local patterns = { ".git", "pyproject.toml", "package.json", "CMakeLists.txt", "compile_commands.json" }
				local found =
					vim.fs.find(patterns, { path = bufpath ~= "" and bufpath or vim.loop.cwd(), upward = true })[1]
				if found then
					return vim.fs.dirname(found)
				end
				-- 3) Fallback: 当前工作目录
				return vim.loop.cwd()
			end

			local terms = {} ---@type table<string, any>

			local function new_term_config(extra)
				return vim.tbl_deep_extend("force", {
					dir = project_root(),
					on_open = function(t)
						vim.cmd "startinsert!"
					end,
					on_close = function()
						pcall(vim.cmd, "stopinsert!")
					end,
					on_exit = function(term)
						-- 退出清理缓存
						for k, v in pairs(terms) do
							if v == term then
								terms[k] = nil
							end
						end
					end,
				}, extra or {})
			end

			local function get_or_create(key, cfg)
				if not terms[key] then
					terms[key] = Terminal:new(new_term_config(cfg))
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

			local maps = {
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
			for _, m in ipairs(maps) do
				local lhs, key, cfg, desc = unpack(m)
				vim.keymap.set({ "n", "t" }, lhs, toggle(key, cfg), vim.tbl_extend("force", mapopts, { desc = desc }))
			end

			local aug = vim.api.nvim_create_augroup("ToggleTerm.Custom", { clear = true })

			vim.api.nvim_create_autocmd("TermOpen", {
				group = aug,
				callback = function(args)
					if vim.bo[args.buf].filetype ~= "toggleterm" then
						return
					end
					local o = { buffer = args.buf, silent = true }
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
				end,
			})

			vim.api.nvim_create_autocmd("VimResized", {
				group = aug,
				callback = function()
					vim.cmd "wincmd ="
				end,
			})

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
			end, { desc = "Close & clear all toggleterm instances" })
		end,
	},
}
