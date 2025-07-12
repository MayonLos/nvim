return {
	"Bekaboo/dropbar.nvim",
	event = { "BufReadPost", "BufNewFile" },
	config = function(_, opts)
		local dropbar_api = require("dropbar.api")
		-- Define keymaps
		local keymaps = {
			{ "n", "<Leader>;", dropbar_api.pick, "Pick symbols in winbar" },
			{ "n", "[;", dropbar_api.goto_context_start, "Go to start of current context" },
			{ "n", "];", dropbar_api.select_next_context, "Select next context" },
		}

		-- Set keymaps
		for _, map in ipairs(keymaps) do
			vim.keymap.set(map[1], map[2], map[3], { desc = map[4], noremap = true, silent = true })
		end

		-- Setup dropbar with provided options
		require("dropbar").setup(opts)
	end,
}
