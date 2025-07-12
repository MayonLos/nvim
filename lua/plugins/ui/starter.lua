return {
	{
		"goolord/alpha-nvim",
		event = "VimEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			local alpha = require("alpha")
			local dashboard = require("alpha.themes.dashboard")
			local pad = string.rep(" ", 4) -- Consistent padding of 4 spaces

			-- Configuring header with ASCII art
			dashboard.section.header.val = {
				"███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
				"████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
				"██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
				"██║╚██╗██║██╔══╝  ██║   ██║██║   ██║██║██║╚██╔╝██║",
				"██║ ╚████║███████╗╚██████╔╝╚██████╔╝██║██║ ╚═╝ ██║",
				"╚═╝  ╚═══╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝     ╚═╝",
			}
			dashboard.section.header.opts.hl = "AlphaHeader"

			-- Configuring dashboard buttons with single-character keybindings
			dashboard.section.buttons.val = {
				dashboard.button("f", "󰱼  Find Files", "<cmd>lua require('telescope.builtin').find_files()<CR>"),
				dashboard.button("g", "  Live Grep", "<cmd>lua require('telescope.builtin').live_grep()<CR>"),
				dashboard.button("r", "  Recent Files", "<cmd>lua require('telescope.builtin').oldfiles()<CR>"),
				dashboard.button("h", "󰋖  Help Tags", "<cmd>lua require('telescope.builtin').help_tags()<CR>"),
				dashboard.button(
					"c",
					"⚙  Config Files",
					"<cmd>lua require('telescope.builtin').find_files({ cwd = vim.fn.stdpath('config') })<CR>"
				),
				dashboard.button("l", "󰒋  Plugin Manager", "<cmd>Lazy<CR>"),
				dashboard.button("n", "  New File", "<cmd>ene <BAR> startinsert<CR>"),
				dashboard.button("q", "󰅚  Quit Neovim", "<cmd>qa<CR>"),
			}
			dashboard.section.buttons.opts.hl = "AlphaButtons"
			dashboard.section.buttons.opts.hl_shortcut = "AlphaShortcut"

			-- Configuring footer with dynamic plugin statistics
			dashboard.section.footer.val = pad .. "Loading plugins..."
			dashboard.section.footer.opts.hl = "AlphaFooter"

			-- Defining optimized layout with balanced spacing
			dashboard.opts.layout = {
				{ type = "padding", val = 5 }, -- Increased top padding for better balance
				dashboard.section.header,
				{ type = "padding", val = 3 }, -- Adjusted spacing between header and buttons
				dashboard.section.buttons,
				{ type = "padding", val = 2 }, -- Reduced footer padding for compactness
				dashboard.section.footer,
			}

			-- Setting up alpha with no autocmds for cleaner startup
			dashboard.opts.opts.noautocmd = true
			alpha.setup(dashboard.opts)

			-- Managing statusline visibility
			vim.api.nvim_create_autocmd("User", {
				pattern = "AlphaReady",
				callback = function()
					vim.opt.laststatus = 0 -- Hide statusline when Alpha is active
				end,
			})

			vim.api.nvim_create_autocmd("BufUnload", {
				buffer = 0,
				callback = function()
					if vim.bo.filetype == "alpha" then
						vim.opt.laststatus = 2 -- Restore statusline when Alpha closes
					end
				end,
			})

			-- Updating footer with plugin statistics on LazyVim startup
			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyVimStarted",
				callback = function(ev)
					local stats = require("lazy").stats()
					local ms = math.floor(stats.startuptime * 100 + 0.5) / 100 -- Rounded to 2 decimal places
					dashboard.section.footer.val = pad
						.. string.format("⚡ %d/%d plugins loaded in %.2fms", stats.loaded, stats.count, ms)
					if vim.bo[ev.buf].filetype == "alpha" then
						pcall(alpha.start, true) -- Refresh Alpha if active
					end
				end,
			})

			-- Disabling folding for Alpha buffer
			vim.api.nvim_create_autocmd("FileType", {
				pattern = "alpha",
				callback = function()
					vim.opt_local.nofoldenable = true
				end,
			})
		end,
	},
}
