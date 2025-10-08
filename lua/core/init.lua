for _, module_name in ipairs({
	"core.options",
	"core.autocmds",
	"core.command",
	"core.keymaps",
	"core.lspconfig",
}) do
	local ok, mod_or_err = pcall(require, module_name)

	if not ok then
		vim.notify(
			string.format("Failed to load %s: %s", module_name, mod_or_err),
			vim.log.levels.WARN
		)
	else
		if type(mod_or_err) == "table" and type(mod_or_err.setup) == "function" then
			pcall(mod_or_err.setup)
		end
	end
end
