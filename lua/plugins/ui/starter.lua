return {
	{
		"echasnovski/mini.starter",
		version = false,
		event = "VimEnter",
		config = function()
			local starter = require("mini.starter")

			-- ASCII logo (font: ANSI Shadow via patorjk.com)
			local header = table.concat({
				"███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
				"████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
				"██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
				"██║╚██╗██║██╔══╝  ██║   ██║██║   ██║██║██║╚██╔╝██║",
				"██║ ╚████║███████╗╚██████╔╝╚██████╔╝██║██║ ╚═╝ ██║",
				"╚═╝  ╚═══╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝     ╚═╝",
			}, "\n")

			starter.setup({
				evaluate_single = true,
				header = header,

				items = {
					starter.sections.recent_files(5, true),
					starter.sections.builtin_actions(),
				},

				content_hooks = {
					starter.gen_hook.adding_bullet("→ ", false),
					starter.gen_hook.aligning("center", "center"),
				},

				footer = "Loading plugins...",
			})

			-- Hide statusline in starter
			vim.api.nvim_create_autocmd("User", {
				pattern = "MiniStarterOpened",
				callback = function()
					vim.opt.laststatus = 0
				end,
			})

			-- Restore statusline after starter
			vim.api.nvim_create_autocmd("BufUnload", {
				buffer = 0,
				callback = function()
					if vim.bo.filetype == "ministarter" then
						vim.opt.laststatus = 2
					end
				end,
			})

			-- Update footer with plugin stats
			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyVimStarted",
				callback = function(ev)
					local stats = require("lazy").stats()
					local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
					starter.config.footer =
						string.format("⚡ %d/%d plugins loaded in %.2fms", stats.loaded, stats.count, ms)
					if vim.bo[ev.buf].filetype == "ministarter" then
						pcall(starter.refresh)
					end
				end,
			})
		end,
	},
}
