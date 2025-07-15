local M = {}

function M.setup()
	vim.api.nvim_create_user_command("OpenURL", function()
		local url = vim.fn.expand("<cWORD>")
		if url:match("^https?://") then
			vim.fn.jobstart({ "xdg-open", url }, { detach = true })
		else
			vim.notify("Invalid URL: " .. url, vim.log.levels.WARN)
		end
	end, { desc = "Open URL under cursor in browser" })
end

return M
