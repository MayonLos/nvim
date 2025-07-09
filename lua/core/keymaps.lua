local M = {}

function M.setup()
	local map = vim.keymap.set
	local opts = { silent = true }

	-- ▍通用
	map("n", "<leader>nh", ":nohlsearch<CR>", { desc = "Clear search highlight" })

	-- ▍Buffer 操作（barbar.nvim）
	map("n", "<A-,>", "<Cmd>BufferPrevious<CR>", { desc = "Previous buffer" })
	map("n", "<A-.>", "<Cmd>BufferNext<CR>", { desc = "Next buffer" })

	map("n", "<A-c>", "<Cmd>BufferClose<CR>", { desc = "Close buffer" })
	map("n", "<A-p>", "<Cmd>BufferPin<CR>", { desc = "Pin/unpin buffer" })

	map("n", "<C-p>", "<Cmd>BufferPick<CR>", { desc = "Pick buffer" })
	map("n", "<C-s-p>", "<Cmd>BufferPickDelete<CR>", { desc = "Pick & delete buffer" })

	for i = 1, 9 do
		map("n", "<A-" .. i .. ">", "<Cmd>BufferGoto " .. i .. "<CR>", { desc = "Go to buffer " .. i })
	end
	map("n", "<A-0>", "<Cmd>BufferLast<CR>", { desc = "Go to last buffer" })

	map("n", "<leader>bo", "<Cmd>BufferOrderByBufferNumber<CR>", { desc = "Sort: buffer number" })
	map("n", "<leader>bn", "<Cmd>BufferOrderByName<CR>", { desc = "Sort: name" })
	map("n", "<leader>bd", "<Cmd>BufferOrderByDirectory<CR>", { desc = "Sort: directory" })
	map("n", "<leader>bl", "<Cmd>BufferOrderByLanguage<CR>", { desc = "Sort: language" })
	map("n", "<leader>bw", "<Cmd>BufferOrderByWindowNumber<CR>", { desc = "Sort: window number" })

	--  更多模块（占位）
	-- LSP
	-- map("n", "gd", vim.lsp.buf.definition, { desc = "LSP: Go to definition" })
	-- Git
	-- map("n", "<leader>gs", "<Cmd>Neogit<CR>", { desc = "Git: status" })
end

return M
