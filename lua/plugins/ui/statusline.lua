return {
	"echasnovski/mini.statusline",
	version = false,
	event = "VeryLazy",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	config = function()
		local statusline = require("mini.statusline")
		local devicons = require("nvim-web-devicons")

		local function section_file_icon()
			local filename = vim.fn.expand("%:t")
			local ext = vim.fn.expand("%:e")
			local icon = devicons.get_icon(filename, ext, { default = true })
			return icon or ""
		end

		local function section_mode()
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

		local function section_git()
			return vim.b.gitsigns_head and (" " .. vim.b.gitsigns_head) or ""
		end

		local function section_diagnostics()
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

		local function section_lsp()
			local clients = vim.lsp.get_clients({ bufnr = 0 })
			if #clients == 0 then
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

		local function section_location()
			return string.format(" %d:%d", vim.fn.line("."), vim.fn.virtcol("."))
		end

		statusline.setup({
			use_icons = true,
			set_vim_settings = false,
			content = {
				active = function()
					local left_parts = {
						section_mode(),
						section_file_icon(),
						section_git(),
						section_diagnostics(),
					}
					local right_parts = {
						section_lsp(),
						section_location(),
					}
					local left = table.concat(
						vim.tbl_filter(function(v)
							return v ~= ""
						end, left_parts),
						" 󰇘 "
					)
					local right = table.concat(
						vim.tbl_filter(function(v)
							return v ~= ""
						end, right_parts),
						" 󰇘 "
					)
					return left .. "%=" .. right
				end,
				inactive = function()
					return section_mode()
				end,
			},
		})
	end,
}
