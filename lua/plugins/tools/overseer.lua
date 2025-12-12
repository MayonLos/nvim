return {
	"stevearc/overseer.nvim",
	cmd = {
		"OverseerRun",
		"OverseerToggle",
		"OverseerQuickAction",
		"OverseerLoadBundle",
		"OverseerSaveBundle",
	},
	keys = {},
	opts = {
		task_list = {
			direction = "float",
			bindings = {
				["q"] = "Close",
				["<Esc>"] = "Close",
			},
		},
		confirm = {
			border = "rounded",
		},
		templates = { "builtin", "user.run_script", "user.make", "user.cargo" },
	},
	config = function(_, opts)
		local overseer = require("overseer")
		overseer.setup(opts)

		-- 快速：当前文件运行并监听保存后重跑
		vim.api.nvim_create_user_command("WatchRun", function()
			overseer.run_task({ name = "run script", autostart = false }, function(task)
				if not task then
					vim.notify(
						"WatchRun not supported for filetype " .. vim.bo.filetype,
						vim.log.levels.ERROR
					)
					return
				end
				task:add_component({ "restart_on_save", paths = { vim.fn.expand("%:p") } })
				task:start()
				task:open_output("vertical")
			end)
		end, { desc = "Overseer: run current file and re-run on save" })
	end,
}
