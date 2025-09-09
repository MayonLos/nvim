return {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPost", "BufNewFile" },
	build = ":TSUpdate",
	opts = {
		ensure_installed = {
			"vim",
			"vimdoc",
			"lua",
			"query",
			"c",
			"cpp",
			"python",
			"bash",
			"markdown",
			"markdown_inline",
			"json",
			"yaml",
			"toml",
			"html",
			"css",
			"javascript",
			"typescript",
		},

		auto_install = true,

		highlight = {
			enable = true,
			disable = function(lang, buf)
				local max_filesize = 100 * 1024
				local ok, stats = pcall(vim.loop.fs_stat, vim.api.nvim_buf_get_name(buf))
				if ok and stats and stats.size > max_filesize then
					return true
				end
			end,
		},

		indent = {
			enable = true,
			disable = { "python" },
		},
	},
}
