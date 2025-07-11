return {
	{
		"olimorris/codecompanion.nvim",
		cmd = {
			"CodeCompanionChat",
			"CodeCompanionAct",
			"CodeCompanionCmd",
			"CodeCompanionToggle",
		},
		keys = {
			{ "<leader>ac", "<cmd>CodeCompanionChat<cr>", desc = "AI Chat" },
			{ "<leader>aa", "<cmd>CodeCompanionAct<cr>", desc = "AI Action" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			"ravitemer/mcphub.nvim",
			"MeanderingProgrammer/render-markdown.nvim",
			{
				"sindrets/diffview.nvim",
				config = function()
					require("diffview").setup({
						enhanced_diff_hl = true,
						use_icons = true,
					})
				end,
			},
		},
		config = function()
			local adapters = require("codecompanion.adapters")

			local function setup_deepseek()
				return adapters.extend("deepseek", {
					env = {
						api_key = os.getenv("DEEPSEEK_API_KEY"),
					},
				})
			end

			require("codecompanion").setup({
				adapters = {
					deepseek = setup_deepseek,
				},
				strategies = {
					chat = { adapter = "deepseek" },
					inline = { adapter = "copilot" },
					cmd = { adapter = "deepseek" },
				},
				extensions = {
					mcphub = {
						callback = "mcphub.extensions.codecompanion",
						opts = {
							make_vars = true,
							make_slash_commands = true,
							show_result_in_chat = true,
						},
					},
				},
			})
		end,
	},
}
