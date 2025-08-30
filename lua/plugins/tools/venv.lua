return {
	"linux-cultist/venv-selector.nvim",
	dependencies = {
		"mfussenegger/nvim-dap",
		"mfussenegger/nvim-dap-python",
	},
	ft = "python",
	keys = {
		{ ",v", "<cmd>VenvSelect<cr>" },
	},
	opts = {
		options = {
			picker = "fzf-lua",
			on_venv_activate_callback = function()
				vim.schedule(function()
					vim.cmd "redrawstatus"
				end)
			end,
		},
	},
}
