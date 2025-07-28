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
			-- STATUS LINE COMPONENTS
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
			-- TABLINE COMPONENTS
			-- ========================================

			-- Tabline file icon
			local TablineFileIcon = {
				init = function(self)
					self.filename = api.nvim_buf_get_name(self.bufnr)
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

			-- Tabline file name
			local TablineFileName = {
				provider = function(self)
					local filename = self.filename
					filename = filename == "" and "[No Name]" or fn.fnamemodify(filename, ":t")

					-- Truncate long filenames
					if #filename > 25 then
						filename = filename:sub(1, 22) .. "..."
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

			-- Tabline file flags
			local TablineFileFlags = {
				{
					condition = function(self)
						return api.nvim_get_option_value("modified", { buf = self.bufnr })
					end,
					provider = " [+]",
					hl = { fg = colors.green, bold = true },
				},
				{
					condition = function(self)
						return not api.nvim_get_option_value("modifiable", { buf = self.bufnr })
							or api.nvim_get_option_value("readonly", { buf = self.bufnr })
					end,
					provider = function(self)
						if api.nvim_get_option_value("buftype", { buf = self.bufnr }) == "terminal" then
							return " 󰓫"
						else
							return " "
						end
					end,
					hl = { fg = colors.peach },
				},
			}

			-- Buffer picker
			local TablinePicker = {
				condition = function(self)
					return self._show_picker
				end,
				init = function(self)
					local bufname = api.nvim_buf_get_name(self.bufnr)
					bufname = fn.fnamemodify(bufname, ":t")
					local label = bufname:sub(1, 1):upper()
					local i = 2
					while self._picker_labels[label] do
						if i > #bufname then
							break
						end
						label = bufname:sub(i, i):upper()
						i = i + 1
					end
					self._picker_labels[label] = self.bufnr
					self.label = label
				end,
				provider = function(self)
					return self.label
				end,
				hl = { fg = colors.red, bg = colors.yellow, bold = true },
			}

			-- Tabline file name block
			local TablineFileNameBlock = {
				init = function(self)
					self.filename = api.nvim_buf_get_name(self.bufnr)
				end,
				hl = function(self)
					if self.is_active then
						return "TabLineSel"
					else
						return "TabLine"
					end
				end,
				on_click = {
					callback = function(_, minwid, _, button)
						vim.schedule(function()
							if button == "m" then
								safe_call(function()
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
								end)
							else
								safe_call(function()
									if api.nvim_buf_is_valid(minwid) then
										api.nvim_win_set_buf(0, minwid)
									end
								end)
							end
						end)
					end,
					minwid = function(self)
						return self.bufnr
					end,
					name = "heirline_tabline_buffer_callback",
				},
				TablineFileIcon,
				{ provider = " " },
				TablineFileName,
				TablineFileFlags,
			}

			-- Final tabline buffer block
			local TablineBufferBlock = utils.surround({ "", "" }, function(self)
				if self.is_active then
					return utils.get_highlight("TabLineSel").bg
				else
					return utils.get_highlight("TabLine").bg
				end
			end, {
				TablinePicker,
				TablineFileNameBlock,
			})

			-- ========================================
			-- BUFFER MANAGEMENT
			-- ========================================

			local buflist_cache = {}

			local function get_bufs()
				return safe_call(function()
					return vim.tbl_filter(function(bufnr)
						return api.nvim_buf_is_valid(bufnr)
							and api.nvim_get_option_value("buflisted", { buf = bufnr })
							and api.nvim_buf_get_name(bufnr) ~= ""
					end, api.nvim_list_bufs())
				end, {})
			end

			local BufferLine = utils.make_buflist(
				TablineBufferBlock,
				{ provider = "󰍞", hl = { fg = colors.overlay1 } },
				{ provider = "󰍟", hl = { fg = colors.overlay1 } },
				function()
					return buflist_cache
				end,
				false
			)

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

			local TabLine = {
				BufferLine,
			}

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
			-- AUTOCOMMANDS
			-- ========================================

			local augroup = api.nvim_create_augroup("HeirlineOptimized", { clear = true })

			-- Buffer list management
			api.nvim_create_autocmd({ "VimEnter", "UIEnter", "BufAdd", "BufDelete", "BufWipeout" }, {
				group = augroup,
				callback = function()
					vim.schedule(function()
						safe_call(function()
							local buffers = get_bufs()
							for i, v in ipairs(buffers) do
								buflist_cache[i] = v
							end
							for i = #buffers + 1, #buflist_cache do
								buflist_cache[i] = nil
							end

							-- Smart tabline visibility
							if #buflist_cache > 1 then
								go.showtabline = 2
							else
								go.showtabline = 1
							end
						end)
					end)
				end,
			})

			-- Color scheme updates
			api.nvim_create_autocmd("ColorScheme", {
				group = augroup,
				callback = function()
					colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")
					setup_highlights()
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

			-- Refresh on resize
			api.nvim_create_autocmd("VimResized", {
				group = augroup,
				callback = function()
					vim.cmd "redrawstatus | redrawtabline"
				end,
			})

			-- ========================================
			-- KEYMAPS
			-- ========================================

			-- Buffer picker
			vim.keymap.set("n", "gbp", function()
				safe_call(function()
					local tabline = require("heirline").tabline
					if not tabline or not tabline._buflist or not tabline._buflist[1] then
						return
					end

					local buflist = tabline._buflist[1]
					buflist._picker_labels = {}
					buflist._show_picker = true
					vim.cmd.redrawtabline()

					local char = fn.getcharstr():upper()
					local bufnr = buflist._picker_labels[char]

					if bufnr and api.nvim_buf_is_valid(bufnr) then
						api.nvim_win_set_buf(0, bufnr)
					end

					buflist._show_picker = false
					vim.cmd.redrawtabline()
				end)
			end, { desc = "Pick buffer from tabline" })

			-- Buffer navigation
			local function safe_buffer_nav(cmd, fallback_msg)
				return function()
					safe_call(function()
						vim.cmd(cmd)
					end)
				end
			end

			vim.keymap.set("n", "<leader>bn", safe_buffer_nav "bnext", { desc = "Next buffer" })
			vim.keymap.set("n", "<leader>bp", safe_buffer_nav "bprevious", { desc = "Previous buffer" })
			vim.keymap.set("n", "<leader>bd", safe_buffer_nav "bdelete", { desc = "Delete buffer" })

			-- Quick buffer switching with numbers
			for i = 1, 9 do
				vim.keymap.set("n", "<leader>" .. i, function()
					local buffers = get_bufs()
					if buffers[i] and api.nvim_buf_is_valid(buffers[i]) then
						api.nvim_win_set_buf(0, buffers[i])
					end
				end, { desc = "Switch to buffer " .. i })
			end
		end,
	},
}
