return {
	{
		"mason-org/mason.nvim",
		build = ":MasonUpdate",
		opts = {},
		event = "VeryLazy",
		config = function(_, opts)
			require("mason").setup(opts)

			local packages = {
				-- LSP servers
				"lua-language-server", -- Lua
				"clangd", -- C/C++
				"pyright", -- Python
				"marksman", -- Markdown
				"texlab", -- LaTeX

				-- Formatters
				"stylua",
				"isort",
				"black",
				"ruff",
				"clang-format",
				"prettier",
				"prettierd",

				-- Linters
				"luacheck",
				"markdownlint",
				"cpplint",
			}

			local mr = require "mason-registry"
			mr.refresh(function()
				for _, name in ipairs(packages) do
					local ok, pkg = pcall(mr.get_package, name)
					if ok then
						if not pkg:is_installed() then
							pkg:install()
						end
					else
						vim.notify("mason: package not found -> " .. name, vim.log.levels.WARN)
					end
				end
			end)
		end,
	},
}
