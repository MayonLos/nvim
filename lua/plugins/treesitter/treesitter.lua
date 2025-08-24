return {
	"nvim-treesitter/nvim-treesitter",
	event = { "BufReadPost", "BufNewFile" },
	build = ":TSUpdate",
	config = function()
		local uv = vim.uv or vim.loop
		local MAX = 100 * 1024
		local blacklist = { rust = true }

		require("nvim-treesitter.configs").setup {
			ensure_installed = {
				"vim",
				"vimdoc",
				"c",
				"cpp",
				"lua",
				"python",
				"bash",
				"markdown",
				"markdown_inline",
				"html",
				"latex",
				"bibtex",
				"json",
				"yaml",
				"toml",
				"regex",
				"query",
			},
			sync_install = false,
			auto_install = true,

			highlight = {
				enable = true,
				additional_vim_regex_highlighting = false,
				disable = function(lang, buf)
					if blacklist[lang] then
						return true
					end
					local ok, stat = pcall(uv.fs_stat, vim.api.nvim_buf_get_name(buf))
					return ok and stat and stat.size and stat.size > MAX
				end,
			},

			incremental_selection = {
				enable = true,
				keymaps = {
					init_selection = "gnn",
					node_incremental = "grn",
					scope_incremental = "grc",
					node_decremental = "grm",
				},
			},

			indent = {
				enable = true,
				disable = { "markdown" },
			},
		}
	end,
}
