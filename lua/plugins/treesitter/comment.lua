return {
	"numToStr/Comment.nvim",
	dependencies = {
		"JoosepAlviste/nvim-ts-context-commentstring",
	},
	keys = function()
		return require("core.keymaps").plugin("comment")
	end,
	config = function()
		vim.g.skip_ts_context_commentstring_module = true
		require("ts_context_commentstring").setup {
			enable_autocmd = false,
		}

		require("Comment").setup {
			padding = true,
			sticky = true,
			ignore = "^$",
			toggler = {
				line = "gcc",
				block = "gbc",
			},
			opleader = {
				line = "gc",
				block = "gb",
			},
			pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
		}
	end,
}
