return {
	{
		"CopilotC-Nvim/CopilotChat.nvim",
		dependencies = {
			{ "zbirenbaum/copilot.lua" },
			{ "nvim-lua/plenary.nvim", branch = "master" },
		},
		build = "make tiktoken",
		opts = {}, -- Preserve default configuration
		keys = {
			-- Core chat interactions
			{ "<leader>ac", "<cmd>CopilotChat<CR>", desc = "Open Copilot Chat", mode = { "n", "v" } },
			{ "<leader>at", "<cmd>CopilotChatToggle<CR>", desc = "Toggle Copilot Chat", mode = "n" },
			{ "<leader>ar", "<cmd>CopilotChatReset<CR>", desc = "Reset Copilot Chat", mode = "n" },
			-- Prompt and selection utilities
			{ "<leader>ap", "<cmd>CopilotChatPrompts<CR>", desc = "Select Prompt", mode = "n" },
			{ "<leader>am", "<cmd>CopilotChatModels<CR>", desc = "Select Model", mode = "n" },
			{ "<leader>aa", "<cmd>CopilotChatAgents<CR>", desc = "Select Agent", mode = "n" },
		},
	},
}
