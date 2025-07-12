return {
	{
		"numToStr/Comment.nvim",
		dependencies = {
			"JoosepAlviste/nvim-ts-context-commentstring",
		},
		keys = {
			{ "gcc", desc = "Toggle line comment" },
			{ "gbc", desc = "Toggle block comment" },
			{ "gc", mode = { "n", "v" }, desc = "Comment operator" },
			{ "gb", mode = { "n", "v" }, desc = "Block comment operator" },
			{ "gcO", desc = "Add comment above" },
			{ "gco", desc = "Add comment below" },
			{ "gcA", desc = "Add comment at EOL" },
		},
		config = function()
			vim.g.skip_ts_context_commentstring_module = true
			require("ts_context_commentstring").setup({})
			local opts = {
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
				extra = {
					above = "gcO",
					below = "gco",
					eol = "gcA",
				},
				mappings = {
					basic = true,
					extra = true,
				},
				pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
				post_hook = nil,
			}
			require("Comment").setup(opts)

			local ft = require("Comment.ft")
			ft.set("lua", { "--%s", "--[[%s]]" })
			ft.set("vim", { '"%s' })
			ft.set("c", { "//%s", "/*%s*/" })
			ft.set("cpp", { "//%s", "/*%s*/" })
		end,
	},
}
