return {
	"ibhagwan/fzf-lua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	cmd = "FzfLua",
	keys = function()
		return require("core.keymaps").plugin("fzf")
	end,
	opts = function()
		local fd = "fd --type f --hidden --follow --exclude .git"
		local rg = table.concat({
			"rg",
			"--column",
			"--line-number",
			"--no-heading",
			"--color=always",
		}, " ")

		return {
			previewers = {
				builtin = { scrollbar = false },
			},
			winopts = {
				height = 0.85,
				width = 0.82,
				row = 0.5,
				col = 0.5,
				border = "rounded",
			},
			keymap = {
				fzf = {
					["ctrl-q"] = "select-all+accept",
					["ctrl-a"] = "select-all",
				},
			},
			files = {
				fd_opts = fd,
				previewer = "builtin",
			},
			buffers = {
				sort_lastused = true,
				previewer = "builtin",
			},
			oldfiles = {
				include_current_session = true,
			},
			grep = {
				rg_opts = rg,
			},
			lsp = {
				icons = { ["Error"] = "E", ["Warning"] = "W", ["Information"] = "I", ["Hint"] = "H" },
			},
		}
	end,
	config = function(_, opts)
		local fzf = require("fzf-lua")
		fzf.setup(opts)
		fzf.register_ui_select()
	end,
}
