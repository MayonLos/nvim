return {
	"numToStr/Comment.nvim",
	dependencies = {
		"JoosepAlviste/nvim-ts-context-commentstring",
	},
	keys = {
		{ "<C-/>", mode = { "n", "i", "v" } },
		{ "<C-_>", mode = { "n", "i", "v" } },
		{ "gc", mode = { "n", "v" } },
		{ "gb", mode = { "n", "v" } },
	},
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

		local api = require "Comment.api"

		vim.keymap.set("n", "<C-/>", api.toggle.linewise.current, { desc = "Toggle comment" })
		vim.keymap.set("v", "<C-/>", function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "nx", false)
			api.toggle.linewise(vim.fn.visualmode())
		end, { desc = "Toggle comment" })

		vim.keymap.set("i", "<C-/>", function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "nx", false)
			api.toggle.linewise.current()
			vim.cmd "startinsert!"
		end, { desc = "Toggle comment" })

		vim.keymap.set("n", "<C-_>", api.toggle.linewise.current, { desc = "Toggle comment" })
		vim.keymap.set("v", "<C-_>", function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "nx", false)
			api.toggle.linewise(vim.fn.visualmode())
		end, { desc = "Toggle comment" })
		vim.keymap.set("i", "<C-_>", function()
			vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<ESC>", true, false, true), "nx", false)
			api.toggle.linewise.current()
			vim.cmd "startinsert!"
		end, { desc = "Toggle comment" })
	end,
}
