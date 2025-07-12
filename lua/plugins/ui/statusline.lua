return {
	{
		"rebelot/heirline.nvim",

		event = { "BufReadPost", "BufNewFile" },
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"neovim/nvim-lspconfig",
			"lewis6991/gitsigns.nvim",
			"catppuccin/nvim",
		},
		config = function()
			local conditions = require("heirline.conditions")
			local utils = require("heirline.utils")
			local devicons = require("nvim-web-devicons")
			local colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")

			-- Utility components
			local Align = { provider = "%=" }
			local Space = { provider = " " }

			-- Mode component with streamlined mode mapping
			local Mode = {
				provider = function()
					local mode_map = {
						n = " NORMAL",
						i = " INSERT",
						v = "󰒅 VISUAL",
						V = "󰒅 V-LINE",
						[""] = "󰒅 V-BLOCK",
						c = "󰞷 COMMAND",
						R = "󰏤 REPLACE",
						t = "󰓫 TERM",
						s = "󰒅 SELECT",
						S = "󰒅 S-LINE",
					}
					return mode_map[vim.fn.mode()] or ("󰜅 " .. vim.fn.mode():upper())
				end,
				hl = { fg = colors.blue, bold = true },
				update = { "ModeChanged" },
			}

			-- File name component with icon and modification indicator
			local FileName = {
				provider = function()
					local filename = vim.fn.expand("%:t")
					if filename == "" then
						return "󰈔 [No Name]"
					end
					local icon = devicons.get_icon(filename, vim.fn.expand("%:e"), { default = true }) or "󰈔"
					return string.format("%s %s%s", icon, filename, vim.bo.modified and " 󰜄" or "")
				end,
				hl = { fg = colors.text },
			}

			-- Git status component
			local Git = {
				condition = conditions.is_git_repo,
				provider = function()
					local head = vim.b.gitsigns_head or ""
					if head == "" then
						return ""
					end
					local stats = vim.b.gitsigns_status_dict or {}
					local parts = {}
					if stats.added and stats.added > 0 then
						parts[#parts + 1] = "󰐕 " .. stats.added
					end
					if stats.changed and stats.changed > 0 then
						parts[#parts + 1] = "󰦒 " .. stats.changed
					end
					if stats.removed and stats.removed > 0 then
						parts[#parts + 1] = "󰍴 " .. stats.removed
					end
					return string.format("󰊢 %s%s", head, #parts > 0 and " | " .. table.concat(parts, " ") or "")
				end,
				hl = { fg = colors.peach },
				update = { "User", pattern = "GitSignsUpdate" },
			}

			-- Diagnostics component with severity icons
			local Diagnostics = {
				condition = conditions.has_diagnostics,
				provider = function()
					local icon_map = {
						[vim.diagnostic.severity.ERROR] = "󰅚 ",
						[vim.diagnostic.severity.WARN] = "󰀪 ",
						[vim.diagnostic.severity.INFO] = "󰋽 ",
						[vim.diagnostic.severity.HINT] = "󰌶 ",
					}
					local diags = {}
					for sev, icon in pairs(icon_map) do
						local count = #vim.diagnostic.get(0, { severity = sev })
						if count > 0 then
							diags[#diags + 1] = icon .. count
						end
					end
					return #diags > 0 and table.concat(diags, " ") or ""
				end,
				hl = { fg = colors.red },
				update = { "DiagnosticChanged" },
			}

			-- LSP clients component, filtering out null-ls
			local LSPClients = {
				condition = conditions.lsp_attached,
				provider = function()
					local clients = {}
					for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
						if client.name ~= "null-ls" then
							clients[#clients + 1] = client.name
						end
					end
					return #clients > 0 and ("󰒋 " .. table.concat(clients, ", ")) or ""
				end,
				hl = { fg = colors.mauve },
				update = { "LspAttach", "LspDetach" },
			}

			-- Filetype, encoding, and format component
			local FileTypeEncoding = {
				provider = function()
					local ft = vim.bo.filetype
					local enc = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or "utf-8"
					local ff = vim.bo.fileformat
					return string.format("󰈔 %s |  %s | ↵ %s", ft, enc, ff)
				end,
				hl = { fg = colors.text },
			}

			-- Cursor position component
			local Ruler = {
				provider = "󰍎%7(%l/%3L%):%2c %P",
				hl = { fg = colors.text },
			}

			-- Scrollbar component
			local ScrollBar = {
				static = {
					sbar = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" },
				},
				provider = function(self)
					local curr_line = vim.api.nvim_win_get_cursor(0)[1]
					local lines = vim.api.nvim_buf_line_count(0)
					local i = math.floor((curr_line - 1) / lines * #self.sbar) + 1
					return string.rep(self.sbar[i], 2)
				end,
				hl = { fg = colors.blue },
			}

			-- Statusline definition
			local StatusLine = {
				hl = function()
					return conditions.is_active() and "StatusLine" or "StatusLineNC"
				end,
				Mode,
				Space,
				FileName,
				Space,
				Git,
				Space,
				Diagnostics,
				Space,
				Align,
				LSPClients,
				{ provider = " | " },
				FileTypeEncoding,
				Space,
				Ruler,
				Space,
				ScrollBar,
			}

			-- Setup Heirline with the defined statusline
			require("heirline").setup({
				statusline = StatusLine,
				opts = {
					colors = colors,
				},
			})

			-- Autocommand group for statusline updates
			local group = vim.api.nvim_create_augroup("Heirline", { clear = true })

			vim.api.nvim_create_autocmd({ "User", "DiagnosticChanged", "LspAttach", "LspDetach" }, {
				pattern = { "GitSignsUpdate", "DiagnosticChanged", "LspAttach", "LspDetach" },
				group = group,
				callback = vim.schedule_wrap(function()
					vim.cmd.redrawstatus()
				end),
			})

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "*",
				group = group,
				callback = function()
					if vim.tbl_contains({ "wipe", "delete" }, vim.bo.bufhidden) then
						vim.bo.buflisted = false
					end
				end,
			})
		end,
	},
}
