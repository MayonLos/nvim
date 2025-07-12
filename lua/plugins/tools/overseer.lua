return {
	"stevearc/overseer.nvim",
	cmd = { "OverseerRun", "OverseerToggle", "OverseerOpen", "OverseerClose" },
	dependencies = {
		{
			"nvim-telescope/telescope.nvim",
			optional = true,
		},
	},
	opts = {
		templates = { "builtin", "user.cpp_build", "user.run_script" },
		strategy = "jobstart",
		task_list = {
			bindings = {
				["q"] = "<Cmd>OverseerClose<CR>",
			},
		},
	},
	config = function(_, opts)
		local overseer = require("overseer")
		if vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) == "" then
			return
		end
		overseer.setup(opts)

		local keymaps = {
			{ "n", "<Leader>or", "<Cmd>OverseerRun<CR>", "Run Overseer task" },
			{ "n", "<Leader>ot", "<Cmd>OverseerToggle<CR>", "Toggle Overseer task list" },
			{ "n", "<Leader>oo", "<Cmd>OverseerOpen<CR>", "Open Overseer task list" },
		}

		for _, map in ipairs(keymaps) do
			vim.keymap.set(map[1], map[2], map[3], { desc = map[4], noremap = true, silent = true })
		end
	end,
}
