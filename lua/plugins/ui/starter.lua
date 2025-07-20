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

			-- Dashboard buttons with Nerd Font icons
			dashboard.section.buttons.val = {
				dashboard.button("f", "󰈞  Find Files", "<cmd>Telescope find_files<CR>"),
				dashboard.button("g", "󰺮  Live Grep", "<cmd>Telescope live_grep<CR>"),
				dashboard.button("r", "󱋢  Recent Files", "<cmd>Telescope oldfiles<CR>"),
				dashboard.button("h", "󰋖  Help Tags", "<cmd>Telescope help_tags<CR>"),
				dashboard.button(
					"c",
					"󰒓  Config Files",
					"<cmd>Telescope find_files cwd=" .. vim.fn.stdpath "config" .. "<CR>"
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

			-- Disable autocmds for cleaner startup
			dashboard.opts.opts.noautocmd = true

			-- Setup alpha
			alpha.setup(dashboard.opts)

			-- Autocommands
			local alpha_group = vim.api.nvim_create_augroup("AlphaConfig", { clear = true })

			-- Hide statusline when Alpha is active
			vim.api.nvim_create_autocmd("User", {
				pattern = "AlphaReady",
				group = alpha_group,
				callback = function()
					vim.opt.laststatus = 0
				end,
			})

			-- Restore statusline when leaving Alpha
			vim.api.nvim_create_autocmd("BufUnload", {
				group = alpha_group,
				callback = function(ev)
					if vim.bo[ev.buf].filetype == "alpha" then
						vim.opt.laststatus = 3
					end
				end,
			})

			-- Update footer with plugin statistics and icon
			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyVimStarted",
				group = alpha_group,
				callback = function()
					-- Ensure lazy is available
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

			-- Defer updating the footer for plugin stats
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

			-- Disable folding, spell, and wrap for Alpha buffer
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
