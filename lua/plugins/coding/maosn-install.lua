return {
	"WhoIsSethDaniel/mason-tool-installer.nvim",
	cmd = { "MasonToolsInstall", "MasonToolsUpdate" },
	event = "VeryLazy",
	dependencies = {
		"mason-org/mason.nvim",
	},
	opts = {
		ensure_installed = {
			-- ✅ LSP servers
			"clangd",
			"lua-language-server",
			"pyright",
			"bash-language-server",
			"marksman",

			-- ✅ formatters for conform.nvim
			"stylua",
			"black",
			"isort",
			"shfmt",
			"clang-format",
			"prettier",

			-- ✅ linters for nvim-lint
			"luacheck",
			"shellcheck",
			"pylint",
			"cpplint",
			"markdownlint",
		},
		run_on_start = true,
		auto_update = false,
		start_delay = 3000,
	},
}
