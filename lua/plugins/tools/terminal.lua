return {
	{
		"akinsho/toggleterm.nvim",
		version = "*",
		cmd = { "ToggleTerm", "TermExec", "CodexTerm" },
		keys = function()
			return require("core.keymaps").plugin("toggleterm")
		end,
		opts = function()
			local function float_size()
				local h = math.floor((vim.o.lines - vim.o.cmdheight) * 0.85)
				local w = math.floor(vim.o.columns * 0.85)
				return h, w
			end

			local height, width = float_size()

			return {
				direction = "float",
				open_mapping = [[<C-\>]],
				start_in_insert = true,
				close_on_exit = false, -- codex 不要一关就死
				shade_terminals = false,
				persist_mode = true,
				persist_size = true,
				float_opts = {
					border = "rounded",
					width = width,
					height = height,
					winblend = 0,
				},
			}
		end,
		config = function(_, opts)
			require("toggleterm").setup(opts)

			local Terminal = require("toggleterm.terminal").Terminal

			local function project_root()
				for _, client in pairs(vim.lsp.get_clients { bufnr = 0 }) do
					if client.config and client.config.root_dir then
						return client.config.root_dir
					end
				end
				local buf = vim.api.nvim_buf_get_name(0)
				local found = vim.fs.find(
					{ ".git", "pyproject.toml", "package.json", "CMakeLists.txt" },
					{ path = buf ~= "" and buf or vim.loop.cwd(), upward = true }
				)[1]
				return found and vim.fs.dirname(found) or vim.loop.cwd()
			end

			local codex
			local function toggle_codex()
				if not codex then
					codex = Terminal:new({
						name = "codex",
						cmd = "codex", -- or other CLI
						dir = project_root(),
						direction = "float",
						close_on_exit = false,
						-- large count to avoid clashing with numbered terminals
						count = 999,
						on_open = function(term)
							vim.cmd.startinsert()
							pcall(vim.api.nvim_buf_set_option, term.bufnr, "filetype", "codex")
						end,
					})
				end
				codex:toggle()
			end

			vim.api.nvim_create_user_command("CodexTerm", toggle_codex, {
				desc = "Toggle Codex float terminal",
			})
		end,
	},
}
