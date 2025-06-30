local M = {}

local lint = require("lint")

function M.setup_linters()
	lint.linters_by_ft = {
		cpp = { "cpplint" },
		c = { "cpplint" },
		python = { "pylint" },
		sh = { "shellcheck" },
		lua = { "luacheck" },
		markdown = { "markdownlint" },
	}
end

function M.trigger()
	lint.try_lint()
end

return M
