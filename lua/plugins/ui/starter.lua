return {
	"goolord/alpha-nvim",
	event = "VimEnter",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")

		dashboard.section.header.val = {
			"",
			"    ███╗   ██╗ ███████╗ ██████╗  ██╗   ██╗ ██╗ ███╗   ███╗",
			"    ████╗  ██║ ██╔════╝██╔═══██╗ ██║   ██║ ██║ ████╗ ████║",
			"    ██╔██╗ ██║ █████╗  ██║   ██║ ██║   ██║ ██║ ██╔████╔██║",
			"    ██║╚██╗██║ ██╔══╝  ██║   ██║ ╚██╗ ██╔╝ ██║ ██║╚██╔╝██║",
			"    ██║ ╚████║ ███████╗╚██████╔╝  ╚████╔╝  ██║ ██║ ╚═╝ ██║",
			"    ╚═╝  ╚═══╝ ╚══════╝ ╚═════╝    ╚═══╝   ╚═╝ ╚═╝     ╚═╝",
			"",
			"",
		}

		dashboard.section.buttons.val = {
			dashboard.button("f", "󰈞  Find Files", ":lua require('fzf-lua').files()<CR>"),
			dashboard.button("g", "󰺮  Live Grep", ":lua require('fzf-lua').live_grep()<CR>"),
			dashboard.button("r", "󱋢  Recent Files", ":lua require('fzf-lua').oldfiles()<CR>"),
			dashboard.button("n", "󰈔  New File", ":enew<CR>"),
			dashboard.button(
				"c",
				"󰒓  Config",
				":lua require('fzf-lua').files({ cwd = vim.fn.stdpath('config') })<CR>"
			),
			dashboard.button("l", "󰒋  Lazy", ":Lazy<CR>"),
			dashboard.button("q", "󰅚  Quit", ":qa<CR>"),
		}

		local version = vim.version()
		local nvim_version = "v" .. version.major .. "." .. version.minor .. "." .. version.patch
		dashboard.section.footer.val = {
			"",
			"📡 Neovim " .. nvim_version .. "  " .. os.date("%Y-%m-%d %H:%M"),
			"",
		}

		dashboard.opts.layout = {
			{ type = "padding", val = 2 },
			dashboard.section.header,
			{ type = "padding", val = 2 },
			dashboard.section.buttons,
			{ type = "padding", val = 1 },
			dashboard.section.footer,
		}

		dashboard.section.header.opts.hl = "AlphaHeader"
		dashboard.section.buttons.opts.hl = "AlphaButtons"
		dashboard.section.footer.opts.hl = "AlphaFooter"

		for _, button in ipairs(dashboard.section.buttons.val) do
			button.opts.hl = "AlphaButtons"
			button.opts.hl_shortcut = "AlphaShortcut"
			button.opts.position = "center"
			button.opts.cursor = 3
			button.opts.width = 40
			button.opts.align_shortcut = "right"
		end

		alpha.setup(dashboard.opts)

		vim.api.nvim_create_autocmd("User", {
			pattern = "LazyVimStarted",
			once = true,
			callback = function()
				vim.schedule(function()
					local stats = require("lazy").stats()
					local ms = math.floor(stats.startuptime + 0.5)

					dashboard.section.footer.val = {
						"",
						string.format("⚡ Loaded %d plugins in %dms", stats.loaded, ms),
						"📡 Neovim " .. nvim_version .. "  " .. os.date("%Y-%m-%d %H:%M"),
						"",
					}

					if vim.bo.filetype == "alpha" then
						pcall(vim.cmd.AlphaRedraw)
					end
				end)
			end,
		})

		local function set_highlights()
			vim.api.nvim_set_hl(0, "AlphaHeader", { fg = "#7aa2f7", bold = true })
			vim.api.nvim_set_hl(0, "AlphaButtons", { fg = "#9ece6a" })
			vim.api.nvim_set_hl(0, "AlphaShortcut", { fg = "#ff9e64", bold = true })
			vim.api.nvim_set_hl(0, "AlphaFooter", { fg = "#565f89", italic = true })
		end

		set_highlights()
		vim.api.nvim_create_autocmd("ColorScheme", { callback = set_highlights })

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "alpha",
			callback = function(ev)
				vim.opt_local.number = false
				vim.opt_local.relativenumber = false
				vim.opt_local.cursorline = false

				local opts = { buffer = ev.buf, silent = true }
				vim.keymap.set("n", "q", ":qa<CR>", opts)
				vim.keymap.set("n", "<Esc>", ":qa<CR>", opts)
			end,
		})
	end,
}
