return {
	{
		"rebelot/heirline.nvim",
		event = "VeryLazy",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"neovim/nvim-lspconfig",
			"lewis6991/gitsigns.nvim",
			"monkoose/neocodeium",
			"catppuccin/nvim",
		},
		config = function()
			local heirline = require("heirline")
			local conditions = require("heirline.conditions")
			local devicons = require("nvim-web-devicons")
			local colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")

			-- Helper components
			local Align = { provider = "%=" }
			local Space = { provider = " " }

			-- Mode component
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
					return mode_map[vim.fn.mode()] or ("󰜅 " .. vim.fn.mode())
				end,
				hl = { fg = colors.blue, bold = true },
				update = { "ModeChanged" },
			}

			-- File name component
			local FileName = {
				provider = function()
					local filename = vim.fn.expand("%:t")
					if filename == "" then
						return "󰈔 [No Name]"
					end
					local icon = devicons.get_icon(filename, vim.fn.expand("%:e"), { default = true }) or "󰈔"
					return icon .. " " .. filename .. (vim.bo.modified and " 󰜄" or "")
				end,
				hl = { fg = colors.text },
			}

			-- Git component
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
						table.insert(parts, "󰐕 " .. stats.added)
					end
					if stats.changed and stats.changed > 0 then
						table.insert(parts, "󰦒 " .. stats.changed)
					end
					if stats.removed and stats.removed > 0 then
						table.insert(parts, "󰍴 " .. stats.removed)
					end
					return "󰊢 " .. head .. (#parts > 0 and " | " .. table.concat(parts, " ") or "")
				end,
				hl = { fg = colors.peach },
				update = { "User", pattern = "GitSignsUpdate" },
			}

			-- Diagnostics component
			local Diagnostics = {
				condition = conditions.has_diagnostics,
				provider = function()
					local diags = {}
					local icon_map = {
						[vim.diagnostic.severity.ERROR] = "󰅚 ",
						[vim.diagnostic.severity.WARN] = "󰀪 ",
						[vim.diagnostic.severity.INFO] = "󰋽 ",
						[vim.diagnostic.severity.HINT] = "󰌶 ",
					}
					for sev, icon in pairs(icon_map) do
						local count = #vim.diagnostic.get(0, { severity = sev })
						if count > 0 then
							table.insert(diags, icon .. count)
						end
					end
					return #diags > 0 and table.concat(diags, " ") or ""
				end,
				hl = { fg = colors.red },
				update = { "DiagnosticChanged" },
			}

			-- NeoCodeium component
			local NeoCodeium = {
				static = {
					status_icons = {
						[0] = "󰬫 ",
						[1] = "󰚛 ",
						[2] = "󰓅 ",
						[3] = "󰓅 ",
						[4] = "󰓅 ",
						[5] = "󰚠 ",
						[6] = "󰚠 ",
					},
					server_icons = {
						[0] = "󰖟 ",
						[1] = "󰠕 ",
						[2] = "󰲜 ",
					},
				},
				provider = function(self)
					local status, server = require("neocodeium").get_status()
					return (self.status_icons[status] or "") .. (self.server_icons[server] or "")
				end,
				hl = { fg = colors.yellow },
				update = {
					"User",
					pattern = {
						"NeoCodeiumEnabled",
						"NeoCodeiumDisabled",
						"NeoCodeiumServerConnected",
						"NeoCodeiumServerStopped",
						"NeoCodeiumBufEnabled",
						"NeoCodeiumBufDisabled",
					},
				},
			}

			-- LSP clients component
			local LSPClients = {
				condition = conditions.lsp_attached,
				provider = function()
					local clients = {}
					for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
						if client.name ~= "null-ls" then
							clients[client.name] = true
						end
					end
					local names = vim.tbl_keys(clients)
					return #names > 0 and ("󰒋 " .. table.concat(names, ", ")) or ""
				end,
				hl = { fg = colors.mauve },
				update = { "LspAttach", "LspDetach" },
			}

			-- Filetype and encoding component
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
			local Location = {
				provider = function()
					local line = vim.fn.line(".")
					local col = vim.fn.virtcol(".")
					local pct = math.floor(line / vim.fn.line("$") * 100)
					return string.format("󰍎 %d:%-2d | %d%%", line, col, pct)
				end,
				hl = { fg = colors.green, italic = true },
			}

			-- Statusline setup
			heirline.setup({
				statusline = {
					Mode,
					Space,
					FileName,
					Space,
					Git,
					Space,
					Diagnostics,
					Space,
					NeoCodeium,
					Space,
					Align,
					LSPClients,
					{ provider = " | " },
					FileTypeEncoding,
					Space,
					Location,
				},
			})

			-- Autocommand for statusline redraw
			vim.api.nvim_create_autocmd({ "BufEnter", "User", "DiagnosticChanged", "LspAttach", "LspDetach" }, {
				pattern = {
					"GitSignsUpdate",
					"NeoCodeiumEnabled",
					"NeoCodeiumDisabled",
					"NeoCodeiumServerConnected",
					"NeoCodeiumServerStopped",
					"NeoCodeiumBufEnabled",
					"NeoCodeiumBufDisabled",
					"DiagnosticChanged",
					"LspAttach",
					"LspDetach",
				},
				callback = function()
					vim.cmd.redrawstatus()
				end,
			})
		end,
	},
}
