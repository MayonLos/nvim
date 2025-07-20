return {
	"WhoIsSethDaniel/mason-tool-installer.nvim",
	cmd = { "MasonToolsInstall", "MasonToolsUpdate", "MasonToolsClean" },
	event = "VeryLazy",
	opts = {
		ensure_installed = {
			-- ✅ LSP Servers (only what you need)
			"clangd", -- C/C++ language server
			"lua-language-server", -- Lua language server
			"pyright", -- Python language server
			"marksman", -- Markdown language server

			-- ✅ Formatters (focused on your languages)
			"stylua", -- Lua formatter
			"isort", -- python formatter
			"black", --python formatter
			"ruff", -- Modern Python formatter/linter
			"clang-format", -- C/C++ formatter
			"prettier", -- Markdown formatter
			"prettierd", -- Faster prettier daemon

			-- ✅ Linters (essential ones only)
			"luacheck", -- Lua linter
			"markdownlint", -- Markdown linter
			"cpplint", --C/C++ linter

			-- ✅ DAP Adapters (debug support)
			"codelldb", -- C/C++ debugger
			"debugpy", -- Python debugger
		},

		-- Installation settings
		run_on_start = true, -- Install tools on startup
		auto_update = false, -- Don't auto-update (can be slow)
		start_delay = 3000, -- Wait 3 seconds before installing

		-- Integration settings
		integrations = {
			["mason-lspconfig"] = true,
			["mason-null-ls"] = false, -- We're using conform instead
			["mason-nvim-dap"] = true,
		},
	},
}
