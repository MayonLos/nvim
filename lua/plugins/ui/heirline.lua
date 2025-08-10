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
			-- ═══════════════════════════════════════════════════════════════════════
			-- ⚡ CORE IMPORTS & SETUP
			-- ═══════════════════════════════════════════════════════════════════════

			local heirline = require "heirline"
			local conditions = require "heirline.conditions"
			local utils = require "heirline.utils"
			local devicons = require "nvim-web-devicons"
			local colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")

			-- Performance optimizations: cache frequently used APIs
			local api, fn, bo, go = vim.api, vim.fn, vim.bo, vim.go
			local diagnostic = vim.diagnostic

			-- ═══════════════════════════════════════════════════════════════════════
			-- 🛠️  UTILITY FUNCTIONS
			-- ═══════════════════════════════════════════════════════════════════════

			local M = {}

			--- Safe function execution with fallback
			--- @param func function Function to execute
			--- @param fallback any Fallback value on error
			--- @return any result Result or fallback
			M.safe_call = function(func, fallback)
				local ok, result = pcall(func)
				return ok and result or fallback
			end

			--- Check if string is empty or nil
			--- @param str string|nil String to check
			--- @return boolean empty True if empty/nil
			M.is_empty = function(str)
				return not str or str == ""
			end

			--- Get window width with validation
			--- @param winid number Window ID
			--- @return number width Window width or 0
			M.get_win_width = function(winid)
				return M.safe_call(function()
					return api.nvim_win_is_valid(winid) and api.nvim_win_get_width(winid) or 0
				end, 0)
			end

			--- Truncate text with ellipsis
			--- @param str string Text to truncate
			--- @param max_len number Maximum length
			--- @return string truncated Truncated text
			M.truncate = function(str, max_len)
				if #str <= max_len then
					return str
				end
				return str:sub(1, max_len - 3) .. "…"
			end

			--- Get responsive max length based on window width
			--- @param base_len number Base length
			--- @return number length Responsive length
			M.get_responsive_length = function(base_len)
				local cols = vim.o.columns
				if cols < 100 then
					return math.floor(base_len * 0.6)
				elseif cols < 150 then
					return base_len
				else
					return math.floor(base_len * 1.4)
				end
			end

			-- ═══════════════════════════════════════════════════════════════════════
			-- 🎨 PRIMITIVE COMPONENTS
			-- ═══════════════════════════════════════════════════════════════════════

			local Primitives = {
				Space = { provider = " " },
				Spacer = { provider = "  " },
				Align = { provider = "%=" },

				Separator = {
					provider = function()
						return vim.o.columns > 120 and "  │  " or "  "
					end,
					hl = { fg = colors.surface1 },
				},
			}

			-- ═══════════════════════════════════════════════════════════════════════
			-- 🚀 ENHANCED STATUS LINE COMPONENTS
			-- ═══════════════════════════════════════════════════════════════════════

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 📍 Modern Mode Component                                             │
			-- └─────────────────────────────────────────────────────────────────────┘

			local Mode = {
				init = function(self)
					self.mode = fn.mode()
				end,

				static = {
					mode_map = {
						-- Normal modes
						n = { icon = "󰰆", name = "NORMAL", color = colors.blue },

						-- Insert modes
						i = { icon = "󰰅", name = "INSERT", color = colors.green },

						-- Visual modes
						v = { icon = "󰰈", name = "VISUAL", color = colors.mauve },
						V = { icon = "󰰉", name = "V-LINE", color = colors.mauve },
						["\22"] = { icon = "󰰊", name = "V-BLOCK", color = colors.mauve },

						-- Command & Terminal
						c = { icon = "󰞷", name = "COMMAND", color = colors.peach },
						t = { icon = "󰓫", name = "TERMINAL", color = colors.yellow },

						-- Replace modes
						R = { icon = "󰛔", name = "REPLACE", color = colors.red },
						r = { icon = "󰛔", name = "REPLACE", color = colors.red },

						-- Select modes
						s = { icon = "󰒅", name = "SELECT", color = colors.teal },
						S = { icon = "󰒅", name = "S-LINE", color = colors.teal },
						["\19"] = { icon = "󰒅", name = "S-BLOCK", color = colors.teal },

						-- Operator pending
						no = { icon = "󰰇", name = "O-PENDING", color = colors.red },
						nov = { icon = "󰰇", name = "O-PENDING", color = colors.red },
						noV = { icon = "󰰇", name = "O-PENDING", color = colors.red },
						["no\22"] = { icon = "󰰇", name = "O-PENDING", color = colors.red },

						-- Insert normal
						niI = { icon = "󰰅", name = "NORMAL", color = colors.blue },
						niR = { icon = "󰰅", name = "NORMAL", color = colors.blue },
						niV = { icon = "󰰅", name = "NORMAL", color = colors.blue },
						nt = { icon = "󰓫", name = "TERMINAL", color = colors.yellow },
					},
				},

				provider = function(self)
					local mode_info = self.mode_map[self.mode]
						or { icon = "󰜅", name = self.mode:upper(), color = colors.surface1 }
					return string.format("  %s %s  ", mode_info.icon, mode_info.name)
				end,

				hl = function(self)
					local mode_info = self.mode_map[self.mode] or { color = colors.surface1 }
					return {
						fg = colors.base,
						bg = mode_info.color,
						bold = true,
					}
				end,

				update = { "ModeChanged", "BufEnter" },
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 📄 Enhanced File Info Component                                     │
			-- └─────────────────────────────────────────────────────────────────────┘

			local FileInfo = {
				init = function(self)
					self.filename = fn.expand "%:t"
					self.filetype = bo.filetype
					self.modified = bo.modified
					self.readonly = bo.readonly
					self.buftype = bo.buftype
				end,

				-- File icon with dynamic coloring
				{
					provider = function(self)
						if M.is_empty(self.filename) then
							return self.buftype == "terminal" and "󰓫" or "󰈔"
						end
						local icon = devicons.get_icon(self.filename, fn.expand "%:e", { default = true })
						return icon or "󰈔"
					end,

					hl = function(self)
						if self.buftype == "terminal" then
							return { fg = colors.yellow }
						end
						if M.is_empty(self.filename) then
							return { fg = colors.text }
						end
						local _, icon_color =
							devicons.get_icon_color(self.filename, fn.expand "%:e", { default = true })
						return { fg = icon_color or colors.text }
					end,
				},

				Primitives.Space,

				-- Filename with smart truncation
				{
					provider = function(self)
						if M.is_empty(self.filename) then
							return self.buftype == "terminal" and "Terminal" or "[Untitled]"
						end
						return M.truncate(self.filename, M.get_responsive_length(30))
					end,

					hl = function(self)
						local base_hl = { bold = self.modified }
						if self.buftype == "terminal" then
							base_hl.fg = colors.yellow
						elseif self.readonly then
							base_hl.fg = colors.red
						elseif self.modified then
							base_hl.fg = colors.peach
						else
							base_hl.fg = colors.text
						end
						return base_hl
					end,
				},

				-- File status indicators
				{
					provider = function(self)
						local indicators = {}
						if self.modified then
							table.insert(indicators, "󰜄")
						end
						if self.readonly then
							table.insert(indicators, "󰌾")
						end
						if bo.buftype == "help" then
							table.insert(indicators, "󰘥")
						end
						return #indicators > 0 and (" " .. table.concat(indicators, " ")) or ""
					end,

					hl = function(self)
						if self.modified then
							return { fg = colors.green, bold = true }
						elseif self.readonly then
							return { fg = colors.red, bold = true }
						else
							return { fg = colors.blue }
						end
					end,
				},

				update = { "BufModifiedSet", "BufEnter", "BufWritePost", "FileType" },
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 🌿 Modern Git Component                                             │
			-- └─────────────────────────────────────────────────────────────────────┘

			local Git = {
				condition = conditions.is_git_repo,

				init = function(self)
					local gitsigns = vim.b.gitsigns_status_dict
					if gitsigns then
						self.head = vim.b.gitsigns_head or ""
						self.added = gitsigns.added or 0
						self.changed = gitsigns.changed or 0
						self.removed = gitsigns.removed or 0
						self.has_changes = self.added > 0 or self.changed > 0 or self.removed > 0
					else
						self.head = ""
						self.has_changes = false
					end
				end,

				static = {
					icons = {
						branch = "󰘬",
						added = "󰐕",
						changed = "󰜥",
						removed = "󰍴",
					},
				},

				-- Branch name
				{
					condition = function(self)
						return not M.is_empty(self.head)
					end,

					provider = function(self)
						local branch = M.truncate(self.head, M.get_responsive_length(20))
						return string.format(" %s %s", self.icons.branch, branch)
					end,

					hl = { fg = colors.lavender, bold = true },
				},

				-- Git changes
				{
					condition = function(self)
						return self.has_changes
					end,

					provider = function(self)
						local changes = {}
						if self.added > 0 then
							table.insert(changes, string.format("%s%d", self.icons.added, self.added))
						end
						if self.changed > 0 then
							table.insert(changes, string.format("%s%d", self.icons.changed, self.changed))
						end
						if self.removed > 0 then
							table.insert(changes, string.format("%s%d", self.icons.removed, self.removed))
						end
						return " (" .. table.concat(changes, " ") .. ")"
					end,

					hl = { fg = colors.subtext1 },
				},

				update = { "User", pattern = "GitSignsUpdate" },
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 🩺 Enhanced Diagnostics Component                                   │
			-- └─────────────────────────────────────────────────────────────────────┘

			local Diagnostics = {
				condition = conditions.has_diagnostics,

				init = function(self)
					self.errors = #diagnostic.get(0, { severity = diagnostic.severity.ERROR })
					self.warnings = #diagnostic.get(0, { severity = diagnostic.severity.WARN })
					self.infos = #diagnostic.get(0, { severity = diagnostic.severity.INFO })
					self.hints = #diagnostic.get(0, { severity = diagnostic.severity.HINT })
				end,

				static = {
					icons = {
						error = "󰅚",
						warn = "󰀪",
						info = "󰋽",
						hint = "󰌶",
					},
				},

				-- Error diagnostics
				{
					provider = function(self)
						return self.errors > 0 and string.format(" %s %d", self.icons.error, self.errors) or ""
					end,
					hl = { fg = colors.red, bold = true },
				},

				-- Warning diagnostics
				{
					provider = function(self)
						return self.warnings > 0 and string.format(" %s %d", self.icons.warn, self.warnings) or ""
					end,
					hl = { fg = colors.yellow, bold = true },
				},

				-- Info diagnostics
				{
					provider = function(self)
						return self.infos > 0 and string.format(" %s %d", self.icons.info, self.infos) or ""
					end,
					hl = { fg = colors.sky, bold = true },
				},

				-- Hint diagnostics
				{
					provider = function(self)
						return self.hints > 0 and string.format(" %s %d", self.icons.hint, self.hints) or ""
					end,
					hl = { fg = colors.teal, bold = true },
				},

				update = { "DiagnosticChanged", "BufEnter" },
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 🔍 Modern Search Info Component                                     │
			-- └─────────────────────────────────────────────────────────────────────┘

			local SearchInfo = {
				condition = function()
					return vim.v.hlsearch ~= 0 and vim.fn.searchcount().total > 0
				end,

				init = function(self)
					self.search = M.safe_call(fn.searchcount, {})
				end,

				provider = function(self)
					if not self.search or not self.search.total or self.search.total == 0 then
						return ""
					end
					return string.format(" 󰍉 %d/%d ", self.search.current or 0, self.search.total)
				end,

				hl = { fg = colors.peach, bg = colors.surface0, bold = true },
				update = { "CmdlineChanged", "CursorMoved" },
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 🔧 Enhanced LSP Clients Component                                   │
			-- └─────────────────────────────────────────────────────────────────────┘

			local LSPClients = {
				condition = conditions.lsp_attached,

				init = function(self)
					local clients = {}
					for _, client in pairs(vim.lsp.get_clients { bufnr = 0 }) do
						if client.name ~= "null-ls" and client.name ~= "copilot" then
							table.insert(clients, client.name)
						end
					end
					self.clients = clients
				end,

				static = {
					icon = "󰒋",
				},

				provider = function(self)
					if #self.clients == 0 then
						return ""
					end
					local text = table.concat(self.clients, "·")
					text = M.truncate(text, M.get_responsive_length(25))
					return string.format(" %s %s", self.icon, text)
				end,

				hl = { fg = colors.sapphire, bold = true },
				update = { "LspAttach", "LspDetach" },
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 📍 Responsive Position Component                                    │
			-- └─────────────────────────────────────────────────────────────────────┘

			local Position = {
				init = function(self)
					local cursor = api.nvim_win_get_cursor(0)
					local lines = api.nvim_buf_line_count(0)
					self.row = cursor[1]
					self.col = cursor[2] + 1
					self.lines = lines
					self.percent = lines > 0 and math.floor((self.row / lines) * 100) or 0
				end,

				flexible = 1,

				-- Full position info
				{
					{
						provider = function(self)
							return string.format("󰍎 %d:%d", self.row, self.col)
						end,
						hl = { fg = colors.blue, bold = true },
					},
					Primitives.Space,
					{
						provider = function(self)
							return string.format("%d%%", self.percent)
						end,
						hl = { fg = colors.green },
					},
					Primitives.Space,
					{
						provider = function(self)
							return string.format("󰓾 %d", self.lines)
						end,
						hl = { fg = colors.subtext1 },
					},
				},

				-- Medium position info
				{
					{
						provider = function(self)
							return string.format("󰍎 %d:%d", self.row, self.col)
						end,
						hl = { fg = colors.blue, bold = true },
					},
					Primitives.Space,
					{
						provider = function(self)
							return string.format("%d%%", self.percent)
						end,
						hl = { fg = colors.green },
					},
				},

				-- Minimal position info
				{
					provider = function(self)
						return string.format("%d%%", self.percent)
					end,
					hl = { fg = colors.green },
				},
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 📊 Enhanced Scroll Bar Component                                    │
			-- └─────────────────────────────────────────────────────────────────────┘

			local ScrollBar = {
				static = {
					sbar = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" },
				},

				provider = function(self)
					local curr_line = api.nvim_win_get_cursor(0)[1]
					local lines = api.nvim_buf_line_count(0)
					if lines <= 1 then
						return " " .. self.sbar[#self.sbar]
					end
					local i = math.min(math.floor((curr_line - 1) / lines * #self.sbar) + 1, #self.sbar)
					return " " .. self.sbar[i]
				end,

				hl = function()
					local curr_line = api.nvim_win_get_cursor(0)[1]
					local lines = api.nvim_buf_line_count(0)
					local ratio = lines > 0 and curr_line / lines or 0

					if ratio < 0.2 then
						return { fg = colors.green }
					elseif ratio < 0.4 then
						return { fg = colors.yellow }
					elseif ratio < 0.6 then
						return { fg = colors.peach }
					elseif ratio < 0.8 then
						return { fg = colors.mauve }
					else
						return { fg = colors.red }
					end
				end,
			}

			-- ═══════════════════════════════════════════════════════════════════════
			-- 📑 ENHANCED TABLINE COMPONENTS (IMPROVED)
			-- ═══════════════════════════════════════════════════════════════════════

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 📂 Modern Tabline Offset Component                                  │
			-- └─────────────────────────────────────────────────────────────────────┘

			local TablineOffset = {
				condition = function(self)
					local wins = api.nvim_tabpage_list_wins(0)
					if #wins == 0 then
						return false
					end

					local win = wins[1]
					if not api.nvim_win_is_valid(win) then
						return false
					end

					local bufnr = api.nvim_win_get_buf(win)
					local filetype = M.safe_call(function()
						return vim.bo[bufnr].filetype
					end, "")
					local buftype = M.safe_call(function()
						return vim.bo[bufnr].buftype
					end, "")

					self.winid = win

					local sidebars = {
						NvimTree = { title = "󰙅 Files", hl = "NvimTreeNormal", icon_color = colors.green },
						["neo-tree"] = { title = "󰙅 Neo-tree", hl = "NeoTreeNormal", icon_color = colors.green },
						CHADTree = { title = "󰙅 CHAD", hl = "CHADTreeNormal", icon_color = colors.green },
						nerdtree = { title = "󰙅 NERD", hl = "NERDTree", icon_color = colors.green },
						Outline = { title = "󰘬 Outline", hl = "OutlineNormal", icon_color = colors.blue },
						tagbar = { title = "󰤌 Tags", hl = "TagbarNormal", icon_color = colors.blue },
						undotree = { title = "󰄶 Undo", hl = "UndotreeNormal", icon_color = colors.yellow },
						vista = { title = "󰤌 Vista", hl = "VistaNormal", icon_color = colors.blue },
						aerial = { title = "󰤌 Aerial", hl = "AerialNormal", icon_color = colors.blue },
						toggleterm = { title = "󰓫 Term", hl = "ToggleTermNormal", icon_color = colors.peach },
					}

					if sidebars[filetype] then
						self.title = sidebars[filetype].title
						self.hl_group = sidebars[filetype].hl
						self.icon_color = sidebars[filetype].icon_color
						return true
					elseif buftype == "terminal" then
						self.title = "󰓫 Terminal"
						self.hl_group = "StatusLine"
						self.icon_color = colors.yellow
						return true
					end

					return false
				end,

				provider = function(self)
					local width = M.get_win_width(self.winid)
					if width == 0 then
						return ""
					end

					local title = self.title
					local title_len = vim.fn.strdisplaywidth(title)
					local pad = math.max(0, math.floor((width - title_len) / 2))
					local right_pad = math.max(0, width - title_len - pad)

					return string.rep(" ", pad) .. title .. string.rep(" ", right_pad)
				end,

				hl = function(self)
					local is_focused = api.nvim_get_current_win() == self.winid
					return {
						bg = is_focused and colors.surface0 or colors.mantle,
						fg = is_focused and self.icon_color or colors.subtext0,
						bold = is_focused,
					}
				end,

				update = { "WinEnter", "BufEnter", "WinResized" },
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 🎨 Enhanced Tabline File Icon Component                            │
			-- └─────────────────────────────────────────────────────────────────────┘

			local TablineFileIcon = {
				init = function(self)
					self.filename = M.safe_call(function()
						return api.nvim_buf_get_name(self.bufnr)
					end, "")
					self.extension = fn.fnamemodify(self.filename, ":e")
					self.buftype = M.safe_call(function()
						return api.nvim_get_option_value("buftype", { buf = self.bufnr })
					end, "")
				end,

				provider = function(self)
					if self.buftype == "terminal" then
						return "󰓫"
					elseif M.is_empty(self.filename) then
						return "󰈔"
					end
					local icon = devicons.get_icon(self.filename, self.extension, { default = true })
					return icon or "󰈔"
				end,

				hl = function(self)
					if self.buftype == "terminal" then
						return { fg = self.is_active and colors.yellow or colors.overlay1 }
					elseif M.is_empty(self.filename) then
						return { fg = self.is_active and colors.subtext1 or colors.overlay0 }
					end
					local _, icon_color = devicons.get_icon_color(self.filename, self.extension, { default = true })
					local base_color = icon_color or colors.text
					-- Dim inactive tab icons
					if not self.is_active then
						base_color = colors.overlay1
					end
					return { fg = base_color }
				end,
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 📝 Modern Tabline File Name Component                              │
			-- └─────────────────────────────────────────────────────────────────────┘

			local TablineFileName = {
				provider = function(self)
					local buftype = M.safe_call(function()
						return api.nvim_get_option_value("buftype", { buf = self.bufnr })
					end, "")

					if buftype == "terminal" then
						-- Extract terminal name or show generic
						local bufname = M.safe_call(function()
							return api.nvim_buf_get_name(self.bufnr)
						end, "")
						local term_name = bufname:match "term://.*//(%d+):" or "Term"
						return term_name
					end

					local filename = self.filename
					if M.is_empty(filename) then
						return "Untitled"
					end

					filename = fn.fnamemodify(filename, ":t")
					local max_len = M.get_responsive_length(18) -- Slightly shorter for better spacing
					return M.truncate(filename, max_len)
				end,

				hl = function(self)
					return {
						bold = self.is_active,
						italic = not self.is_active,
						fg = self.is_active and colors.text or colors.subtext0,
					}
				end,
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 🏷️  Enhanced Tabline File Flags Component                         │
			-- └─────────────────────────────────────────────────────────────────────┘

			local TablineFileFlags = {
				-- Modified indicator with animation effect
				{
					condition = function(self)
						return M.safe_call(function()
							return api.nvim_get_option_value("modified", { buf = self.bufnr })
						end, false)
					end,
					provider = function(self)
						-- Use different indicators based on activity
						if self.is_active then
							return " ●"
						else
							return " •"
						end
					end,
					hl = function(self)
						return {
							fg = self.is_active and colors.green or colors.overlay2,
							bold = self.is_active,
						}
					end,
				},

				-- Readonly indicator
				{
					condition = function(self)
						local readonly = M.safe_call(function()
							return api.nvim_get_option_value("readonly", { buf = self.bufnr })
						end, false)
						local modifiable = M.safe_call(function()
							return api.nvim_get_option_value("modifiable", { buf = self.bufnr })
						end, true)
						return readonly or not modifiable
					end,
					provider = " 󰌾",
					hl = function(self)
						return {
							fg = self.is_active and colors.red or colors.overlay1,
						}
					end,
				},

				-- Close button (only on active tab and when hovered)
				{
					condition = function(self)
						return self.is_active and vim.o.columns > 100
					end,
					provider = " 󰅖",
					hl = { fg = colors.overlay1 },
					on_click = {
						callback = function(_, minwid)
							vim.schedule(function()
								M.safe_call(function()
									local modified = api.nvim_get_option_value("modified", { buf = minwid })
									if modified then
										local choice =
											fn.confirm("Save changes before closing?", "&Save\n&Discard\n&Cancel")
										if choice == 1 then
											vim.cmd("buffer " .. minwid)
											vim.cmd "write"
											api.nvim_buf_delete(minwid, {})
										elseif choice == 2 then
											api.nvim_buf_delete(minwid, { force = true })
										end
									else
										api.nvim_buf_delete(minwid, {})
									end
									vim.cmd.redrawtabline()
								end)
							end)
						end,
						minwid = function(self)
							return self.bufnr
						end,
						name = "heirline_tabline_close",
					},
				},
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 🎯 Enhanced Tabline Picker Component                               │
			-- └─────────────────────────────────────────────────────────────────────┘

			local TablinePicker = {
				condition = function(self)
					return self._show_picker
				end,

				init = function(self)
					local bufname = M.safe_call(function()
						return api.nvim_buf_get_name(self.bufnr)
					end, "")

					bufname = fn.fnamemodify(bufname, ":t")
					if M.is_empty(bufname) then
						bufname = "untitled"
					end

					local label = bufname:sub(1, 1):upper()
					local i = 2
					while self._picker_labels[label] and i <= #bufname do
						label = bufname:sub(i, i):upper()
						i = i + 1
					end

					if self._picker_labels[label] then
						local num = 1
						while self._picker_labels[tostring(num)] do
							num = num + 1
						end
						label = tostring(num)
					end

					self._picker_labels[label] = self.bufnr
					self.label = label
				end,

				provider = function(self)
					return string.format(" [%s] ", self.label)
				end,

				hl = {
					fg = colors.base,
					bg = colors.red,
					bold = true,
				},
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 📄 Modern Tabline File Name Block                                  │
			-- └─────────────────────────────────────────────────────────────────────┘

			local TablineFileNameBlock = {
				init = function(self)
					self.filename = M.safe_call(function()
						return api.nvim_buf_get_name(self.bufnr)
					end, "")
				end,

				hl = function(self)
					if self.is_active then
						return {
							bg = colors.surface0,
							fg = colors.text,
						}
					elseif self.is_visible then
						return {
							bg = colors.surface1,
							fg = colors.subtext1,
						}
					else
						return {
							bg = colors.mantle,
							fg = colors.subtext0,
						}
					end
				end,

				on_click = {
					callback = function(_, minwid, _, button)
						vim.schedule(function()
							M.safe_call(function()
								if button == "m" then -- Middle click to close
									local modified = api.nvim_get_option_value("modified", { buf = minwid })
									if modified then
										local choice =
											fn.confirm("Save changes before closing?", "&Save\n&Discard\n&Cancel")
										if choice == 1 then
											vim.cmd("buffer " .. minwid)
											vim.cmd "write"
											api.nvim_buf_delete(minwid, {})
										elseif choice == 2 then
											api.nvim_buf_delete(minwid, { force = true })
										end
									else
										api.nvim_buf_delete(minwid, {})
									end
								else -- Left click to switch
									api.nvim_win_set_buf(0, minwid)
								end
								vim.cmd.redrawtabline()
							end)
						end)
					end,
					minwid = function(self)
						return self.bufnr
					end,
					name = "heirline_tabline_buffer_callback",
				},

				{ provider = " " },
				TablineFileIcon,
				{ provider = " " },
				TablineFileName,
				TablineFileFlags,
				{ provider = " " },
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 📊 Beautiful Tabline Buffer Block with Separators                  │
			-- └─────────────────────────────────────────────────────────────────────┘

			local TablineBufferBlock = {
				TablinePicker,
				utils.surround(
					{ "", "" }, -- Modern rounded separators
					function(self)
						if self.is_active then
							return colors.blue
						elseif self.is_visible then
							return colors.surface2
						else
							return colors.surface1
						end
					end,
					{
						TablineFileNameBlock,
					}
				),
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 📋 Enhanced Buffer Management System                               │
			-- └─────────────────────────────────────────────────────────────────────┘

			local buflist_cache = {}
			local buffer_positions = {} -- Track buffer positions for animations

			--- Get filtered buffer list with enhanced filtering
			--- @return table buffers List of valid buffer numbers
			local function get_bufs()
				return M.safe_call(function()
					local excluded_filetypes = {
						"help",
						"alpha",
						"dashboard",
						"NvimTree",
						"neo-tree",
						"Trouble",
						"lir",
						"Outline",
						"spectre_panel",
						"toggleterm",
						"TelescopePrompt",
						"lazy",
						"mason",
						"notify",
						"noice",
						"aerial",
						"qf",
						"fugitive",
						"gitcommit",
						"startuptime",
						"lspinfo",
						"checkhealth",
						"DressingInput",
					}

					local excluded_buftypes = {
						"quickfix",
						"help",
						"nofile",
						"prompt",
					}

					local buffers = vim.tbl_filter(function(bufnr)
						if not api.nvim_buf_is_valid(bufnr) then
							return false
						end

						local buftype = api.nvim_get_option_value("buftype", { buf = bufnr })
						local filetype = api.nvim_get_option_value("filetype", { buf = bufnr })
						local buflisted = api.nvim_get_option_value("buflisted", { buf = bufnr })
						local bufname = api.nvim_buf_get_name(bufnr)

						-- Allow terminal buffers
						if buftype == "terminal" then
							return buflisted
						end

						-- Exclude unwanted buftypes
						if vim.tbl_contains(excluded_buftypes, buftype) then
							return false
						end

						-- Exclude unwanted filetypes
						if vim.tbl_contains(excluded_filetypes, filetype) then
							return false
						end

						-- Exclude special buffers
						if bufname:match "^%w+://" then
							return false
						end

						return buflisted and buftype == ""
					end, api.nvim_list_bufs())

					-- Sort buffers by last access time for better UX
					table.sort(buffers, function(a, b)
						local a_last = api.nvim_buf_get_var(a, "heirline_last_access") or 0
						local b_last = api.nvim_buf_get_var(b, "heirline_last_access") or 0
						return a_last > b_last
					end)

					return buffers
				end, {})
			end

			-- Track buffer access for intelligent sorting
			local function track_buffer_access(bufnr)
				M.safe_call(function()
					if api.nvim_buf_is_valid(bufnr) then
						api.nvim_buf_set_var(bufnr, "heirline_last_access", vim.loop.now())
					end
				end)
			end

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 📑 Enhanced Buffer Line Component                                   │
			-- └─────────────────────────────────────────────────────────────────────┘

			local BufferLine = {
				TablineOffset,

				-- Add a subtle separator after offset
				{
					condition = function()
						return vim.o.columns > 80
					end,
					provider = "▏",
					hl = { fg = colors.surface2 },
				},

				utils.make_buflist(
					TablineBufferBlock,
					{
						provider = " 󰍞 ",
						hl = { fg = colors.overlay1, bg = colors.mantle },
					}, -- Left truncation indicator
					{
						provider = " 󰍟 ",
						hl = { fg = colors.overlay1, bg = colors.mantle },
					}, -- Right truncation indicator
					function()
						return buflist_cache
					end,
					false -- Don't cache (we handle it manually)
				),

				-- Right side padding and additional info
				{ provider = "%=" }, -- Right align

				-- Show buffer count when there are multiple buffers
				{
					condition = function()
						return #buflist_cache > 1 and vim.o.columns > 100
					end,
					provider = function()
						return string.format(" %d buffers ", #buflist_cache)
					end,
					hl = {
						fg = colors.subtext0,
						bg = colors.mantle,
						italic = true,
					},
				},
			}

			-- ═══════════════════════════════════════════════════════════════════════
			-- 🎯 MAIN COMPONENTS ASSEMBLY
			-- ═══════════════════════════════════════════════════════════════════════

			local StatusLine = {
				hl = function()
					return conditions.is_active() and "StatusLine" or "StatusLineNC"
				end,

				-- Left side components
				Mode,
				Primitives.Spacer,
				FileInfo,
				Git,
				Diagnostics,
				Primitives.Space,
				SearchInfo,

				-- Center alignment
				Primitives.Align,

				-- Right side components
				LSPClients,
				Primitives.Space,
				Position,
				ScrollBar,
			}

			local TabLine = BufferLine

			-- ═══════════════════════════════════════════════════════════════════════
			-- 🎨 ENHANCED HIGHLIGHT GROUPS SETUP
			-- ═══════════════════════════════════════════════════════════════════════

			--- Setup custom highlight groups with modern styling
			local function setup_highlights()
				local highlights = {
					-- Enhanced Tabline highlights
					HeirlineTablineActive = {
						fg = colors.text,
						bg = colors.surface0,
						bold = true,
					},
					HeirlineTablineInactive = {
						fg = colors.subtext0,
						bg = colors.mantle,
					},
					HeirlineTablineVisible = {
						fg = colors.subtext1,
						bg = colors.surface1,
					},
					HeirlineTablineModified = {
						fg = colors.green,
						bold = true,
					},
					HeirlineTablineClose = {
						fg = colors.overlay1,
						bg = "NONE",
					},
					HeirlineTablineSeparator = {
						fg = colors.surface2,
						bg = colors.mantle,
					},

					-- Git highlights
					GitAdded = { fg = colors.green, bold = true },
					GitChanged = { fg = colors.yellow, bold = true },
					GitRemoved = { fg = colors.red, bold = true },

					-- Mode highlights with gradients
					HeirlineModeNormal = { fg = colors.base, bg = colors.blue, bold = true },
					HeirlineModeInsert = { fg = colors.base, bg = colors.green, bold = true },
					HeirlineModeVisual = { fg = colors.base, bg = colors.mauve, bold = true },
					HeirlineModeCommand = { fg = colors.base, bg = colors.peach, bold = true },
					HeirlineModeReplace = { fg = colors.base, bg = colors.red, bold = true },
					HeirlineModeTerminal = { fg = colors.base, bg = colors.yellow, bold = true },
				}

				for group, hl in pairs(highlights) do
					api.nvim_set_hl(0, group, hl)
				end
			end

			-- ═══════════════════════════════════════════════════════════════════════
			-- ⚡ HEIRLINE INITIALIZATION
			-- ═══════════════════════════════════════════════════════════════════════

			heirline.setup {
				statusline = StatusLine,
				tabline = TabLine,
				opts = {
					colors = colors,
					disable_winbar_cb = function(args)
						return conditions.buffer_matches({
							buftype = { "nofile", "prompt", "help", "quickfix", "terminal" },
							filetype = {
								"^git.*",
								"fugitive",
								"Trouble",
								"dashboard",
								"alpha",
								"neo-tree",
								"NvimTree",
								"undotree",
								"toggleterm",
								"fzf",
								"telescope",
								"lazy",
								"mason",
								"notify",
								"noice",
								"aerial",
								"lspinfo",
								"null-ls-info",
								"qf",
								"help",
								"man",
								"spectre_panel",
								"startuptime",
								"TelescopePrompt",
								"checkhealth",
								"DressingInput",
							},
						}, args.buf)
					end,
				},
			}

			setup_highlights()

			-- ═══════════════════════════════════════════════════════════════════════
			-- 🔄 ENHANCED AUTOCOMMANDS & PERFORMANCE
			-- ═══════════════════════════════════════════════════════════════════════

			local augroup = api.nvim_create_augroup("HeirlineEnhanced", { clear = true })

			-- Buffer list management with intelligent updates
			api.nvim_create_autocmd({
				"VimEnter",
				"UIEnter",
				"BufAdd",
				"BufDelete",
				"BufWipeout",
				"SessionLoadPost",
			}, {
				group = augroup,
				callback = function(event)
					vim.schedule(function()
						M.safe_call(function()
							local buffers = get_bufs()

							-- Update buffer cache efficiently
							local cache_changed = false
							if #buffers ~= #buflist_cache then
								cache_changed = true
							else
								for i, bufnr in ipairs(buffers) do
									if buflist_cache[i] ~= bufnr then
										cache_changed = true
										break
									end
								end
							end

							if cache_changed then
								-- Clear old cache
								for i = 1, #buflist_cache do
									buflist_cache[i] = nil
								end

								-- Update with new buffers
								for i, bufnr in ipairs(buffers) do
									buflist_cache[i] = bufnr
								end

								-- Smart tabline visibility
								if #buflist_cache > 1 then
									go.showtabline = 2
								elseif go.showtabline ~= 1 then
									go.showtabline = 1
								end

								-- Track this as a buffer access
								if event.event == "BufEnter" and event.buf then
									track_buffer_access(event.buf)
								end
							end
						end)
					end)
				end,
				desc = "Update buffer list intelligently",
			})

			-- Track buffer access on enter
			api.nvim_create_autocmd("BufEnter", {
				group = augroup,
				callback = function(event)
					if event.buf then
						track_buffer_access(event.buf)
					end
				end,
				desc = "Track buffer access time",
			})

			-- Efficient tabline refresh on window events
			api.nvim_create_autocmd({ "WinEnter", "WinClosed", "WinResized" }, {
				group = augroup,
				callback = function()
					vim.schedule(function()
						vim.cmd.redrawtabline()
					end)
				end,
				desc = "Refresh tabline on window events",
			})

			-- Color scheme change handler
			api.nvim_create_autocmd("ColorScheme", {
				group = augroup,
				callback = function()
					vim.schedule(function()
						colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")
						setup_highlights()
						vim.cmd "redrawstatus | redrawtabline"
					end)
				end,
				desc = "Update colors on colorscheme change",
			})

			-- Performance optimizations for different modes
			local original_updatetime = go.updatetime
			api.nvim_create_autocmd("InsertEnter", {
				group = augroup,
				callback = function()
					go.updatetime = 1000 -- Slower updates in insert mode
				end,
				desc = "Optimize performance in insert mode",
			})

			api.nvim_create_autocmd("InsertLeave", {
				group = augroup,
				callback = function()
					go.updatetime = original_updatetime
				end,
				desc = "Restore normal update frequency",
			})

			-- Debounced resize handler
			local resize_timer = nil
			api.nvim_create_autocmd("VimResized", {
				group = augroup,
				callback = function()
					if resize_timer then
						resize_timer:stop()
						resize_timer:close()
						resize_timer = nil
					end
					resize_timer = vim.uv.new_timer()
					if resize_timer then
						resize_timer:start(
							100, -- Faster response
							0,
							vim.schedule_wrap(function()
								vim.cmd "redrawstatus | redrawtabline"
								if resize_timer then
									resize_timer:close()
									resize_timer = nil
								end
							end)
						)
					end
				end,
				desc = "Debounced redraw on resize",
			})

			-- ═══════════════════════════════════════════════════════════════════════
			-- ⌨️  ENHANCED KEYMAPS & COMMANDS
			-- ═══════════════════════════════════════════════════════════════════════

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 🎯 Enhanced Buffer Picker                                           │
			-- └─────────────────────────────────────────────────────────────────────┘

			vim.keymap.set("n", "gbb", function()
				M.safe_call(function()
					local tabline = heirline.tabline
					if not tabline or not tabline._buflist or not tabline._buflist[1] then
						vim.notify("No buffers available", vim.log.levels.WARN)
						return
					end

					local buflist = tabline._buflist[1]
					buflist._picker_labels = {}
					buflist._show_picker = true
					vim.cmd.redrawtabline()

					vim.notify("󰒅 Buffer Picker: Press label key (ESC to cancel)", vim.log.levels.INFO)

					local ok, char = pcall(fn.getcharstr)
					if not ok or char == "\27" then
						buflist._show_picker = false
						vim.cmd.redrawtabline()
						vim.notify("Buffer picker cancelled", vim.log.levels.INFO)
						return
					end

					char = char:upper()
					local bufnr = buflist._picker_labels[char]
					if bufnr and api.nvim_buf_is_valid(bufnr) then
						api.nvim_win_set_buf(0, bufnr)
						track_buffer_access(bufnr) -- Track access
						local name = fn.fnamemodify(api.nvim_buf_get_name(bufnr), ":t")
						name = M.is_empty(name) and "[Untitled]" or name
						vim.notify("󰒅 Switched to: " .. name, vim.log.levels.INFO)
					else
						vim.notify("Invalid selection", vim.log.levels.WARN)
					end

					buflist._show_picker = false
					vim.cmd.redrawtabline()
				end)
			end, { desc = "󰒅 Pick buffer from tabline" })

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 🚀 Enhanced Buffer Navigation                                       │
			-- └─────────────────────────────────────────────────────────────────────┘

			local function create_buffer_nav(cmd, desc, icon)
				return function()
					M.safe_call(function()
						local current_buf = api.nvim_get_current_buf()
						local current_name = fn.fnamemodify(api.nvim_buf_get_name(current_buf), ":t")
						current_name = M.is_empty(current_name) and "[Untitled]" or current_name

						vim.cmd(cmd)

						local new_buf = api.nvim_get_current_buf()
						if new_buf ~= current_buf then
							track_buffer_access(new_buf)
							local new_name = fn.fnamemodify(api.nvim_buf_get_name(new_buf), ":t")
							new_name = M.is_empty(new_name) and "[Untitled]" or new_name
							vim.notify(string.format("%s %s", icon, new_name), vim.log.levels.INFO)
						end
					end)
				end
			end

			-- Smart buffer navigation with wrap-around
			vim.keymap.set(
				"n",
				"<Tab>",
				create_buffer_nav("bnext", "Next buffer", "󰒭"),
				{ desc = "󰒭 Next buffer" }
			)
			vim.keymap.set(
				"n",
				"<S-Tab>",
				create_buffer_nav("bprevious", "Previous buffer", "󰒮"),
				{ desc = "󰒮 Previous buffer" }
			)

			-- Alternative keybindings
			vim.keymap.set(
				"n",
				"<leader>bn",
				create_buffer_nav("bnext", "Next buffer", "󰒭"),
				{ desc = "󰒭 Next buffer" }
			)
			vim.keymap.set(
				"n",
				"<leader>bp",
				create_buffer_nav("bprevious", "Previous buffer", "󰒮"),
				{ desc = "󰒮 Previous buffer" }
			)

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 🗑️  Enhanced Buffer Management                                     │
			-- └─────────────────────────────────────────────────────────────────────┘

			-- Smart buffer close with confirmation
			vim.keymap.set("n", "<leader>bd", function()
				M.safe_call(function()
					local bufnr = api.nvim_get_current_buf()
					local bufname = api.nvim_buf_get_name(bufnr)
					local filename = M.is_empty(bufname) and "[Untitled]" or fn.fnamemodify(bufname, ":t")
					local modified = api.nvim_get_option_value("modified", { buf = bufnr })

					if modified then
						local choices = { "&Save and close", "&Close without saving", "&Cancel" }
						local choice = fn.confirm(
							string.format("󰜄 '%s' has unsaved changes", filename),
							table.concat(choices, "\n"),
							3,
							"Question"
						)

						if choice == 1 then
							vim.cmd "write"
							vim.cmd "bdelete"
							vim.notify("󰆓 Saved and closed: " .. filename, vim.log.levels.INFO)
						elseif choice == 2 then
							vim.cmd "bdelete!"
							vim.notify("󰆴 Closed without saving: " .. filename, vim.log.levels.WARN)
						end
					else
						-- Check if this is the last buffer
						local buffers = get_bufs()
						if #buffers <= 1 then
							vim.cmd "enew" -- Create new buffer before closing
						end
						vim.cmd "bdelete"
						vim.notify("󰆴 Closed: " .. filename, vim.log.levels.INFO)
					end
				end)
			end, { desc = "󰆴 Smart close buffer" })

			-- Close all other buffers
			vim.keymap.set("n", "<leader>bo", function()
				M.safe_call(function()
					local current = api.nvim_get_current_buf()
					local buffers = get_bufs()
					local closed_count = 0

					for _, bufnr in ipairs(buffers) do
						if bufnr ~= current and api.nvim_buf_is_valid(bufnr) then
							local modified = api.nvim_get_option_value("modified", { buf = bufnr })
							if not modified then
								api.nvim_buf_delete(bufnr, {})
								closed_count = closed_count + 1
							end
						end
					end

					vim.notify(string.format("󰆴 Closed %d buffer(s)", closed_count), vim.log.levels.INFO)
				end)
			end, { desc = "󰆴 Close other buffers" })

			-- Quick buffer access (Ctrl+1-9)
			for i = 1, 9 do
				vim.keymap.set("n", "<C-" .. i .. ">", function()
					M.safe_call(function()
						local buffers = get_bufs()
						if buffers[i] and api.nvim_buf_is_valid(buffers[i]) then
							api.nvim_win_set_buf(0, buffers[i])
							track_buffer_access(buffers[i])
							local name = fn.fnamemodify(api.nvim_buf_get_name(buffers[i]), ":t")
							name = M.is_empty(name) and "[Untitled]" or name
							vim.notify(string.format("󰒅 Buffer %d: %s", i, name), vim.log.levels.INFO)
						else
							vim.notify(string.format("Buffer %d not available", i), vim.log.levels.WARN)
						end
					end)
				end, { desc = string.format("󰒅 Switch to buffer %d", i) })
			end

			-- Toggle to last buffer
			vim.keymap.set("n", "<leader><leader>", function()
				M.safe_call(function()
					local last_buf = fn.bufnr "#"
					if last_buf ~= -1 and api.nvim_buf_is_valid(last_buf) then
						api.nvim_win_set_buf(0, last_buf)
						track_buffer_access(last_buf)
						local name = fn.fnamemodify(api.nvim_buf_get_name(last_buf), ":t")
						name = M.is_empty(name) and "[Untitled]" or name
						vim.notify("󰒅 Toggled to: " .. name, vim.log.levels.INFO)
					else
						vim.notify("No alternate buffer", vim.log.levels.WARN)
					end
				end)
			end, { desc = "󰒅 Toggle last buffer" })

			-- Refresh interface
			vim.keymap.set("n", "<leader>br", function()
				vim.cmd "redrawstatus | redrawtabline"
				vim.notify("󰑓 Interface refreshed", vim.log.levels.INFO)
			end, { desc = "󰑓 Refresh interface" })

			-- ═══════════════════════════════════════════════════════════════════════
			-- 📋 ENHANCED COMMANDS
			-- ═══════════════════════════════════════════════════════════════════════

			-- Enhanced buffer info with detailed statistics
			vim.api.nvim_create_user_command("BufferInfo", function()
				local buffers = get_bufs()
				local current_buf = api.nvim_get_current_buf()
				local info = { "󰒅 Enhanced Buffer Information", string.rep("━", 60) }

				if #buffers == 0 then
					table.insert(info, "No buffers available")
				else
					table.insert(info, string.format("Total buffers: %d", #buffers))
					table.insert(info, "")

					for i, bufnr in ipairs(buffers) do
						local name = api.nvim_buf_get_name(bufnr)
						local filename = M.is_empty(name) and "[Untitled]" or fn.fnamemodify(name, ":t")
						local modified = api.nvim_get_option_value("modified", { buf = bufnr }) and " 󰜄" or ""
						local readonly = api.nvim_get_option_value("readonly", { buf = bufnr }) and " 󰌾" or ""
						local current = bufnr == current_buf and " 󰻃" or ""
						local buftype = api.nvim_get_option_value("buftype", { buf = bufnr })
						local type_indicator = buftype == "terminal" and " 󰓫" or ""
						local last_access = api.nvim_buf_get_var(bufnr, "heirline_last_access") or 0
						local time_ago = last_access > 0
								and string.format(" (%.1fs ago)", (vim.loop.now() - last_access) / 1000)
							or ""

						table.insert(
							info,
							string.format(
								"%2d. %s%s%s%s%s%s",
								i,
								filename,
								modified,
								readonly,
								type_indicator,
								current,
								time_ago
							)
						)
					end
				end

				table.insert(info, "")
				table.insert(info, string.rep("━", 60))
				table.insert(info, "Keybindings:")
				table.insert(info, "  <Tab>/<S-Tab>  - Navigate buffers")
				table.insert(info, "  <Ctrl-1-9>     - Quick buffer access")
				table.insert(info, "  gbb            - Buffer picker")
				table.insert(info, "  <leader>bd     - Close buffer")
				table.insert(info, "  <leader>bo     - Close other buffers")

				-- Create floating window with better styling
				local buf = api.nvim_create_buf(false, true)
				api.nvim_buf_set_lines(buf, 0, -1, false, info)

				local width = math.max(70, math.min(vim.o.columns - 10, 90))
				local height = math.min(#info + 4, vim.o.lines - 10)
				local opts = {
					relative = "editor",
					width = width,
					height = height,
					col = math.floor((vim.o.columns - width) / 2),
					row = math.floor((vim.o.lines - height) / 2),
					style = "minimal",
					border = "rounded",
					title = " 󰒅 Buffer Info ",
					title_pos = "center",
				}

				local win = api.nvim_open_win(buf, true, opts)
				api.nvim_set_option_value("filetype", "heirline-info", { buf = buf })

				-- Enhanced window styling
				api.nvim_win_set_hl_ns(win, api.nvim_create_namespace "heirline_info")

				-- Key mappings for the info window
				local function close_window()
					if api.nvim_win_is_valid(win) then
						api.nvim_win_close(win, true)
					end
				end

				vim.keymap.set("n", "<Esc>", close_window, { buffer = buf, nowait = true })
				vim.keymap.set("n", "q", close_window, { buffer = buf, nowait = true })
				vim.keymap.set("n", "<CR>", close_window, { buffer = buf, nowait = true })
			end, { desc = "Show enhanced buffer information" })

			-- Smart buffer cleanup with preview
			vim.api.nvim_create_user_command("BufferCleanup", function()
				M.safe_call(function()
					local buffers = get_bufs()
					local current = api.nvim_get_current_buf()
					local candidates = {}

					-- Find cleanup candidates
					for _, bufnr in ipairs(buffers) do
						if bufnr ~= current and api.nvim_buf_is_valid(bufnr) then
							local modified = api.nvim_get_option_value("modified", { buf = bufnr })
							local name = api.nvim_buf_get_name(bufnr)

							if not modified then
								local should_clean = false
								local reason = ""

								if M.is_empty(name) then
									should_clean = true
									reason = "Empty buffer"
								elseif name:match "^/tmp/" then
									should_clean = true
									reason = "Temporary file"
								elseif name:match "scratch" or name:match "Scratch" then
									should_clean = true
									reason = "Scratch buffer"
								elseif fn.getbufvar(bufnr, "&buftype") == "nofile" then
									should_clean = true
									reason = "No file buffer"
								end

								if should_clean then
									table.insert(candidates, {
										bufnr = bufnr,
										name = M.is_empty(name) and "[Untitled]" or fn.fnamemodify(name, ":t"),
										reason = reason,
									})
								end
							end
						end
					end

					if #candidates == 0 then
						vim.notify("󰆴 No buffers need cleanup", vim.log.levels.INFO)
						return
					end

					-- Show preview and confirm
					local preview = { "Buffers to be cleaned:" }
					for _, candidate in ipairs(candidates) do
						table.insert(preview, string.format("  • %s (%s)", candidate.name, candidate.reason))
					end

					local choice = fn.confirm(
						table.concat(preview, "\n") .. string.format("\n\nCleanup %d buffer(s)?", #candidates),
						"&Yes\n&No",
						2
					)

					if choice == 1 then
						local cleaned = 0
						for _, candidate in ipairs(candidates) do
							if api.nvim_buf_is_valid(candidate.bufnr) then
								api.nvim_buf_delete(candidate.bufnr, {})
								cleaned = cleaned + 1
							end
						end
						vim.notify(string.format("󰆴 Cleaned up %d buffer(s)", cleaned), vim.log.levels.INFO)
					else
						vim.notify("Cleanup cancelled", vim.log.levels.INFO)
					end
				end)
			end, { desc = "Smart buffer cleanup with preview" })

			-- Tabline toggle with animation
			vim.api.nvim_create_user_command("TablineToggle", function()
				if go.showtabline == 0 then
					go.showtabline = 2
					vim.notify("󰓩 Tabline enabled", vim.log.levels.INFO)
				else
					go.showtabline = 0
					vim.notify("󰓩 Tabline disabled", vim.log.levels.INFO)
				end
			end, { desc = "Toggle tabline visibility" })

			-- Advanced theme cycling
			vim.api.nvim_create_user_command("ThemeToggle", function()
				local flavors = { "latte", "frappe", "macchiato", "mocha" }
				local flavor_names = { "☀️  Latte", "🪴 Frappé", "🌺 Macchiato", "🌙 Mocha" }
				local current = vim.g.catppuccin_flavour or "mocha"
				local current_idx = 1

				for i, flavor in ipairs(flavors) do
					if flavor == current then
						current_idx = i
						break
					end
				end

				local next_idx = current_idx % #flavors + 1
				local next_flavor = flavors[next_idx]

				vim.g.catppuccin_flavour = next_flavor
				vim.cmd "colorscheme catppuccin"
				vim.notify(string.format("󰏘 Theme: %s", flavor_names[next_idx]), vim.log.levels.INFO)
			end, { desc = "Cycle through catppuccin themes" })

			-- Buffer sorting options
			vim.api.nvim_create_user_command("BufferSort", function(opts)
				local sort_type = opts.args or "name"
				local buffers = get_bufs()

				if sort_type == "name" then
					table.sort(buffers, function(a, b)
						local name_a = fn.fnamemodify(api.nvim_buf_get_name(a), ":t")
						local name_b = fn.fnamemodify(api.nvim_buf_get_name(b), ":t")
						return name_a < name_b
					end)
				elseif sort_type == "modified" then
					table.sort(buffers, function(a, b)
						local mod_a = api.nvim_get_option_value("modified", { buf = a })
						local mod_b = api.nvim_get_option_value("modified", { buf = b })
						return mod_a and not mod_b
					end)
				elseif sort_type == "access" then
					table.sort(buffers, function(a, b)
						local access_a = api.nvim_buf_get_var(a, "heirline_last_access") or 0
						local access_b = api.nvim_buf_get_var(b, "heirline_last_access") or 0
						return access_a > access_b
					end)
				end

				-- Update cache
				for i = 1, #buflist_cache do
					buflist_cache[i] = nil
				end
				for i, bufnr in ipairs(buffers) do
					buflist_cache[i] = bufnr
				end

				vim.cmd.redrawtabline()
				vim.notify(string.format("󰒅 Buffers sorted by %s", sort_type), vim.log.levels.INFO)
			end, {
				desc = "Sort buffers by criteria",
				nargs = "?",
				complete = function()
					return { "name", "modified", "access" }
				end,
			})

			-- ═══════════════════════════════════════════════════════════════════════
			-- 🎯 FINAL SETUP & OPTIMIZATION
			-- ═══════════════════════════════════════════════════════════════════════

			-- Initial buffer list update
			vim.schedule(function()
				local buffers = get_bufs()
				for i, bufnr in ipairs(buffers) do
					buflist_cache[i] = bufnr
					-- Initialize access time for existing buffers
					if not pcall(api.nvim_buf_get_var, bufnr, "heirline_last_access") then
						api.nvim_buf_set_var(bufnr, "heirline_last_access", vim.loop.now())
					end
				end

				-- Set intelligent initial tabline state
				if #buffers > 1 then
					go.showtabline = 2
				end
			end)

			-- Memory cleanup on exit
			api.nvim_create_autocmd("VimLeavePre", {
				group = augroup,
				callback = function()
					-- Clean up timers
					if resize_timer then
						resize_timer:stop()
						resize_timer:close()
						resize_timer = nil
					end

					-- Clear cache
					buflist_cache = {}
					buffer_positions = {}
				end,
				desc = "Clean up resources on exit",
			})

			-- Periodic buffer access cleanup (prevent memory bloat)
			local cleanup_timer = vim.uv.new_timer()
			if cleanup_timer then
				cleanup_timer:start(300000, 300000, function() -- Every 5 minutes
					vim.schedule(function()
						M.safe_call(function()
							local current_time = vim.loop.now()
							local buffers = api.nvim_list_bufs()

							for _, bufnr in ipairs(buffers) do
								if api.nvim_buf_is_valid(bufnr) then
									local last_access = api.nvim_buf_get_var(bufnr, "heirline_last_access") or 0
									-- Remove access time for buffers not accessed in 30 minutes
									if current_time - last_access > 1800000 then
										pcall(api.nvim_buf_del_var, bufnr, "heirline_last_access")
									end
								end
							end
						end)
					end)
				end)
			end

			-- Success notification with enhanced info
			vim.notify("🚀 Heirline Enhanced loaded successfully!", vim.log.levels.INFO, {
				title = "Heirline Enhanced",
				timeout = 3000,
			})

			-- Additional performance hint
			vim.defer_fn(function()
				local buffers = get_bufs()
				if #buffers > 10 then
					vim.notify("💡 Tip: Use 'gbb' for quick buffer picking with many buffers", vim.log.levels.INFO, {
						title = "Heirline Tip",
						timeout = 5000,
					})
				end
			end, 2000)
		end,
	},
}
