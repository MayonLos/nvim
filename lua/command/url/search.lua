local M = {}

function M.setup()
	vim.api.nvim_create_user_command("SearchURL", function()
		local word = vim.fn.expand("<cWORD>")
		local url = "https://www.google.com/search?q=" .. vim.fn.escape(word, " ")
		vim.fn.jobstart({ "xdg-open", url }, { detach = true })
	end, { desc = "Search word under cursor via Google" })
end

return M
