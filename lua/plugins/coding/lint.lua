return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufWritePost", "InsertLeave", "TextChanged" },
		config = function()
			local lint_utils = require("utils.lint")

			lint_utils.setup_linters()

			local group = vim.api.nvim_create_augroup("LintAutogroup", { clear = true })
			vim.api.nvim_create_autocmd({ "BufWritePost", "InsertLeave", "TextChanged" }, {
				group = group,
				callback = function()
					vim.defer_fn(function()
						lint_utils.trigger()
					end, 100)
				end,
			})

			vim.keymap.set("n", "<leader>ll", lint_utils.trigger, { desc = "Lint current buffer" })
		end,
	},
}
