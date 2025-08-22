return {
	{
		"folke/noice.nvim",
		event = "VeryLazy",
		dependencies = {
			"MunifTanjim/nui.nvim",
			{
				"rcarriga/nvim-notify",
				lazy = true,
				opts = { background_colour = "#000000" },
			},
		},
		opts = {
			lsp = {
				progress = { enabled = true },
				signature = { enabled = false },
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true,
				},
			},

			cmdline = {
				-- view = "cmdline",
				format = {
					cmdline = { pattern = "^:", icon = "", lang = "vim" },
					search_down = { kind = "search", pattern = "^/", icon = " ", lang = "regex" },
					search_up = { kind = "search", pattern = "^%?", icon = " ", lang = "regex" },
				},
			},

			popupmenu = { enabled = false },

			presets = {
				bottom_search = true,
				command_palette = false,
				long_message_to_split = true,
				inc_rename = false,
				lsp_doc_border = false,
			},

			routes = {
				{ filter = { event = "msg_show", find = "written" }, opts = { skip = true } },
				{ filter = { event = "msg_show", find = "yanked" }, opts = { skip = true } },
			},

			views = {
				mini = { win_options = { winblend = 0 } },
			},
		},
	},
}
