return {
	{
		"goolord/alpha-nvim",
		event = "VimEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local alpha = require "alpha"
			local dashboard = require "alpha.themes.dashboard"

			-- ASCII art header with Nerd Font icons
			dashboard.section.header.val = {
				"   ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗   ",
				"   ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║   ",
				"   ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║   ",
				"   ██║╚██╗██║██╔══╝  ██║   ██║██║   ██║██║██║╚██╔╝██║   ",
				"   ██║ ╚████║███████╗╚██████╔╝╚██████╔╝██║██║ ╚═╝ ██║   ",
				"   ╚═╝  ╚═══╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝     ╚═╝   ",
			}

			-- Dashboard buttons with Nerd Font icons (fzf-lua)
			dashboard.section.buttons.val = {
				dashboard.button("f", "󰈞  Find Files", "<cmd>lua require('fzf-lua').files()<CR>"),
				dashboard.button("g", "󰺮  Live Grep", "<cmd>lua require('fzf-lua').live_grep()<CR>"),
				dashboard.button("r", "󱋢  Recent Files", "<cmd>lua require('fzf-lua').oldfiles()<CR>"),
				dashboard.button("h", "󰋖  Help Tags", "<cmd>lua require('fzf-lua').help_tags()<CR>"),
				dashboard.button(
					"c",
					"󰒓  Config Files",
					"<cmd>lua require('fzf-lua').files({ cwd = vim.fn.stdpath('config') })<CR>"
				),
				dashboard.button("l", "󰒋  Plugin Manager", "<cmd>Lazy<CR>"),
				dashboard.button("n", "  New File", "<cmd>ene <BAR> startinsert<CR>"),
				dashboard.button("q", "󰅚  Quit Neovim", "<cmd>qa<CR>"),
			}

			-- Initial footer with icon
			dashboard.section.footer.val = "󰄙 Loading plugins..."

			-- Layout configuration
			dashboard.opts.layout = {
				{ type = "padding", val = 5 },
				dashboard.section.header,
				{ type = "padding", val = 3 },
				dashboard.section.buttons,
				{ type = "padding", val = 2 },
				dashboard.section.footer,
			}

			-- Highlight groups
			dashboard.section.header.opts.hl = "AlphaHeader"
			dashboard.section.buttons.opts.hl = "AlphaButtons"
			dashboard.section.buttons.opts.hl_shortcut = "AlphaShortcut"
			dashboard.section.footer.opts.hl = "AlphaFooter"

			dashboard.opts.opts.noautocmd = true
			alpha.setup(dashboard.opts)

			local alpha_group = vim.api.nvim_create_augroup("AlphaConfig", { clear = true })

			vim.api.nvim_create_autocmd("User", {
				pattern = "AlphaReady",
				group = alpha_group,
				callback = function()
					vim.opt.laststatus = 0
				end,
			})

			vim.api.nvim_create_autocmd("BufUnload", {
				group = alpha_group,
				callback = function(ev)
					if vim.bo[ev.buf].filetype == "alpha" then
						vim.opt.laststatus = 3
					end
				end,
			})

			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyVimStarted",
				group = alpha_group,
				callback = function()
					local ok, lazy = pcall(require, "lazy")
					if not ok then
						dashboard.section.footer.val = "󰅚 Failed to load plugin stats"
						return
					end
					local stats = lazy.stats()
					local ms = math.floor((stats.startuptime or 0) * 100 + 0.5) / 100
					dashboard.section.footer.val =
						string.format("⚡ %d/%d plugins loaded in %.2fms", stats.loaded or 0, stats.count or 0, ms)
					if vim.bo.filetype == "alpha" then
						pcall(function()
							vim.cmd "AlphaRedraw"
						end)
					end
				end,
			})

			vim.defer_fn(function()
				if vim.bo.filetype == "alpha" then
					local ok, lazy = pcall(require, "lazy")
					if ok then
						local stats = lazy.stats()
						if stats.loaded and stats.loaded > 0 then
							local ms = math.floor((stats.startuptime or 0) * 100 + 0.5) / 100
							dashboard.section.footer.val =
								string.format("⚡ %d/%d plugins loaded in %.2fms", stats.loaded, stats.count or 0, ms)
							pcall(function()
								vim.cmd "AlphaRedraw"
							end)
						end
					end
				end
			end, 1000)

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "alpha",
				group = alpha_group,
				callback = function()
					vim.opt_local.foldenable = false
					vim.opt_local.spell = false
					vim.opt_local.wrap = false
				end,
			})
		end,
	},
}
