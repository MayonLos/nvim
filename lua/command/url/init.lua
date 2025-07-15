local M = {}

function M.setup()
	for _, mod_name in ipairs({
		"command.url.open",
		"command.url.copy",
		"command.url.search",
	}) do
		local ok, mod = pcall(require, mod_name)
		if ok and type(mod.setup) == "function" then
			pcall(mod.setup)
		else
			vim.notify("Failed to load url module: " .. mod_name, vim.log.levels.WARN)
		end
	end
end

return M
