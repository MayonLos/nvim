local M = {}

function M.setup()
	vim.api.nvim_create_user_command("CopyURL", function()
		local url = vim.fn.expand("<cWORD>")
		if url:match("^https?://") then
			vim.fn.setreg("+", url)
			vim.notify("Copied to clipboard: " .. url, vim.log.levels.INFO)
		else
			vim.notify("Invalid URL: " .. url, vim.log.levels.WARN)
		end
	end, { desc = "Copy URL under cursor to clipboard" })
end

return M
