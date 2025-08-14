return {
	"lervag/vimtex",
	lazy = false,
	init = function()
		vim.g.vimtex_mappings_enabled = false
		vim.g.vimtex_view_method = "zathura"
		local augroup = vim.api.nvim_create_augroup("vimtexConfig", {})
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "tex",
			group = augroup,
			callback = function(event)
				local wk = require "which-key"
				wk.add {
					buffer = event.buf,
				}
			end,
		})
	end,
}
