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
			-- ========================================
			-- IMPORTS AND SETUP
			-- ========================================

			local conditions = require "heirline.conditions"
			local utils = require "heirline.utils"
			local devicons = require "nvim-web-devicons"
			local colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")

			-- Cache API functions for performance
			local api, fn, bo, go = vim.api, vim.fn, vim.bo, vim.go
			local diagnostic = vim.diagnostic

			-- ========================================
			-- UTILITIES
			-- ========================================

			local function is_empty(s)
				return s == nil or s == ""
			end

			local function safe_call(func, default)
				local ok, result = pcall(func)
				return ok and result or default
			end

			-- Get window width safely
			local function get_win_width(winid)
				return safe_call(function()
					return api.nvim_win_is_valid(winid) and api.nvim_win_get_width(winid) or 0
				end, 0)
			end

			-- ========================================
			-- BASIC COMPONENTS
			-- ========================================

			local Space = { provider = " " }
			local Spacer = { provider = "  " }
			local Align = { provider = "%=" }
			local Separator = {
				provider = "  ",
				hl = { fg = colors.surface1 },
			}

			-- ========================================
			-- STATUS LINE COMPONENTS (keeping existing ones)
			-- ========================================

			-- Mode component
			local Mode = {
				init = function(self)
					self.mode = fn.mode()
				end,
				static = {
					mode_map = {
						n = { icon = "", name = "NORMAL", color = colors.blue },
						i = { icon = "", name = "INSERT", color = colors.green },
						v = { icon = "󰒅", name = "VISUAL", color = colors.mauve },
						V = { icon = "󰒅", name = "V-LINE", color = colors.mauve },
						["\22"] = { icon = "󰒅", name = "V-BLOCK", color = colors.mauve },
						c = { icon = "󰞷", name = "COMMAND", color = colors.peach },
						R = { icon = "󰛔", name = "REPLACE", color = colors.red },
						t = { icon = "󰓫", name = "TERMINAL", color = colors.yellow },
						s = { icon = "󰒅", name = "SELECT", color = colors.teal },
						S = { icon = "󰒅", name = "S-LINE", color = colors.teal },
					},
				},
				provider = function(self)
					local mode_info = self.mode_map[self.mode]
					if mode_info then
						return string.format(" %s %s ", mode_info.icon, mode_info.name)
					end
					return string.format(" 󰜅 %s ", self.mode:upper())
				end,
				hl = function(self)
					local mode_info = self.mode_map[self.mode]
					local bg = mode_info and mode_info.color or colors.surface1
					return { fg = colors.base, bg = bg, bold = true }
				end,
				update = { "ModeChanged", "BufEnter" },
			}

			-- File info component
			local FileInfo = {
				init = function(self)
					self.filename = fn.expand "%:t"
					self.filepath = fn.expand "%:p"
					self.filetype = bo.filetype
					self.modified = bo.modified
					self.readonly = bo.readonly
				end,
				{
					provider = function(self)
						if is_empty(self.filename) then
							return "󰈔 [No Name]"
						end
						local icon, _ = devicons.get_icon_color(self.filename, fn.expand "%:e", { default = true })
						return string.format("%s %s", icon or "󰈔", self.filename)
					end,
					hl = function(self)
						local _, icon_color =
							devicons.get_icon_color(self.filename, fn.expand "%:e", { default = true })
						return { fg = icon_color or colors.text }
					end,
				},
				{
					provider = function(self)
						local status = {}
						if self.modified then
							table.insert(status, "󰜄")
						end
						if self.readonly then
							table.insert(status, "󰌾")
						end
						return #status > 0 and (" " .. table.concat(status, " ")) or ""
					end,
					hl = function(self)
						if self.modified then
							return { fg = colors.peach, bold = true }
						elseif self.readonly then
							return { fg = colors.red }
						end
					end,
				},
				update = { "BufModifiedSet", "BufEnter", "BufWritePost" },
			}

			-- Git component
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
						added = "󰐕",
						changed = "󰜥",
						removed = "󰍵",
						branch = "",
					},
				},
				{
					provider = function(self)
						if is_empty(self.head) then
							return ""
						end
						return string.format(" %s %s", self.icons.branch, self.head)
					end,
					hl = { fg = colors.peach, bold = true },
				},
				{
					condition = function(self)
						return self.has_changes
					end,
					provider = function(self)
						local changes = {}
						if self.added > 0 then
							table.insert(changes, string.format("%%#GitAdded#%s %d%%*", self.icons.added, self.added))
						end
						if self.changed > 0 then
							table.insert(
								changes,
								string.format("%%#GitChanged#%s %d%%*", self.icons.changed, self.changed)
							)
						end
						if self.removed > 0 then
							table.insert(
								changes,
								string.format("%%#GitRemoved#%s %d%%*", self.icons.removed, self.removed)
							)
						end
						return " " .. table.concat(changes, " ")
					end,
				},
				update = { "User", pattern = "GitSignsUpdate" },
			}

			-- Diagnostics component
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
						return self.errors > 0 and string.format(" %s %d", self.icons.error, self.errors) or ""
					end,
					hl = { fg = colors.red, bold = true },
				},
				{
					provider = function(self)
						return self.warnings > 0 and string.format(" %s %d", self.icons.warn, self.warnings) or ""
					end,
					hl = { fg = colors.yellow, bold = true },
				},
				{
					provider = function(self)
						return self.infos > 0 and string.format(" %s %d", self.icons.info, self.infos) or ""
					end,
					hl = { fg = colors.blue, bold = true },
				},
				{
					provider = function(self)
						return self.hints > 0 and string.format(" %s %d", self.icons.hint, self.hints) or ""
					end,
					hl = { fg = colors.mauve, bold = true },
				},
				update = { "DiagnosticChanged", "BufEnter" },
			}

			-- Search info component
			local SearchInfo = {
				condition = function()
					return vim.v.hlsearch ~= 0
				end,
				init = function(self)
					self.search = safe_call(fn.searchcount, {})
				end,
				provider = function(self)
					if not self.search or not self.search.total or self.search.total == 0 then
						return ""
					end
					return string.format(" 󰍉 %d/%d", self.search.current, self.search.total)
				end,
				hl = { fg = colors.yellow, bold = true },
			}

			-- LSP clients component
			local LSPClients = {
				condition = conditions.lsp_attached,
				init = function(self)
					local clients = {}
					for _, client in ipairs(vim.lsp.get_clients { bufnr = 0 }) do
						local name = client.name
						if name ~= "null-ls" and name ~= "copilot" and name ~= "GitHub Copilot" then
							table.insert(clients, name)
						end
					end
					self.clients = clients
				end,
				static = {
					max_len = 30,
					icon = "󰒋",
				},
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
				hl = { fg = colors.mauve, bold = true },
				update = { "LspAttach", "LspDetach" },
			}

			-- File encoding component
			local FileEncoding = {
				provider = function()
					return string.format("󰈍 %s", bo.fileencoding)
				end,
				hl = { fg = colors.overlay2 },
			}

			-- Position component
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
							return string.format("󰍎 %d/%d", self.row, self.lines)
						end,
						hl = { fg = colors.blue, bold = true },
					},
					Space,
					{
						provider = function(self)
							return string.format("󰘭 %d", self.col)
						end,
						hl = { fg = colors.mauve },
					},
					Space,
					{
						provider = function(self)
							return string.format("%d%%", self.percent)
						end,
						hl = { fg = colors.green },
					},
				},
				{
					{
						provider = function(self)
							return string.format("󰍎 %d/%d", self.row, self.lines)
						end,
						hl = { fg = colors.blue, bold = true },
					},
					Space,
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

			-- Scroll bar component
			local ScrollBar = {
				static = {
					sbar = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" },
				},
				provider = function(self)
					local curr_line = api.nvim_win_get_cursor(0)[1]
					local lines = api.nvim_buf_line_count(0)
					if lines <= 1 then
						return self.sbar[#self.sbar]
					end
					local i = math.min(math.floor((curr_line - 1) / lines * #self.sbar) + 1, #self.sbar)
					return string.rep(self.sbar[i], 2)
				end,
				hl = { fg = colors.blue },
			}

			-- ========================================
			-- IMPROVED TABLINE COMPONENTS
			-- ========================================

			-- Tabline offset for sidebar plugins like nvim-tree
			local TablineOffset = {
				condition = function(self)
					-- Check first window in tabpage for sidebar plugins
					local wins = api.nvim_tabpage_list_wins(0)
					if #wins == 0 then
						return false
					end

					local win = wins[1]
					if not api.nvim_win_is_valid(win) then
						return false
					end

					local bufnr = api.nvim_win_get_buf(win)
					local filetype = safe_call(function()
						return vim.bo[bufnr].filetype
					end, "")
					local buftype = safe_call(function()
						return vim.bo[bufnr].buftype
					end, "")

					self.winid = win

					-- Handle different sidebar plugins
					if filetype == "NvimTree" then
						self.title = "󰙅 NvimTree"
						self.hl_group = "NvimTreeNormal"
						return true
					elseif filetype == "neo-tree" then
						self.title = "󰙅 Neo-tree"
						self.hl_group = "NeoTreeNormal"
						return true
					elseif filetype == "CHADTree" then
						self.title = "󰙅 CHADTree"
						self.hl_group = "CHADTreeNormal"
						return true
					elseif filetype == "nerdtree" then
						self.title = "󰙅 NERDTree"
						self.hl_group = "NERDTree"
						return true
					elseif filetype == "Outline" then
						self.title = "󰙅 Outline"
						self.hl_group = "OutlineNormal"
						return true
					elseif filetype == "tagbar" then
						self.title = "󰙅 Tagbar"
						self.hl_group = "TagbarNormal"
						return true
					elseif buftype == "terminal" then
						self.title = "󰓫 Terminal"
						self.hl_group = "StatusLine"
						return true
					end

					return false
				end,

				provider = function(self)
					local width = get_win_width(self.winid)
					if width == 0 then
						return ""
					end

					local title = self.title
					local title_len = vim.fn.strdisplaywidth(title)

					-- Calculate padding to center the title
					local pad = math.max(0, math.floor((width - title_len) / 2))
					local right_pad = math.max(0, width - title_len - pad)

					return string.rep(" ", pad) .. title .. string.rep(" ", right_pad)
				end,

				hl = function(self)
					-- Use appropriate highlight group based on focus
					if api.nvim_get_current_win() == self.winid then
						return { bg = colors.surface0, fg = colors.text, bold = true }
					else
						return { bg = colors.base, fg = colors.overlay1 }
					end
				end,

				update = { "WinEnter", "BufEnter", "WinResized" },
			}

			-- Optimized tabline file icon
			local TablineFileIcon = {
				init = function(self)
					self.filename = safe_call(function()
						return api.nvim_buf_get_name(self.bufnr)
					end, "")
					self.extension = fn.fnamemodify(self.filename, ":e")
				end,
				provider = function(self)
					if is_empty(self.filename) then
						return "󰈔"
					end
					local icon = devicons.get_icon(self.filename, self.extension, { default = true })
					return icon or "󰈔"
				end,
				hl = function(self)
					if is_empty(self.filename) then
						return { fg = colors.text }
					end
					local _, icon_color = devicons.get_icon_color(self.filename, self.extension, { default = true })
					return { fg = icon_color or colors.text }
				end,
			}

			-- Improved tabline file name with better truncation
			local TablineFileName = {
				provider = function(self)
					local filename = self.filename
					filename = filename == "" and "[No Name]" or fn.fnamemodify(filename, ":t")

					-- Smart truncation based on available space
					local max_len = 25
					if vim.o.columns < 120 then
						max_len = 15
					elseif vim.o.columns > 200 then
						max_len = 35
					end

					if #filename > max_len then
						filename = filename:sub(1, max_len - 3) .. "..."
					end

					return filename
				end,
				hl = function(self)
					return {
						bold = self.is_active,
						italic = not self.is_active,
						fg = self.is_active and colors.text or colors.overlay1,
					}
				end,
			}

			-- Enhanced tabline file flags
			local TablineFileFlags = {
				{
					condition = function(self)
						return safe_call(function()
							return api.nvim_get_option_value("modified", { buf = self.bufnr })
						end, false)
					end,
					provider = " 󰜄",
					hl = { fg = colors.green, bold = true },
				},
				{
					condition = function(self)
						local not_modifiable = safe_call(function()
							return not api.nvim_get_option_value("modifiable", { buf = self.bufnr })
						end, false)
						local readonly = safe_call(function()
							return api.nvim_get_option_value("readonly", { buf = self.bufnr })
						end, false)
						return not_modifiable or readonly
					end,
					provider = function(self)
						local buftype = safe_call(function()
							return api.nvim_get_option_value("buftype", { buf = self.bufnr })
						end, "")
						if buftype == "terminal" then
							return " 󰓫"
						else
							return " 󰌾"
						end
					end,
					hl = { fg = colors.peach },
				},
			}

			-- Buffer picker with improved label selection
			local TablinePicker = {
				condition = function(self)
					return self._show_picker
				end,
				init = function(self)
					local bufname = safe_call(function()
						return api.nvim_buf_get_name(self.bufnr)
					end, "")
					bufname = fn.fnamemodify(bufname, ":t")
					if bufname == "" then
						bufname = "unnamed"
					end

					-- Try to find a unique label
					local label = bufname:sub(1, 1):upper()
					local i = 2
					while self._picker_labels[label] and i <= #bufname do
						label = bufname:sub(i, i):upper()
						i = i + 1
					end

					-- If no unique letter found, use numbers
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
					return " " .. self.label .. " "
				end,
				hl = { fg = colors.base, bg = colors.red, bold = true },
			}

			-- Main tabline file name block
			local TablineFileNameBlock = {
				init = function(self)
					self.filename = safe_call(function()
						return api.nvim_buf_get_name(self.bufnr)
					end, "")
				end,
				hl = function(self)
					if self.is_active then
						return { bg = colors.surface0, fg = colors.text }
					else
						return { bg = colors.base, fg = colors.overlay1 }
					end
				end,
				on_click = {
					callback = function(_, minwid, _, button)
						vim.schedule(function()
							safe_call(function()
								if button == "m" then -- Middle click to close
									if api.nvim_buf_is_valid(minwid) and api.nvim_buf_is_loaded(minwid) then
										local modified = api.nvim_get_option_value("modified", { buf = minwid })
										if modified then
											local choice = fn.confirm(
												"Buffer has unsaved changes. Save before closing?",
												"&Save\n&Discard\n&Cancel",
												3
											)
											if choice == 1 then
												vim.cmd("buffer " .. minwid)
												vim.cmd "write"
												api.nvim_buf_delete(minwid, { force = false })
											elseif choice == 2 then
												api.nvim_buf_delete(minwid, { force = true })
											end
										else
											api.nvim_buf_delete(minwid, { force = false })
										end
										vim.cmd.redrawtabline()
									end
								else -- Left click to switch
									if api.nvim_buf_is_valid(minwid) then
										api.nvim_win_set_buf(0, minwid)
									end
								end
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

			-- Close button for buffers
			local TablineCloseButton = {
				condition = function(self)
					local modified = safe_call(function()
						return api.nvim_get_option_value("modified", { buf = self.bufnr })
					end, false)
					return not modified
				end,
				{
					provider = "󰅖 ",
					hl = { fg = colors.overlay1 },
					on_click = {
						callback = function(_, minwid)
							vim.schedule(function()
								safe_call(function()
									api.nvim_buf_delete(minwid, { force = false })
									vim.cmd.redrawtabline()
								end)
							end)
						end,
						minwid = function(self)
							return self.bufnr
						end,
						name = "heirline_tabline_close_buffer_callback",
					},
				},
			}

			-- Final tabline buffer block with improved styling
			local TablineBufferBlock = utils.surround({ "", "" }, function(self)
				if self.is_active then
					return colors.surface0
				else
					return colors.base
				end
			end, {
				TablinePicker,
				TablineFileNameBlock,
				TablineCloseButton,
			})

			-- ========================================
			-- BUFFER MANAGEMENT (Enhanced)
			-- ========================================

			local buflist_cache = {}

			-- Improved buffer filtering
			local function get_bufs()
				return safe_call(function()
					return vim.tbl_filter(function(bufnr)
						if not api.nvim_buf_is_valid(bufnr) then
							return false
						end

						local buftype = api.nvim_get_option_value("buftype", { buf = bufnr })
						local filetype = api.nvim_get_option_value("filetype", { buf = bufnr })
						local buflisted = api.nvim_get_option_value("buflisted", { buf = bufnr })

						-- Filter out special buffers
						if buftype ~= "" and buftype ~= "terminal" then
							return false
						end

						-- Filter out certain filetypes
						local excluded_filetypes = {
							"help",
							"alpha",
							"dashboard",
							"NvimTree",
							"Trouble",
							"lir",
							"Outline",
							"spectre_panel",
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

			-- Create buffer line with offset support
			local BufferLine = {
				TablineOffset,
				utils.make_buflist(
					TablineBufferBlock,
					{ provider = "󰍞 ", hl = { fg = colors.overlay1 } }, -- left truncation
					{ provider = " 󰍟", hl = { fg = colors.overlay1 } }, -- right truncation
					function()
						return buflist_cache
					end,
					false -- no internal cache
				),
			}

			-- ========================================
			-- MAIN COMPONENTS
			-- ========================================

			local StatusLine = {
				hl = function()
					return conditions.is_active() and "StatusLine" or "StatusLineNC"
				end,
				-- Left section
				Mode,
				Spacer,
				FileInfo,
				Git,
				Diagnostics,
				Space,
				SearchInfo,
				-- Center alignment
				Align,
				-- Right section
				LSPClients,
				Spacer,
				FileEncoding,
				Separator,
				Position,
				Spacer,
				ScrollBar,
			}

			local TabLine = BufferLine

			-- ========================================
			-- HIGHLIGHT SETUP
			-- ========================================

			local function setup_highlights()
				local highlights = {
					GitAdded = { fg = colors.green, bold = true },
					GitChanged = { fg = colors.yellow, bold = true },
					GitRemoved = { fg = colors.red, bold = true },
				}
				for group, hl in pairs(highlights) do
					api.nvim_set_hl(0, group, hl)
				end
			end

			-- ========================================
			-- INITIALIZATION
			-- ========================================

			require("heirline").setup {
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
							},
						}, args.buf)
					end,
				},
			}

			setup_highlights()

			-- ========================================
			-- ENHANCED AUTOCOMMANDS
			-- ========================================

			local augroup = api.nvim_create_augroup("HeirlineOptimizedTabline", { clear = true })

			-- Buffer list management with better performance
			api.nvim_create_autocmd({ "VimEnter", "UIEnter", "BufAdd", "BufDelete", "BufWipeout" }, {
				group = augroup,
				callback = function()
					vim.schedule(function()
						safe_call(function()
							local buffers = get_bufs()

							-- Update cache efficiently
							for i, v in ipairs(buffers) do
								buflist_cache[i] = v
							end
							for i = #buffers + 1, #buflist_cache do
								buflist_cache[i] = nil
							end

							-- Smart tabline visibility
							if #buflist_cache > 1 then
								go.showtabline = 2
							elseif go.showtabline ~= 1 then
								go.showtabline = 1
							end
						end)
					end)
				end,
			})

			-- Handle nvim-tree and other sidebar events
			api.nvim_create_autocmd({ "BufEnter", "WinEnter", "WinClosed" }, {
				group = augroup,
				callback = function()
					vim.schedule(function()
						vim.cmd.redrawtabline()
					end)
				end,
			})

			-- Color scheme updates
			api.nvim_create_autocmd("ColorScheme", {
				group = augroup,
				callback = function()
					colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")
					setup_highlights()
					vim.cmd.redrawtabline()
				end,
			})

			-- Performance optimizations
			api.nvim_create_autocmd("InsertEnter", {
				group = augroup,
				callback = function()
					go.updatetime = 1000
				end,
			})

			api.nvim_create_autocmd("InsertLeave", {
				group = augroup,
				callback = function()
					go.updatetime = 300
				end,
			})

			-- Refresh on resize with debouncing
			local resize_timer = nil
			api.nvim_create_autocmd("VimResized", {
				group = augroup,
				callback = function()
					if resize_timer then
						fn.timer_stop(resize_timer)
					end
					resize_timer = fn.timer_start(100, function()
						vim.schedule(function()
							vim.cmd "redrawstatus | redrawtabline"
						end)
						resize_timer = nil
					end)
				end,
			})

			-- Handle window focus changes for better nvim-tree integration
			api.nvim_create_autocmd({ "WinEnter", "WinLeave" }, {
				group = augroup,
				callback = function()
					-- Small delay to ensure window states are updated
					vim.schedule(function()
						vim.defer_fn(function()
							vim.cmd.redrawtabline()
						end, 10)
					end)
				end,
			})

			-- ========================================
			-- ENHANCED KEYMAPS
			-- ========================================

			-- Improved buffer picker with error handling
			vim.keymap.set("n", "gbp", function()
				safe_call(function()
					local tabline = require("heirline").tabline
					if not tabline or not tabline._buflist or not tabline._buflist[1] then
						vim.notify("No buffers available for picking", vim.log.levels.WARN)
						return
					end

					local buflist = tabline._buflist[1]
					if not buflist then
						vim.notify("Buffer list not available", vim.log.levels.WARN)
						return
					end

					buflist._picker_labels = {}
					buflist._show_picker = true
					vim.cmd.redrawtabline()

					-- Show instruction
					vim.notify("Pick buffer: press label key", vim.log.levels.INFO)

					local char = fn.getcharstr():upper()
					local bufnr = buflist._picker_labels[char]

					if bufnr and api.nvim_buf_is_valid(bufnr) then
						api.nvim_win_set_buf(0, bufnr)
						vim.notify("Switched to buffer: " .. fn.fnamemodify(api.nvim_buf_get_name(bufnr), ":t"))
					else
						vim.notify("Invalid selection or buffer not found", vim.log.levels.WARN)
					end

					buflist._show_picker = false
					vim.cmd.redrawtabline()
				end)
			end, { desc = "Pick buffer from tabline" })

			-- Enhanced buffer navigation
			local function safe_buffer_nav(cmd, desc)
				return function()
					safe_call(function()
						vim.cmd(cmd)
					end)
				end
			end

			vim.keymap.set("n", "<leader>bn", safe_buffer_nav "bnext", { desc = "Next buffer" })
			vim.keymap.set("n", "<leader>bp", safe_buffer_nav "bprevious", { desc = "Previous buffer" })

			-- Smart buffer delete that handles modified buffers
			vim.keymap.set("n", "<leader>bd", function()
				safe_call(function()
					local bufnr = api.nvim_get_current_buf()
					local modified = api.nvim_get_option_value("modified", { buf = bufnr })

					if modified then
						local filename = fn.fnamemodify(api.nvim_buf_get_name(bufnr), ":t")
						if filename == "" then
							filename = "[No Name]"
						end

						local choice = fn.confirm(
							string.format("Buffer '%s' has unsaved changes. Save before closing?", filename),
							"&Save and close\n&Close without saving\n&Cancel",
							3
						)

						if choice == 1 then
							vim.cmd "write"
							vim.cmd "bdelete"
						elseif choice == 2 then
							vim.cmd "bdelete!"
						end
					else
						vim.cmd "bdelete"
					end
				end)
			end, { desc = "Delete buffer" })

			-- Close all buffers except current
			vim.keymap.set("n", "<leader>bo", function()
				safe_call(function()
					local current = api.nvim_get_current_buf()
					local buffers = get_bufs()

					for _, bufnr in ipairs(buffers) do
						if bufnr ~= current and api.nvim_buf_is_valid(bufnr) then
							local modified = api.nvim_get_option_value("modified", { buf = bufnr })
							if not modified then
								api.nvim_buf_delete(bufnr, { force = false })
							end
						end
					end

					vim.notify "Closed all unmodified buffers except current"
				end)
			end, { desc = "Close all other buffers" })

			-- Quick buffer switching with numbers (1-9)
			for i = 1, 9 do
				vim.keymap.set("n", "<leader>b" .. i, function()
					safe_call(function()
						local buffers = get_bufs()
						if buffers[i] and api.nvim_buf_is_valid(buffers[i]) then
							api.nvim_win_set_buf(0, buffers[i])
							local filename = fn.fnamemodify(api.nvim_buf_get_name(buffers[i]), ":t")
							if filename == "" then
								filename = "[No Name]"
							end
							vim.notify("Switched to buffer " .. i .. ": " .. filename)
						else
							vim.notify("Buffer " .. i .. " not available", vim.log.levels.WARN)
						end
					end)
				end, { desc = "Switch to buffer " .. i })
			end

			-- Cycle through buffers with Tab/Shift-Tab
			vim.keymap.set("n", "<Tab>", safe_buffer_nav "bnext", { desc = "Next buffer" })
			vim.keymap.set("n", "<S-Tab>", safe_buffer_nav "bprevious", { desc = "Previous buffer" })

			-- Move buffers left/right in tabline
			vim.keymap.set("n", "<leader>bmh", function()
				safe_call(function()
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
						-- Update cache
						for i, v in ipairs(buffers) do
							buflist_cache[i] = v
						end
						vim.cmd.redrawtabline()
						vim.notify "Moved buffer left"
					end
				end)
			end, { desc = "Move buffer left" })

			vim.keymap.set("n", "<leader>bml", function()
				safe_call(function()
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
						-- Update cache
						for i, v in ipairs(buffers) do
							buflist_cache[i] = v
						end
						vim.cmd.redrawtabline()
						vim.notify "Moved buffer right"
					end
				end)
			end, { desc = "Move buffer right" })

			-- Toggle between last two buffers
			vim.keymap.set("n", "<leader><leader>", function()
				safe_call(function()
					vim.cmd "buffer #"
				end)
			end, { desc = "Toggle last buffer" })

			-- Force refresh tabline
			vim.keymap.set("n", "<leader>br", function()
				vim.cmd "redrawtabline"
				vim.notify "Tabline refreshed"
			end, { desc = "Refresh tabline" })

			-- ========================================
			-- COMMANDS
			-- ========================================

			-- Command to toggle tabline visibility
			api.nvim_create_user_command("TablineToggle", function()
				if go.showtabline == 0 then
					go.showtabline = 2
					vim.notify "Tabline enabled"
				else
					go.showtabline = 0
					vim.notify "Tabline disabled"
				end
			end, { desc = "Toggle tabline visibility" })

			-- Command to show buffer info
			api.nvim_create_user_command("BufferInfo", function()
				local buffers = get_bufs()
				local info = {}

				table.insert(info, "Buffer List:")
				table.insert(info, string.rep("=", 50))

				for i, bufnr in ipairs(buffers) do
					local name = api.nvim_buf_get_name(bufnr)
					local filename = name == "" and "[No Name]" or fn.fnamemodify(name, ":t")
					local modified = api.nvim_get_option_value("modified", { buf = bufnr }) and " [+]" or ""
					local current = bufnr == api.nvim_get_current_buf() and " (current)" or ""

					table.insert(info, string.format("%d. %s%s%s", i, filename, modified, current))
				end

				vim.notify(table.concat(info, "\n"), vim.log.levels.INFO)
			end, { desc = "Show buffer information" })
		end,
	},
}
