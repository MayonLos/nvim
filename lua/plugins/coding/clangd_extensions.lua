return {
	"p00f/clangd_extensions.nvim",
	ft = { "c", "cpp", "objc", "objcpp" },
	keys = function()
		return require("core.keymaps").plugin("clangd_extensions")
	end,
	opts = {
		ast = {
			highlights = { detail = "Comment" },
		},
		memory_usage = { border = "rounded" },
		symbol_info = { border = "rounded" },
	},
	config = function(_, opts)
		require("clangd_extensions").setup(opts)
	end,
}
