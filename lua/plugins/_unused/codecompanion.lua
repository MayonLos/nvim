return {
	"olimorris/codecompanion.nvim",
	cmd = {
		"CodeCompanion",
		"CodeCompanionChat",
		"CodeCompanionAction",
		"CodeCompanionCmd",
		"CodeCompanionHistory",
		"CodeCompanionSummaries",
	},
	keys = {
		{ "<leader>ac", "<cmd>CodeCompanionChat<cr>", desc = "AI Chat", mode = { "n", "v" } },
		{ "<leader>aa", "<cmd>CodeCompanionAction<cr>", desc = "AI Action", mode = { "n", "v" } },
		{ "<leader>ah", "<cmd>CodeCompanionHistory<cr>", desc = "AI History", mode = { "n", "v" } },
		{ "<leader>as", "<cmd>CodeCompanionSummaries<cr>", desc = "AI Summaries", mode = { "n", "v" } },
	},
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		"franco-ruggeri/codecompanion-spinner.nvim",
		"folke/noice.nvim",
		"ravitemer/codecompanion-history.nvim",
		{
			"echasnovski/mini.diff",
			config = function()
				require("mini.diff").setup {
					source = require("mini.diff").gen_source.none(),
				}
			end,
		},
	},
	config = function()
		local ok, companion_notification = pcall(require, "codecompanion.extensions.companion-notification")
		if ok then
			companion_notification.init()
		end

		require("codecompanion").setup {
			strategies = {
				chat = {
					keymaps = {
						send = {
							modes = {
								n = "<CR>",
								i = "<C-s>",
							},
							opts = { desc = "Send message" },
						},
						close = {
							modes = {
								n = "<C-c>",
								i = "<C-c>",
							},
							opts = { desc = "Close chat" },
						},
					},
				},
			},
			log_level = "DEBUG",
			display = {
				action_palette = {
					width = 95,
					height = 10,
					prompt = "Prompt ",
					-- provider = "fzf-lua",
					opts = {
						show_default_actions = true,
						show_default_prompt_library = true,
					},
				},
				diff = {
					enabled = true,
					close_chat_at = 240,
					layout = "vertical",
					provider = "mini_diff",
					opts = {
						"internal",
						"filler",
						"closeoff",
						"algorithm:patience",
						"followwrap",
						"linematch:120",
					},
				},
			},
			extensions = {
				spinner = {},
				history = {
					enabled = true,
					opts = {},
				},
			},
		}
	end,
}
