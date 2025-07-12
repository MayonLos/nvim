return {
	{
		"echasnovski/mini.starter",
		version = false,
		event = "VimEnter",
		config = function()
			local starter = require("mini.starter")
			local pad = string.rep(" ", 4) -- Consistent padding of 4 spaces

			-- ASCII logo (font: ANSI Shadow via patorjk.com)
			local header = table.concat({
				"███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
				"████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
				"██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
				"██║╚██╗██║██╔══╝  ██║   ██║██║   ██║██║██║╚██╔╝██║",
				"██║ ╚████║███████╗╚██████╔╝╚██████╔╝██║██║ ╚═╝ ██║",
				"╚═╝  ╚═══╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝     ╚═╝",
			}, "\n")

			-- Initial starter setup
			starter.setup({
				evaluate_single = true,
				header = header,
				items = {
					starter.sections.recent_files(5, true), -- Display up to 5 recent files
					starter.sections.builtin_actions(), -- Include built-in actions
				},
				content_hooks = {
					starter.gen_hook.adding_bullet("• ", false), -- Add right-aligned bullets
					starter.gen_hook.aligning("center", "center"), -- Center-align content
				},
				footer = pad .. "Loading plugins...", -- Initial footer with padding
			})

			-- Hide statusline when MiniStarter is opened
			vim.api.nvim_create_autocmd("User", {
				pattern = "MiniStarterOpened",
				callback = function()
					vim.opt.laststatus = 0
				end,
			})

			-- Restore statusline when MiniStarter is closed
			vim.api.nvim_create_autocmd("BufUnload", {
				buffer = 0,
				callback = function()
					if vim.bo.filetype == "ministarter" then
						vim.opt.laststatus = 2
					end
				end,
			})

			-- Update footer with plugin statistics on LazyVim start
			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyVimStarted",
				callback = function(ev)
					local stats = require("lazy").stats()
					local ms = math.floor(stats.startuptime * 100 + 0.5) / 100 -- Rounded to 2 decimal places
					starter.config.footer = pad
						.. string.format(
							"⚡ %d/%d plugins loaded in %.2fms",
							stats.loaded, -- Number of loaded plugins
							stats.count, -- Total number of plugins
							ms
						)
					if vim.bo[ev.buf].filetype == "ministarter" then
						pcall(starter.refresh) -- Safely refresh if active
					end
				end,
			})
		end,
	},
}
