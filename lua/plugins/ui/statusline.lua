return {
	"echasnovski/mini.statusline",
	version = false,
	event = "VeryLazy",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local statusline = require("mini.statusline")
		local devicons = require("nvim-web-devicons")

		statusline.setup({
			use_icons = true,
			set_vim_settings = false,
			content = {
				active = function()
					local left = table.concat({
						statusline.section_mode(),
						statusline.section_git(),
						statusline.section_diagnostics(),
					}, " 󰇘 ")

					local right = table.concat({
						statusline.section_lsp(),
						statusline.section_location(),
					}, " 󰇘 ")

					return left .. "%=" .. right
				end,

				inactive = function()
					return statusline.section_mode()
				end,
			},
		})

		statusline.section_location = function()
			return string.format(" %d:%d", vim.fn.line("."), vim.fn.virtcol("."))
		end

		statusline.section_mode = function()
			local mode_map = {
				n = "NORMAL",
				i = "INSERT",
				v = "VISUAL",
				V = "V-LINE",
				["\22"] = "V-BLOCK",
				c = "COMMAND",
				R = "REPLACE",
				t = "TERMINAL",
			}
			local mode_code = vim.fn.mode()
			local mode_text = mode_map[mode_code] or mode_code
			return string.format(" %s", mode_text)
		end

		statusline.section_git = function()
			return vim.b.gitsigns_head and (" " .. vim.b.gitsigns_head) or ""
		end

		statusline.section_lsp = function()
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if vim.tbl_isempty(clients) then
				return ""
			end
			local names = {}
			for _, client in ipairs(clients) do
				if client.name ~= "null-ls" then
					table.insert(names, client.name)
				end
			end
			return #names > 0 and (" " .. table.concat(names, ", ")) or ""
		end

		statusline.section_diagnostics = function()
			local errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
			local warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })

			if errors == 0 and warnings == 0 then
				return ""
			end

			local parts = {}
			if errors > 0 then
				table.insert(parts, string.format(" %d", errors))
			end
			if warnings > 0 then
				table.insert(parts, string.format(" %d", warnings))
			end

			return table.concat(parts, " ")
		end
	end,
}
