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
			"MeanderingProgrammer/render-markdown.nvim",
			"sindrets/diffview.nvim",
			"zbirenbaum/copilot.lua",
		},
		config = function()
			local adapters = require("codecompanion.adapters")
			local cc = require("codecompanion")

			-- 定义 Deepseek 适配器
			local function setup_deepseek()
				return adapters.extend("deepseek", {
					env = { api_key = os.getenv("DEEPSEEK_API_KEY") },
				})
			end

			-- CodeCompanion 主设置
			cc.setup({
				adapters = {
					deepseek = setup_deepseek,
				},
				strategies = {
					chat = { adapter = "copilot" },
					cmd = { adapter = "deepseek" },
					inline = { adapter = "copilot" },
					act = { adapter = "deepseek" },
				},
				display = {
					chat = {
						window = {
							layout = "float",
							width = 0.4,
							height = 0.4,
							border = "rounded",
							opts = {
								wrap = true,
								breakindent = true,
							},
						},
					},
				},
			})

			-- 配置 Copilot
			require("copilot").setup({
				panel = {
					enabled = true,
					auto_refresh = true,
					keymap = {
						accept = "<C-e>",
						quit = "q",
						jump_next = "<C-n>",
						jump_prev = "<C-p>",
						previous = "<M-p>",
						next = "<M-n>",
					},
					layout = { position = "bottom", ratio = 0.4 },
				},
				suggestion = {
					enabled = false,
					auto_trigger = false,
					debounce = 75,
					keymap = {
						accept = "<M-CR>",
						accept_word = "<M-M>",
						accept_line = "<M-L>",
						next = "<M-]>",
						prev = "<M-[>",
						dismiss = "<C-]>",
					},
				},
				filetypes = { ["*"] = true },
			})
		end,
	},
}
