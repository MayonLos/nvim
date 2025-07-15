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
			local colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")

			local Align = { provider = "%=" }
			local Space = { provider = " " }

			local Mode = {
				provider = function()
					local mode_map = {
						n = " NORMAL",
						i = " INSERT",
						v = "󰒅 VISUAL",
						V = "󰒅 V-LINE",
						["\22"] = "󰒅 V-BLOCK",
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

			local FileName = {
				provider = function()
					local filename = vim.fn.expand("%:t")
					if filename == "" then
						return "󰈔 [No Name]"
					end
					local icon = devicons.get_icon(filename, vim.fn.expand("%:e"), { default = true })
						or "󰈔"
					return string.format("%s %s%s", icon, filename, vim.bo.modified and " 󰜄" or "")
				end,
				hl = { fg = colors.text },
			}

			local Git = {
				condition = conditions.is_git_repo,
				init = function(self)
					self.head = vim.b.gitsigns_head or ""
					local stats = vim.b.gitsigns_status_dict or {}
					self.added = stats.added or 0
					self.changed = stats.changed or 0
					self.removed = stats.removed or 0
				end,
				provider = function(self)
					if self.head == "" then
						return ""
					end

					local parts = {}

					if self.added > 0 then
						table.insert(parts, "%#" .. "GitAdded" .. "# " .. self.added .. "%*")
					end

					if self.changed > 0 then
						table.insert(parts, "%#" .. "GitChanged" .. "# " .. self.changed .. "%*")
					end

					if self.removed > 0 then
						table.insert(parts, "%#" .. "GitRemoved" .. "# " .. self.removed .. "%*")
					end

					local stats_str = ""
					if #parts > 0 then
						stats_str = " | " .. table.concat(parts, " ")
					end

					return string.format(" %s%s", self.head, stats_str)
				end,
				hl = { fg = colors.peach, bold = true },
				update = { "User", pattern = "GitSignsUpdate" },
			}
			local Diagnostics = {
				condition = conditions.has_diagnostics,
				init = function(self)
					self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
					self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
					self.infos = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
					self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
				end,
				static = {
					icons = {
						error = "󰅚 ",
						warn = "󰀪 ",
						info = "󰋽 ",
						hint = "󰌶 ",
					},
				},
				update = { "DiagnosticChanged", "BufEnter" },
				{
					provider = function(self)
						return self.errors > 0 and (self.icons.error .. self.errors .. " ") or ""
					end,
					hl = { fg = colors.red },
				},
				{
					provider = function(self)
						return self.warnings > 0 and (self.icons.warn .. self.warnings .. " ") or ""
					end,
					hl = { fg = colors.yellow },
				},
				{
					provider = function(self)
						return self.infos > 0 and (self.icons.info .. self.infos .. " ") or ""
					end,
					hl = { fg = colors.blue },
				},
				{
					provider = function(self)
						return self.hints > 0 and (self.icons.hint .. self.hints) or ""
					end,
					hl = { fg = colors.mauve },
				},
			}

			local LSPClients = {
				condition = conditions.lsp_attached,
				init = function(self)
					local clients = {}
					for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
						if client.name ~= "null-ls" then
							table.insert(clients, client.name)
						end
					end
					self.clients = clients
				end,
				static = {
					max_len = 30,
					icon = "",
				},
				hl = { fg = colors.mauve, bold = true },
				provider = function(self)
					if #self.clients == 0 then
						return ""
					end
					local text = table.concat(self.clients, ", ")
					if #text > self.max_len then
						text = text:sub(1, self.max_len - 3) .. "..."
					end
					return string.format(" %s %s", self.icon, text)
				end,
				update = { "LspAttach", "LspDetach" },
			}

			local FileEncoding = {
				provider = function()
					local enc = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or "utf-8"
					return " " .. enc
				end,
				hl = { fg = colors.overlay2 },
			}

			local Ruler = {
				init = function(self)
					local row, col = unpack(vim.api.nvim_win_get_cursor(0))
					local lines = vim.api.nvim_buf_line_count(0)
					self.row = row
					self.col = col + 1
					self.lines = lines
					self.percent = math.floor((row / lines) * 100)
				end,
				hl = { fg = colors.text, bold = true },
				flexible = 1,
				{
					provider = function(self)
						return string.format("󰍎 %d/%d", self.row, self.lines)
					end,
					hl = { fg = colors.blue, bold = true },
				},
				{
					provider = function(self)
						return string.format(" :%d ", self.col)
					end,
					hl = { fg = colors.mauve },
				},
				{
					provider = function(self)
						return string.format("%d%%%%", self.percent)
					end,
					hl = { fg = colors.green },
				},
			}

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
				FileEncoding,
				Space,
				Ruler,
				Space,
				ScrollBar,
			}

			require("heirline").setup({
				statusline = StatusLine,
			})

			vim.api.nvim_create_autocmd("FileType", {
				pattern = "*",
				group = vim.api.nvim_create_augroup("Heirline", { clear = true }),
				callback = function()
					if vim.tbl_contains({ "wipe", "delete" }, vim.bo.bufhidden) then
						vim.bo.buflisted = false
					end
				end,
			})
		end,
	},
}
