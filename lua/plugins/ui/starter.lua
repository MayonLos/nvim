return {
	{
		"echasnovski/mini.starter",
		version = false,
		event = "VimEnter",
		config = function()
			local starter = require("mini.starter")
			local pad = string.rep(" ", 4) -- Unified padding

			-- Original ASCII art header
			local header = table.concat({
				"███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗",
				"████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║",
				"██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║",
				"██║╚██╗██║██╔══╝  ██║   ██║██║   ██║██║██║╚██╔╝██║",
				"██║ ╚████║███████╗╚██████╔╝╚██████╔╝██║██║ ╚═╝ ██║",
				"╚═╝  ╚═══╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝╚═╝     ╚═╝",
			}, "\n")
			starter.setup({
				evaluate_single = false,
				header = header,
				query_updaters = "",
				items = {
					starter.sections.recent_files(5, true),
					starter.sections.builtin_actions(),
				},
				content_hooks = {
					starter.gen_hook.adding_bullet("• ", true),
					starter.gen_hook.aligning("center", "center"),
					starter.gen_hook.padding(3, 2),
				},
				footer = "",
				silent = true,
			})

			-- Delayed statistics loading
			vim.defer_fn(function()
				local stats = require("lazy").stats()
				local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
				starter.config.footer = pad .. string.format("⚡ %d plugins loaded in %.2fms", stats.count, ms)
				if vim.bo.filetype == "ministarter" then
					starter.refresh()
				end
			end, 50)
		end,
	},
}
