return {
	"goolord/alpha-nvim",
	event = "VimEnter",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local alpha = require("alpha")
		local dashboard = require("alpha.themes.dashboard")

		dashboard.section.header.val = {
			"   ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗   ",
			"   ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║   ",
			"   ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║   ",
			"   ██║╚██╗██║██╔══╝  ██║   ██║██║   ██║██║██║╚██╔╝██║   ",
			"   ██║ ╚████║███████╗╚██████╔╝╚██████╔╝██║██║ ╚═╝ ██║   ",
			"   ╚═╝  ╚═══╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝     ╚═╝   ",
		}

		dashboard.section.buttons.val = {
			dashboard.button("f", "󰈞  Find Files", "<cmd>lua require('fzf-lua').files()<CR>"),
			dashboard.button("g", "󰺮  Live Grep", "<cmd>lua require('fzf-lua').live_grep()<CR>"),
			dashboard.button(
				"r",
				"󱋢  Recent Files",
				"<cmd>lua require('fzf-lua').oldfiles()<CR>"
			),
			dashboard.button("h", "󰋖  Help Tags", "<cmd>lua require('fzf-lua').help_tags()<CR>"),
			dashboard.button(
				"c",
				"󰒓  Config Files",
				"<cmd>lua require('fzf-lua').files({ cwd = vim.fn.stdpath('config') })<CR>"
			),
			dashboard.button("l", "󰒋  Plugin Manager", "<cmd>Lazy<CR>"),
			dashboard.button("n", "  New File", "<cmd>ene <BAR> startinsert<CR>"),
			dashboard.button("q", "󰅚  Quit Neovim", "<cmd>qa<CR>"),
		}

		dashboard.section.footer.val = "󰄙 Loading plugins..."

		dashboard.opts.layout = {
			{ type = "padding", val = 5 },
			dashboard.section.header,
			{ type = "padding", val = 3 },
			dashboard.section.buttons,
			{ type = "padding", val = 2 },
			dashboard.section.footer,
		}

		dashboard.section.header.opts.hl = "AlphaHeader"
		dashboard.section.buttons.opts.hl = "AlphaButtons"
		dashboard.section.footer.opts.hl = "AlphaFooter"

		alpha.setup(dashboard.opts)

		vim.api.nvim_create_autocmd("User", {
			pattern = "AlphaReady",
			callback = function()
				vim.opt.laststatus = 0
			end,
		})

		vim.api.nvim_create_autocmd("BufUnload", {
			callback = function(ev)
				if vim.bo[ev.buf].filetype == "alpha" then
					vim.opt.laststatus = 3
				end
			end,
		})

		vim.api.nvim_create_autocmd("User", {
			pattern = "LazyVimStarted",
			callback = function()
				local stats = require("lazy").stats()
				local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
				dashboard.section.footer.val = string.format(
					"⚡ %d/%d plugins loaded in %.2fms",
					stats.loaded,
					stats.count,
					ms
				)
				if vim.bo.filetype == "alpha" then
					vim.cmd("AlphaRedraw")
				end
			end,
		})
	end,
}
