local M = {}

function M.setup()
	vim.api.nvim_create_user_command("RunCode", function()
		require("command.runner.logic").compile_and_run()
	end, { desc = "Compile and run current file" })
end

return M
