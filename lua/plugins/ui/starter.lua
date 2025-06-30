return {
	{
		"echasnovski/mini.starter",
		version = false,
		lazy = false,
		config = function()
			local starter = require("mini.starter")

			starter.setup({
				evaluate_single = true,

				header = table.concat({
					"╭──────────────────────────────────╮",
					"│         欢迎回来，启程吧！      │",
					"╰──────────────────────────────────╯",
				}, "\n"),

				items = {
					starter.sections.builtin_actions(),
					starter.sections.recent_files(5, true),
					starter.sections.sessions(3, true),
				},

				content_hooks = {
					starter.gen_hook.adding_bullet(" ", false),
					starter.gen_hook.aligning("center", "center"),
				},

				footer = " 正在加载启动信息...",
			})

			vim.api.nvim_create_autocmd("User", {
				pattern = "LazyVimStarted",
				callback = function(ev)
					local stats = require("lazy").stats()
					local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
					starter.config.footer = string.format(
						"⚡ 启动加载了 %d/%d 个插件，耗时 %.2fms",
						stats.loaded,
						stats.count,
						ms
					)
					if vim.bo[ev.buf].filetype == "ministarter" then
						pcall(starter.refresh)
					end
				end,
			})
		end,
	},
}
