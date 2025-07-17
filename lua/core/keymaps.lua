local M = {}

function M.setup()
	local map = vim.keymap.set
	local opts = { silent = true }

	-- ▍通用
	map("n", "<leader>nh", ":nohlsearch<CR>", { desc = "Clear search highlight" })

	-- ▍Buffer 操作
	map("n", "<leader>bn", "<Cmd>BufferNext<CR>", { desc = "Next buffer" })
	map("n", "<leader>bp", "<Cmd>BufferPrevious<CR>", { desc = "Previous buffer" })
	map("n", "<leader>bl", "<Cmd>BufferLast<CR>", { desc = "Go to last buffer" })
	map("n", "<leader>bb", "<Cmd>BufferPick<CR>", { desc = "Pick buffer" })
	map("n", "<leader>bd", "<Cmd>BufferClose<CR>", { desc = "Close buffer" })
	map("n", "<leader>bx", "<Cmd>BufferPickDelete<CR>", { desc = "Pick & delete buffer" })
	map("n", "<leader>bm", "<Cmd>BufferPin<CR>", { desc = "Pin/unpin buffer" })
	map("n", "<leader>bb", "<Cmd>BufferPick<CR>", { desc = "Pick buffer" })

	-- ▍Buffer 排序
	map("n", "<leader>bsn", "<Cmd>BufferOrderByName<CR>", { desc = "Sort buffers by name" })
	map("n", "<leader>bsd", "<Cmd>BufferOrderByDirectory<CR>", { desc = "Sort buffers by directory" })
	map("n", "<leader>bsl", "<Cmd>BufferOrderByLanguage<CR>", { desc = "Sort buffers by language" })
	map(
		"n",
		"<leader>bsw",
		"<Cmd>BufferOrderByWindowNumber<CR>",
		{ desc = "Sort buffers by window number" }
	)
end

return M
