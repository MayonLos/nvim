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
			-- =========================================================================
			-- CORE IMPORTS & SETUP
			-- =========================================================================

			local heirline = require "heirline"
			local conditions = require "heirline.conditions"
			local utils = require "heirline.utils"
			local devicons = require "nvim-web-devicons"
			local colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")

			-- Cache frequently used APIs for better performance
			local api, fn, bo, go = vim.api, vim.fn, vim.bo, vim.go
			local diagnostic = vim.diagnostic

			-- =========================================================================
			-- UTILITY FUNCTIONS
			-- =========================================================================

			local M = {}

			-- Safe function execution with fallback
			M.safe_call = function(func, fallback)
				local ok, result = pcall(func)
				return ok and result or fallback
			end

			-- Check if string is empty or nil
			M.is_empty = function(str)
				return not str or str == ""
			end

			-- Get window width with validation
			M.get_win_width = function(winid)
				return M.safe_call(function()
					return api.nvim_win_is_valid(winid) and api.nvim_win_get_width(winid) or 0
				end, 0)
			end

			-- Truncate text with ellipsis
			M.truncate = function(str, max_len)
				if #str <= max_len then
					return str
				end
				return str:sub(1, max_len - 3) .. "…"
			end

			-- Get responsive max length based on window width
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

			-- =========================================================================
			-- PRIMITIVE COMPONENTS
			-- =========================================================================

			local Primitives = {
				Space = { provider = " " },
				Spacer = { provider = "  " },
				TripleSpacer = { provider = "   " },
				Align = { provider = "%=" },
				Separator = {
					provider = function()
						return vim.o.columns > 120 and "  │  " or "  "
					end,
					hl = { fg = colors.surface1 },
				},
			}

			-- =========================================================================
			-- ENHANCED STATUS LINE COMPONENTS
			-- =========================================================================

			-- Modern mode component with better icons and colors
			local Mode = {
				init = function(self)
					self.mode = fn.mode()
				end,
				static = {
					mode_map = {
						n = { icon = "󰰆", name = "NORMAL", color = colors.blue },
						i = { icon = "󰰅", name = "INSERT", color = colors.green },
						v = { icon = "󰰈", name = "VISUAL", color = colors.mauve },
						V = { icon = "󰰉", name = "V-LINE", color = colors.mauve },
						["\22"] = { icon = "󰰊", name = "V-BLOCK", color = colors.mauve },
						c = { icon = "󰞷", name = "COMMAND", color = colors.peach },
						R = { icon = "󰛔", name = "REPLACE", color = colors.red },
						r = { icon = "󰛔", name = "REPLACE", color = colors.red },
						t = { icon = "󰓫", name = "TERMINAL", color = colors.yellow },
						s = { icon = "󰒅", name = "SELECT", color = colors.teal },
						S = { icon = "󰒅", name = "S-LINE", color = colors.teal },
						["\19"] = { icon = "󰒅", name = "S-BLOCK", color = colors.teal },
						no = { icon = "󰰇", name = "O-PENDING", color = colors.red },
						nov = { icon = "󰰇", name = "O-PENDING", color = colors.red },
						noV = { icon = "󰰇", name = "O-PENDING", color = colors.red },
						["no\22"] = { icon = "󰰇", name = "O-PENDING", color = colors.red },
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

			-- Enhanced file info with better responsiveness
			local FileInfo = {
				init = function(self)
					self.filename = fn.expand "%:t"
					self.filepath = fn.expand "%:p"
					self.filetype = bo.filetype
					self.modified = bo.modified
					self.readonly = bo.readonly
					self.buftype = bo.buftype
				end,
				{
					-- File icon with dynamic coloring
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
				{
					-- Filename with smart truncation
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
				{
					-- File status indicators
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

			-- Modern Git component with better formatting
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
						removed = "-",
					},
				},
				{
					-- Branch name
					condition = function(self)
						return not M.is_empty(self.head)
					end,
					provider = function(self)
						local branch = M.truncate(self.head, M.get_responsive_length(20))
						return string.format(" %s %s", self.icons.branch, branch)
					end,
					hl = { fg = colors.lavender, bold = true },
				},
				{
					-- Git changes
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

			-- Enhanced diagnostics with severity-based styling
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
				{
					provider = function(self)
						if self.errors == 0 then
							return ""
						end
						return string.format(" %s %d", self.icons.error, self.errors)
					end,
					hl = { fg = colors.red, bold = true },
				},
				{
					provider = function(self)
						if self.warnings == 0 then
							return ""
						end
						return string.format(" %s %d", self.icons.warn, self.warnings)
					end,
					hl = { fg = colors.yellow, bold = true },
				},
				{
					provider = function(self)
						if self.infos == 0 then
							return ""
						end
						return string.format(" %s %d", self.icons.info, self.infos)
					end,
					hl = { fg = colors.sky, bold = true },
				},
				{
					provider = function(self)
						if self.hints == 0 then
							return ""
						end
						return string.format(" %s %d", self.icons.hint, self.hints)
					end,
					hl = { fg = colors.teal, bold = true },
				},
				update = { "DiagnosticChanged", "BufEnter" },
			}

			-- Modern search info component
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

			-- Enhanced LSP clients with better formatting
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

			-- Format status component
			local FormatStatus = {
				condition = function()
					local ok, _ = pcall(require, "conform")
					return ok
				end,
				init = function(self)
					self.global_enabled = vim.g.autoformat_enabled ~= false
					self.buffer_enabled = vim.b.autoformat_enabled ~= false
					self.is_enabled = self.global_enabled and self.buffer_enabled
					local ok, conform = pcall(require, "conform")
					if ok then
						local formatters = conform.list_formatters(0)
						self.has_formatters = #formatters > 0
						self.formatter_names = {}
						for _, formatter in ipairs(formatters) do
							table.insert(self.formatter_names, formatter.name)
						end
					else
						self.has_formatters = false
						self.formatter_names = {}
					end
				end,
				{
					provider = function(self)
						if not self.has_formatters then
							return ""
						end
						if vim.b.formatted_recently then
							return " 🔄"
						elseif self.is_enabled then
							return " 🔧"
						else
							return " 🚫"
						end
					end,
					hl = function(self)
						if not self.has_formatters then
							return { fg = colors.overlay1 }
						end
						if vim.b.formatted_recently then
							return { fg = colors.yellow, bold = true }
						elseif self.is_enabled then
							return { fg = colors.green, bold = true }
						else
							return { fg = colors.red, bold = true }
						end
					end,
					on_click = {
						callback = function()
							vim.schedule(function()
								if vim.g.autoformat_enabled then
									vim.g.autoformat_enabled = false
									vim.notify("🚫 Global autoformat disabled", vim.log.levels.WARN)
								else
									vim.g.autoformat_enabled = true
									vim.notify("🔧 Global autoformat enabled", vim.log.levels.INFO)
								end
							end)
						end,
						name = "format_toggle_click",
					},
				},
				{
					condition = function(self)
						return self.has_formatters and vim.o.columns > 140 and #self.formatter_names > 0
					end,
					provider = function(self)
						local names = table.concat(self.formatter_names, "·")
						return M.truncate(names, 15)
					end,
					hl = { fg = colors.subtext1, italic = true },
				},
				update = { "BufEnter", "BufWritePost", "User" },
			}

			-- Smart format status that adapts to screen width
			local FormatStatusSmart = {
				condition = function()
					local ok, conform = pcall(require, "conform")
					if not ok then
						return false
					end
					local formatters = conform.list_formatters(0)
					return #formatters > 0
				end,
				flexible = 2,
				{
					FormatStatus,
				},
				{
					{
						provider = function()
							if vim.b.formatted_recently then
								return " 🔄"
							else
								local global_enabled = vim.g.autoformat_enabled ~= false
								local buffer_enabled = vim.b.autoformat_enabled ~= false
								return (global_enabled and buffer_enabled) and " 🔧" or " 🚫"
							end
						end,
						hl = function()
							if vim.b.formatted_recently then
								return { fg = colors.yellow, bold = true }
							else
								local global_enabled = vim.g.autoformat_enabled ~= false
								local buffer_enabled = vim.b.autoformat_enabled ~= false
								local is_enabled = global_enabled and buffer_enabled
								return { fg = is_enabled and colors.green or colors.red, bold = true }
							end
						end,
					},
					{ provider = " " },
				},
				{
					provider = function()
						if vim.b.formatted_recently then
							return "🔄"
						else
							local global_enabled = vim.g.autoformat_enabled ~= false
							local buffer_enabled = vim.b.autoformat_enabled ~= false
							return (global_enabled and buffer_enabled) and "🔧" or "🚫"
						end
					end,
					hl = function()
						if vim.b.formatted_recently then
							return { fg = colors.yellow }
						else
							local global_enabled = vim.g.autoformat_enabled ~= false
							local buffer_enabled = vim.b.autoformat_enabled ~= false
							local is_enabled = global_enabled and buffer_enabled
							return { fg = is_enabled and colors.green or colors.red }
						end
					end,
				},
			}

			-- Responsive position component
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
				{
					provider = function(self)
						return string.format("%d%%", self.percent)
					end,
					hl = { fg = colors.green },
				},
			}

			-- Enhanced scroll bar with smooth gradient
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

			-- =========================================================================
			-- ENHANCED TABLINE COMPONENTS
			-- =========================================================================

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
						NvimTree = { title = "󰙅 Explorer", hl = "NvimTreeNormal" },
						["neo-tree"] = { title = "󰙅 Neo-tree", hl = "NeoTreeNormal" },
						CHADTree = { title = "󰙅 CHADTree", hl = "CHADTreeNormal" },
						nerdtree = { title = "󰙅 NERDTree", hl = "NERDTree" },
						Outline = { title = "󰘬 Outline", hl = "OutlineNormal" },
						tagbar = { title = "󰤌 Tagbar", hl = "TagbarNormal" },
						undotree = { title = "󰄶 UndoTree", hl = "UndotreeNormal" },
						vista = { title = "󰤌 Vista", hl = "VistaNormal" },
						aerial = { title = "󰤌 Aerial", hl = "AerialNormal" },
					}
					if sidebars[filetype] then
						self.title = sidebars[filetype].title
						self.hl_group = sidebars[filetype].hl
						return true
					elseif buftype == "terminal" then
						self.title = "󰓫 Terminal"
						self.hl_group = "StatusLine"
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
						bg = is_focused and colors.surface0 or colors.base,
						fg = is_focused and colors.text or colors.subtext1,
						bold = is_focused,
					}
				end,
				update = { "WinEnter", "BufEnter", "WinResized" },
			}

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
						return { fg = colors.yellow }
					elseif M.is_empty(self.filename) then
						return { fg = colors.subtext1 }
					end
					local _, icon_color = devicons.get_icon_color(self.filename, self.extension, { default = true })
					return { fg = icon_color or colors.text }
				end,
			}

			local TablineFileName = {
				provider = function(self)
					local buftype = M.safe_call(function()
						return api.nvim_get_option_value("buftype", { buf = self.bufnr })
					end, "")
					if buftype == "terminal" then
						return "Terminal"
					end
					local filename = self.filename
					if M.is_empty(filename) then
						return "[Untitled]"
					end
					filename = fn.fnamemodify(filename, ":t")
					local max_len = M.get_responsive_length(20)
					return M.truncate(filename, max_len)
				end,
				hl = function(self)
					return {
						bold = self.is_active,
						italic = not self.is_active,
						fg = self.is_active and colors.text or colors.subtext1,
					}
				end,
			}

			local TablineFileFlags = {
				{
					condition = function(self)
						return M.safe_call(function()
							return api.nvim_get_option_value("modified", { buf = self.bufnr })
						end, false)
					end,
					provider = " ●",
					hl = { fg = colors.green, bold = true },
				},
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
					hl = { fg = colors.red },
				},
			}

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
					return "[" .. self.label .. "]"
				end,
				hl = { fg = colors.base, bg = colors.red, bold = true },
			}

			local TablineFileNameBlock = {
				init = function(self)
					self.filename = M.safe_call(function()
						return api.nvim_buf_get_name(self.bufnr)
					end, "")
				end,
				hl = function(self)
					if self.is_active then
						return { bg = colors.surface0, fg = colors.text }
					else
						return { bg = colors.base, fg = colors.subtext1 }
					end
				end,
				on_click = {
					callback = function(_, minwid, _, button)
						vim.schedule(function()
							M.safe_call(function()
								if button == "m" then
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
								else
									api.nvim_win_set_buf(0, minwid)
								end
								vim.cmd.redrawtabline()
							end)
						end)
					end,
					minwid = function(self)
						return self.bufnr
					end,
					name = "heirline_tabline_callback",
				},
				{ provider = " " },
				TablineFileIcon,
				{ provider = " " },
				TablineFileName,
				TablineFileFlags,
				{ provider = " " },
			}

			local TablineBufferBlock = utils.surround({ "▎", "" }, function(self)
				return self.is_active and colors.blue or colors.surface1
			end, {
				TablinePicker,
				TablineFileNameBlock,
			})

			-- =========================================================================
			-- BUFFER MANAGEMENT
			-- =========================================================================

			local buflist_cache = {}

			local function get_bufs()
				return M.safe_call(function()
					return vim.tbl_filter(function(bufnr)
						if not api.nvim_buf_is_valid(bufnr) then
							return false
						end
						local buftype = api.nvim_get_option_value("buftype", { buf = bufnr })
						local filetype = api.nvim_get_option_value("filetype", { buf = bufnr })
						local buflisted = api.nvim_get_option_value("buflisted", { buf = bufnr })
						if buftype ~= "" and buftype ~= "terminal" then
							return false
						end
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
						}
						for _, ft in ipairs(excluded_filetypes) do
							if filetype == ft then
								return false
							end
						end
						return buflisted
					end, api.nvim_list_bufs())
				end, {})
			end

			local BufferLine = {
				TablineOffset,
				utils.make_buflist(
					TablineBufferBlock,
					{ provider = "󰍞 ", hl = { fg = colors.overlay1 } },
					{ provider = " 󰍟", hl = { fg = colors.overlay1 } },
					function()
						return buflist_cache
					end,
					false
				),
			}

			-- =========================================================================
			-- MAIN COMPONENTS ASSEMBLY
			-- =========================================================================

			local StatusLine = {
				hl = function()
					return conditions.is_active() and "StatusLine" or "StatusLineNC"
				end,
				Mode,
				Primitives.Spacer,
				FileInfo,
				Git,
				Diagnostics,
				Primitives.Space,
				SearchInfo,
				Primitives.Align,
				LSPClients,
				Primitives.Space,
				FormatStatusSmart,
				Primitives.Space,
				Position,
				ScrollBar,
			}

			local TabLine = BufferLine

			-- =========================================================================
			-- HIGHLIGHT GROUPS SETUP
			-- =========================================================================

			local function setup_highlights()
				local highlights = {
					GitAdded = { fg = colors.green, bold = true },
					GitChanged = { fg = colors.yellow, bold = true },
					GitRemoved = { fg = colors.red, bold = true },
					HeirlineModeNormal = { fg = colors.base, bg = colors.blue, bold = true },
					HeirlineModeInsert = { fg = colors.base, bg = colors.green, bold = true },
					HeirlineModeVisual = { fg = colors.base, bg = colors.mauve, bold = true },
					HeirlineModeCommand = { fg = colors.base, bg = colors.peach, bold = true },
					HeirlineModeReplace = { fg = colors.base, bg = colors.red, bold = true },
					HeirlineModeTerminal = { fg = colors.base, bg = colors.yellow, bold = true },
					HeirlineTablineActive = { fg = colors.text, bg = colors.surface0, bold = true },
					HeirlineTablineInactive = { fg = colors.subtext1, bg = colors.base },
					HeirlineTablineModified = { fg = colors.green, bold = true },
					HeirlineTablineClose = { fg = colors.overlay1 },
				}
				for group, hl in pairs(highlights) do
					api.nvim_set_hl(0, group, hl)
				end
			end

			-- =========================================================================
			-- HEIRLINE INITIALIZATION
			-- =========================================================================

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
								"lspinfo",
								"spectre_panel",
								"startuptime",
								"TelescopePrompt",
							},
						}, args.buf)
					end,
				},
			}

			setup_highlights()

			-- =========================================================================
			-- ENHANCED AUTOCOMMANDS
			-- =========================================================================

			local augroup = api.nvim_create_augroup("HeirlineEnhanced", { clear = true })

			api.nvim_create_autocmd({ "User" }, {
				group = augroup,
				pattern = "ConformFormatToggle",
				callback = function()
					vim.schedule(function()
						vim.cmd.redrawstatus()
					end)
				end,
			})

			api.nvim_create_autocmd("BufWritePost", {
				group = augroup,
				callback = function()
					if vim.b.autoformat_enabled ~= false and vim.g.autoformat_enabled ~= false then
						vim.b.formatted_recently = true
						vim.cmd.redrawstatus()
						if vim.b.format_timer then
							vim.b.format_timer:stop()
							vim.b.format_timer:close()
						end
						local timer = vim.loop.new_timer()
						timer:start(
							5000,
							0,
							vim.schedule_wrap(function()
								vim.b.formatted_recently = false
								vim.cmd.redrawstatus()
								timer:close()
							end)
						)
						vim.b.format_timer = timer
					end
				end,
			})

			api.nvim_create_autocmd({
				"VimEnter",
				"UIEnter",
				"BufAdd",
				"BufDelete",
				"BufWipeout",
				"SessionLoadPost",
			}, {
				group = augroup,
				callback = function()
					vim.schedule(function()
						M.safe_call(function()
							local buffers = get_bufs()
							for i, bufnr in ipairs(buffers) do
								buflist_cache[i] = bufnr
							end
							for i = #buffers + 1, #buflist_cache do
								buflist_cache[i] = nil
							end
							if #buflist_cache > 1 then
								go.showtabline = 2
							elseif go.showtabline ~= 1 then
								go.showtabline = 1
							end
						end)
					end)
				end,
			})

			api.nvim_create_autocmd({ "BufEnter", "WinEnter", "WinClosed", "WinResized" }, {
				group = augroup,
				callback = function()
					vim.schedule(function()
						vim.cmd.redrawtabline()
					end)
				end,
			})

			api.nvim_create_autocmd("ColorScheme", {
				group = augroup,
				callback = function()
					vim.schedule(function()
						colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")
						setup_highlights()
						vim.cmd "redrawstatus | redrawtabline"
					end)
				end,
			})

			api.nvim_create_autocmd("InsertEnter", {
				group = augroup,
				callback = function()
					go.updatetime = 1000
				end,
			})

			api.nvim_create_autocmd("InsertLeave", {
				group = augroup,
				callback = function()
					go.updatetime = 250
				end,
			})

			local resize_timer = nil
			api.nvim_create_autocmd("VimResized", {
				group = augroup,
				callback = function()
					if resize_timer then
						fn.timer_stop(resize_timer)
					end
					resize_timer = fn.timer_start(150, function()
						vim.schedule(function()
							vim.cmd "redrawstatus | redrawtabline"
						end)
						resize_timer = nil
					end)
				end,
			})

			api.nvim_create_autocmd({ "FocusGained", "FocusLost" }, {
				group = augroup,
				callback = function()
					vim.schedule(function()
						vim.cmd.redrawtabline()
					end)
				end,
			})

			-- =========================================================================
			-- ENHANCED KEYMAPS & COMMANDS
			-- =========================================================================

			vim.api.nvim_create_user_command("FormatToggle", function()
				vim.g.autoformat_enabled = not vim.g.autoformat_enabled
				local status = vim.g.autoformat_enabled and "✅ enabled" or "❌ disabled"
				vim.notify(
					string.format("Global autoformat %s", status),
					vim.log.levels.INFO,
					{ title = "Conform Format" }
				)
				vim.api.nvim_exec_autocmds("User", { pattern = "ConformFormatToggle" })
			end, { desc = "Toggle global autoformat on save" })

			vim.api.nvim_create_user_command("FormatBufferToggle", function()
				if vim.b.autoformat_enabled == nil then
					vim.b.autoformat_enabled = true
				end
				vim.b.autoformat_enabled = not vim.b.autoformat_enabled
				local status = vim.b.autoformat_enabled and "✅ enabled" or "❌ disabled"
				vim.notify(
					string.format("Buffer autoformat %s", status),
					vim.log.levels.INFO,
					{ title = "Conform Format" }
				)
				vim.api.nvim_exec_autocmds("User", { pattern = "ConformFormatToggle" })
			end, { desc = "Toggle autoformat for current buffer" })

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

			local function create_buffer_nav(cmd, desc, icon)
				return function()
					M.safe_call(function()
						local current_name = fn.fnamemodify(api.nvim_buf_get_name(0), ":t")
						current_name = M.is_empty(current_name) and "[Untitled]" or current_name
						vim.cmd(cmd)
						local new_name = fn.fnamemodify(api.nvim_buf_get_name(0), ":t")
						new_name = M.is_empty(new_name) and "[Untitled]" or new_name
						if current_name ~= new_name then
							vim.notify(string.format("%s %s", icon, new_name), vim.log.levels.INFO)
						end
					end)
				end
			end

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

			vim.keymap.set("n", "<leader>bd", function()
				M.safe_call(function()
					local bufnr = api.nvim_get_current_buf()
					local bufname = api.nvim_buf_get_name(bufnr)
					local filename = M.is_empty(bufname) and "[Untitled]" or fn.fnamemodify(bufname, ":t")
					local modified = api.nvim_get_option_value("modified", { buf = bufnr })
					if modified then
						local choices = {
							"&Save and close",
							"&Close without saving",
							"&Cancel",
						}
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
						vim.cmd "bdelete"
						vim.notify("󰆴 Closed: " .. filename, vim.log.levels.INFO)
					end
				end)
			end, { desc = "󰆴 Close buffer" })

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

			for i = 1, 9 do
				vim.keymap.set("n", "<C-" .. i .. ">", function()
					M.safe_call(function()
						local buffers = get_bufs()
						if buffers[i] and api.nvim_buf_is_valid(buffers[i]) then
							api.nvim_win_set_buf(0, buffers[i])
							local name = fn.fnamemodify(api.nvim_buf_get_name(buffers[i]), ":t")
							name = M.is_empty(name) and "[Untitled]" or name
							vim.notify(string.format("󰒅 Buffer %d: %s", i, name), vim.log.levels.INFO)
						else
							vim.notify(string.format("Buffer %d not available", i), vim.log.levels.WARN)
						end
					end)
				end, { desc = string.format("󰒅 Switch to buffer %d", i) })
			end

			vim.keymap.set("n", "<leader>bmh", function()
				M.safe_call(function()
					local current_buf = api.nvim_get_current_buf()
					local buffers = get_bufs()
					local current_idx = nil
					for i, bufnr in ipairs(buffers) do
						if bufnr == current_buf then
							current_idx = i
							break
						end
					end
					if current_idx and current_idx > 1 then
						buffers[current_idx], buffers[current_idx - 1] = buffers[current_idx - 1], buffers[current_idx]
						for i, v in ipairs(buffers) do
							buflist_cache[i] = v
						end
						vim.cmd.redrawtabline()
						vim.notify("󰒮 Moved buffer left", vim.log.levels.INFO)
					else
						vim.notify("Cannot move buffer left", vim.log.levels.WARN)
					end
				end)
			end, { desc = "󰒮 Move buffer left" })

			vim.keymap.set("n", "<leader>bml", function()
				M.safe_call(function()
					local current_buf = api.nvim_get_current_buf()
					local buffers = get_bufs()
					local current_idx = nil
					for i, bufnr in ipairs(buffers) do
						if bufnr == current_buf then
							current_idx = i
							break
						end
					end
					if current_idx and current_idx < #buffers then
						buffers[current_idx], buffers[current_idx + 1] = buffers[current_idx + 1], buffers[current_idx]
						for i, v in ipairs(buffers) do
							buflist_cache[i] = v
						end
						vim.cmd.redrawtabline()
						vim.notify("󰒭 Moved buffer right", vim.log.levels.INFO)
					else
						vim.notify("Cannot move buffer right", vim.log.levels.WARN)
					end
				end)
			end, { desc = "󰒭 Move buffer right" })

			vim.keymap.set("n", "<leader><leader>", function()
				M.safe_call(function()
					vim.cmd "buffer #"
					local name = fn.fnamemodify(api.nvim_buf_get_name(0), ":t")
					name = M.is_empty(name) and "[Untitled]" or name
					vim.notify("󰒅 Toggled to: " .. name, vim.log.levels.INFO)
				end)
			end, { desc = "󰒅 Toggle last buffer" })

			vim.keymap.set("n", "<leader>br", function()
				vim.cmd "redrawstatus | redrawtabline"
				vim.notify("󰑓 Interface refreshed", vim.log.levels.INFO)
			end, { desc = "󰑓 Refresh interface" })

			-- =========================================================================
			-- ENHANCED COMMANDS
			-- =========================================================================

			api.nvim_create_user_command("TablineToggle", function()
				if go.showtabline == 0 then
					go.showtabline = 2
					vim.notify("󰓩 Tabline enabled", vim.log.levels.INFO)
				else
					go.showtabline = 0
					vim.notify("󰓩 Tabline disabled", vim.log.levels.INFO)
				end
			end, { desc = "Toggle tabline visibility" })

			api.nvim_create_user_command("BufferInfo", function()
				local buffers = get_bufs()
				local current_buf = api.nvim_get_current_buf()
				local info = { "󰒅 Buffer Information", string.rep("─", 50) }
				if #buffers == 0 then
					table.insert(info, "No buffers available")
				else
					for i, bufnr in ipairs(buffers) do
						local name = api.nvim_buf_get_name(bufnr)
						local filename = M.is_empty(name) and "[Untitled]" or fn.fnamemodify(name, ":t")
						local modified = api.nvim_get_option_value("modified", { buf = bufnr }) and " 󰜄" or ""
						local readonly = api.nvim_get_option_value("readonly", { buf = bufnr }) and " 󰌾" or ""
						local current = bufnr == current_buf and " 󰻃" or ""
						local buftype = api.nvim_get_option_value("buftype", { buf = bufnr })
						local type_indicator = buftype == "terminal" and " 󰓫" or ""
						table.insert(
							info,
							string.format("%2d. %s%s%s%s%s", i, filename, modified, readonly, type_indicator, current)
						)
					end
				end
				table.insert(info, string.rep("─", 50))
				table.insert(info, string.format("Total: %d buffer(s)", #buffers))
				local buf = api.nvim_create_buf(false, true)
				api.nvim_buf_set_lines(buf, 0, -1, false, info)
				local width = math.max(60, math.min(vim.o.columns - 10, 80))
				local height = math.min(#info + 2, vim.o.lines - 10)
				local opts = {
					relative = "editor",
					width = width,
					height = height,
					col = math.floor((vim.o.columns - width) / 2),
					row = math.floor((vim.o.lines - height) / 2),
					style = "minimal",
					border = "rounded",
					title = " Buffer Info ",
					title_pos = "center",
				}
				local win = api.nvim_open_win(buf, true, opts)
				api.nvim_set_option_value("filetype", "heirline-info", { buf = buf })
				vim.keymap.set("n", "<Esc>", function()
					if api.nvim_win_is_valid(win) then
						api.nvim_win_close(win, true)
					end
				end, { buffer = buf, nowait = true })
				vim.keymap.set("n", "q", function()
					if api.nvim_win_is_valid(win) then
						api.nvim_win_close(win, true)
					end
				end, { buffer = buf, nowait = true })
			end, { desc = "Show detailed buffer information" })

			api.nvim_create_user_command("BufferCleanup", function()
				M.safe_call(function()
					local buffers = get_bufs()
					local current = api.nvim_get_current_buf()
					local cleaned = 0
					for _, bufnr in ipairs(buffers) do
						if bufnr ~= current and api.nvim_buf_is_valid(bufnr) then
							local modified = api.nvim_get_option_value("modified", { buf = bufnr })
							local name = api.nvim_buf_get_name(bufnr)
							if not modified and (M.is_empty(name) or name:match "^/tmp/" or name:match "scratch") then
								api.nvim_buf_delete(bufnr, {})
								cleaned = cleaned + 1
							end
						end
					end
					vim.notify(string.format("󰆴 Cleaned up %d buffer(s)", cleaned), vim.log.levels.INFO)
				end)
			end, { desc = "Clean up empty and scratch buffers" })

			api.nvim_create_user_command("ThemeToggle", function()
				local flavors = { "latte", "frappe", "macchiato", "mocha" }
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
				vim.notify(string.format("󰏘 Theme: %s", next_flavor:gsub("^%l", string.upper)), vim.log.levels.INFO)
			end, { desc = "Toggle between catppuccin themes" })
		end,
	},
}
