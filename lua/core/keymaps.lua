local M = {}

function M.setup()
	vim.keymap.set("n", "<leader>nh", ":nohlsearch<CR>", { desc = "Clear highlight" })
	vim.keymap.set("n", "<leader>bn", ":bnext<CR>", { desc = "Next buffer" })
	vim.keymap.set("n", "<leader>bp", ":bprevious<CR>", { desc = "Previous buffer" })
end

return M
