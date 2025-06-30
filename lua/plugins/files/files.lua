return {
	"echasnovski/mini.files",
	version = false,
	keys = {
		{
			"<leader>fm",
			function()
				local mini_files = require("mini.files")
				if not mini_files.close() then
					local buf_path = vim.api.nvim_buf_get_name(0)

					if buf_path:match("^%a+://") or buf_path == "" then
						mini_files.open(vim.fn.getcwd())
					elseif vim.fn.isdirectory(buf_path) == 1 then
						mini_files.open(buf_path)
					else
						mini_files.open(vim.fn.fnamemodify(buf_path, ":p:h"), true)
					end
				end
			end,
			desc = "Toggle file explorer (smart path)",
		},
	},
	config = function()
		local mini_files = require("mini.files")
		mini_files.setup({
			windows = {
				preview = false,
				width_focus = 40,
				width_nofocus = 20,
				width_preview = 0,
			},
			options = {
				use_as_default_explorer = true,
				permanent_delete = false,
				content_hooks = {
					function(content, ctx)
						if #content.files == 0 and ctx.directory ~= nil then
							table.insert(content.files, {
								path = ctx.directory,
								name = "(empty directory)",
								fs_type = "directory",
								size = 0,
								modified = 0,
							})
						end
						return content
					end,
				},
			},
		})

		vim.api.nvim_create_autocmd("FileType", {
			pattern = "minifiles",
			callback = function()
				local map = function(lhs, rhs)
					vim.keymap.set("n", lhs, rhs, { buffer = true, nowait = true })
				end

				map("<Esc>", mini_files.close)
				map("q", mini_files.close)

				map("-", function()
					local current_path = mini_files.get_fs_state().cwd
					local parent_path = vim.fn.fnamemodify(current_path, ":h")
					mini_files.open(parent_path)
				end)

				map("<C-r>", function()
					local current_path = mini_files.get_fs_state().cwd
					mini_files.open(current_path)
				end)
			end,
		})
	end,
}
