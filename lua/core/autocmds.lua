local M = {}

function M.setup()
	vim.api.nvim_create_autocmd("TextYankPost", {
		group = vim.api.nvim_create_augroup("YankHighlight", { clear = true }),
		callback = function()
			vim.highlight.on_yank({ higroup = "IncSearch", timeout = 300 })
		end,
		desc = "Highlight yanked text",
	})
end

return M
