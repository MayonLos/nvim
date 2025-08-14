local M = {}

local modules = {
	"core.command.runners",
	"core.command.url",
	"core.command.cmake",
}

function M.setup()
	for _, mod_name in ipairs(modules) do
		local ok, mod = pcall(require, mod_name)
		if ok and type(mod.setup) == "function" then
			pcall(mod.setup)
		else
			vim.notify("Failed to load command module: " .. mod_name, vim.log.levels.WARN)
		end
	end
end

return M
