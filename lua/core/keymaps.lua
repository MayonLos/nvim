local M = {}

function M.setup()
	local map = vim.keymap.set
	local opts = { silent = true }

	map("n", "<leader>nh", ":nohlsearch<CR>", { desc = "Clear search highlight" })
end

return M
