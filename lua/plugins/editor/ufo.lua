return {
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "kevinhwang91/promise-async" },
		event = "BufReadPost",
		config = function()
			vim.o.foldcolumn = "0"
			vim.o.foldlevel = 99
			vim.o.foldlevelstart = 99
			vim.o.foldenable = true

			require("ufo").setup({
				open_fold_hl_timeout = 150,
				provider_selector = function(_, filetype, buftype)
					return { "lsp", "indent" }
				end,
				close_fold_kinds_for_ft = {
					default = { "imports", "comment" },
					lua = { "comment" },
					json = { "array" },
				},
				close_fold_current_line_for_ft = {
					default = false,
				},
				preview = {
					win_config = {
						border = "rounded",
						winblend = 8,
						winhighlight = "Normal:Normal",
						maxheight = 20,
					},
				},
				fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
					local newVirtText = {}
					local suffix = (" 󰁂 %d lines"):format(endLnum - lnum)
					local sufWidth = vim.fn.strdisplaywidth(suffix)
					local targetWidth = width - sufWidth
					local curWidth = 0
					for _, chunk in ipairs(virtText) do
						local chunkText = chunk[1]
						local chunkWidth = vim.fn.strdisplaywidth(chunkText)
						if targetWidth > curWidth + chunkWidth then
							table.insert(newVirtText, chunk)
						else
							chunkText = truncate(chunkText, targetWidth - curWidth)
							table.insert(newVirtText, { chunkText, chunk[2] })
							break
						end
						curWidth = curWidth + chunkWidth
					end
					table.insert(newVirtText, { suffix, "MoreMsg" })
					return newVirtText
				end,
			})

			-- Key mappings for fold operations
			local map = vim.keymap.set
			map("n", "zR", require("ufo").openAllFolds, { desc = "Open All Folds" })
			map("n", "zM", require("ufo").closeAllFolds, { desc = "Close All Folds" })
			map("n", "zr", require("ufo").openFoldsExceptKinds, { desc = "Open Folds (except kinds)" })
			map("n", "zm", require("ufo").closeFoldsWith, { desc = "Close Folds With Level" })
			map("n", "K", function()
				local winid = require("ufo").peekFoldedLinesUnderCursor()
				if not winid then
					vim.lsp.buf.hover()
				end
			end, { desc = "Peek Fold or Hover" })
		end,
	},
}
