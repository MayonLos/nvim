return {
	{
		"rebelot/heirline.nvim",
		event = "VeryLazy",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"neovim/nvim-lspconfig",
			"lewis6991/gitsigns.nvim",
			"catppuccin/nvim",
		},
		config = function()
			local conditions = require("heirline.conditions")
			local devicons = require("nvim-web-devicons")
			local palette = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")

			-- Helpers
			local Align = { provider = "%=" }
			local Space = { provider = " " }

			-- Mode indicator
			local Mode = {
				provider = function()
					local modes = {
						n = " NORMAL",
						i = " INSERT",
						v = "󰒅 VISUAL",
						V = "󰒅 V-LINE",
						[""] = "󰒅 V-BLOCK",
						c = "󰞷 COMMAND",
						R = "󰏤 REPLACE",
						t = "󰓫 TERM",
					}
					return modes[vim.fn.mode()] or vim.fn.mode():upper()
				end,
				hl = { fg = palette.blue, bold = true },
				update = { "ModeChanged" },
			}

			-- File info
			local FileName = {
				provider = function()
					local name = vim.fn.expand("%:t")
					if name == "" then
						return "[No Name]"
					end
					local icon = devicons.get_icon(name, vim.fn.expand("%:e"), { default = true })
					return (icon or "󰈔") .. " " .. name .. (vim.bo.modified and " ●" or "")
				end,
				hl = { fg = palette.text },
			}

			-- Git status
			local Git = {
				condition = conditions.is_git_repo,
				provider = function()
					local s = vim.b.gitsigns_status_dict or {}
					local parts = {}
					if s.head then
						table.insert(parts, " " .. s.head)
					end
					if s.added and s.added > 0 then
						table.insert(parts, "+" .. s.added)
					end
					if s.changed and s.changed > 0 then
						table.insert(parts, "~" .. s.changed)
					end
					if s.removed and s.removed > 0 then
						table.insert(parts, "-" .. s.removed)
					end
					return table.concat(parts, " ")
				end,
				hl = { fg = palette.peach },
			}

			-- Diagnostics
			local Diagnostics = {
				condition = conditions.has_diagnostics,
				provider = function()
					local icons = { E = "󰅚", W = "󰀪", I = "󰋽", H = "󰌶" }
					local msgs = {}
					for key, icon in pairs(icons) do
						local count = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity[key] })
						if count > 0 then
							table.insert(msgs, icon .. count)
						end
					end
					return table.concat(msgs, " ")
				end,
				hl = { fg = palette.red },
				update = { "DiagnosticChanged" },
			}

			-- LSP clients
			local LSPClients = {
				condition = conditions.lsp_attached,
				provider = function()
					local clients = vim.lsp.get_clients({ bufnr = 0 })
					local names = vim.tbl_map(
						function(c)
							return c.name
						end,
						vim.tbl_filter(function(c)
							return c.name ~= "null-ls"
						end, clients)
					)
					return #names > 0 and " " .. table.concat(names, ", ") or ""
				end,
				hl = { fg = palette.mauve },
				update = { "LspAttach", "LspDetach" },
			}

			-- File type / encoding / format
			local FileInfo = {
				provider = function()
					return table.concat(
						{ vim.bo.filetype or "noft", vim.bo.fileencoding or "utf-8", vim.bo.fileformat },
						"|"
					)
				end,
				hl = { fg = palette.text },
			}

			-- Ruler
			local Ruler = { provider = "%l/%L:%c", hl = { fg = palette.text } }

			-- Scrollbar
			local ScrollBar = {
				static = { sbar = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" } },
				provider = function(self)
					local line = vim.api.nvim_win_get_cursor(0)[1]
					local total = vim.api.nvim_buf_line_count(0)
					local idx = math.floor((line - 1) / total * #self.sbar) + 1
					return string.rep(self.sbar[idx], 2)
				end,
				hl = { fg = palette.blue },
			}

			-- Build statusline
			require("heirline").setup({
				statusline = {
					Mode,
					Space,
					FileName,
					Space,
					Git,
					Space,
					Diagnostics,
					Align,
					LSPClients,
					Space,
					FileInfo,
					Space,
					Ruler,
					Space,
					ScrollBar,
				},
				opts = { colors = palette },
			})
		end,
	},
}
