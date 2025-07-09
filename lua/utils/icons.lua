local M = {}

local diagnostic_icons = {
	[vim.diagnostic.severity.ERROR] = "",
	[vim.diagnostic.severity.WARN] = "",
	[vim.diagnostic.severity.INFO] = "",
	[vim.diagnostic.severity.HINT] = "",
}

function M.apply_diagnostic_signs()
	vim.diagnostic.config({
		signs = {
			text = diagnostic_icons,
		},
	})
end

return M
