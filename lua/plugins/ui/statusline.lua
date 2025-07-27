return {
	{
		"rebelot/heirline.nvim", -- Plugin for customizable statusline and winbar
		event = "VeryLazy", -- Load plugin on VeryLazy event to optimize startup time
		dependencies = {
			"nvim-tree/nvim-web-devicons", -- Provides file type icons
			"neovim/nvim-lspconfig", -- LSP configuration for Neovim
			"lewis6991/gitsigns.nvim", -- Git integration for signs and status
			"catppuccin/nvim", -- Catppuccin theme for color palette
		},
		config = function()
			-- Import required modules
			local conditions = require "heirline.conditions"
			local utils = require "heirline.utils"
			local devicons = require "nvim-web-devicons"
			local colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")

			-- Cache frequently used Vim functions for performance
			local api = vim.api
			local fn = vim.fn
			local bo = vim.bo
			local diagnostic = vim.diagnostic

			-- Utility function to check if a string is empty
			local function is_empty(s)
				return s == nil or s == ""
			end

			-- Basic components for spacing and alignment
			local Space = { provider = " " } -- Single space component
			local Spacer = { provider = "  " } -- Double space component
			local Align = { provider = "%=" } -- Alignment component for centering
			local Separator = {
				provider = "  ", -- Separator with custom highlight
				hl = { fg = colors.surface1 },
			}

			-- Mode component: Displays current Vim mode with icon and name
			local Mode = {
				init = function(self)
					self.mode = fn.mode() -- Get current Vim mode
				end,
				static = {
					-- Mapping of modes to their icons, names, and colors
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
						return string.format(" %s %s ", mode_info.icon, mode_info.name) -- Display mode icon and name
					end
					return string.format(" 󰜅 %s ", self.mode:upper()) -- Fallback for unknown modes
				end,
				hl = function(self)
					local mode_info = self.mode_map[self.mode]
					local bg = mode_info and mode_info.color or colors.surface1 -- Set background color based on mode
					return { fg = colors.base, bg = bg, bold = true }
				end,
				update = { "ModeChanged", "BufEnter" }, -- Update on mode change or buffer enter
			}

			-- FileIcon component for tabline
			local FileIcon = {
				init = function(self)
					self.filename = self.filename or api.nvim_buf_get_name(self.bufnr)
				end,
				provider = function(self)
					local filename = self.filename
					if filename == "" then
						return "󰈔"
					end
					local extension = fn.fnamemodify(filename, ":e")
					local icon, icon_color = devicons.get_icon_color(filename, extension, { default = true })
					return icon or "󰈔"
				end,
				hl = function(self)
					local filename = self.filename
					if filename == "" then
						return { fg = colors.text }
					end
					local extension = fn.fnamemodify(filename, ":e")
					local _, icon_color = devicons.get_icon_color(filename, extension, { default = true })
					return { fg = icon_color or colors.text }
				end,
			}

			-- FileInfo component: Displays file name, icon, and status (modified/readonly)
			local FileInfo = {
				init = function(self)
					self.filename = fn.expand "%:t" -- Get file name
					self.filepath = fn.expand "%:p" -- Get full file path
					self.filetype = bo.filetype -- Get file type
					self.modified = bo.modified -- Check if buffer is modified
					self.readonly = bo.readonly -- Check if buffer is readonly
				end,
				{
					-- Subcomponent: File icon and name
					provider = function(self)
						if is_empty(self.filename) then
							return "󰈔 [No Name]" -- Display for unnamed buffers
						end
						local icon, icon_color =
							devicons.get_icon_color(self.filename, fn.expand "%:e", { default = true })
						return string.format("%s %s", icon or "󰈔", self.filename) -- Display icon and file name
					end,
					hl = function(self)
						local _, icon_color =
							devicons.get_icon_color(self.filename, fn.expand "%:e", { default = true })
						return { fg = icon_color or colors.text } -- Set icon color
					end,
				},
				{
					-- Subcomponent: File status (modified/readonly indicators)
					provider = function(self)
						local status = {}
						if self.modified then
							table.insert(status, "󰜄") -- Modified indicator
						end
						if self.readonly then
							table.insert(status, "󰌾") -- Readonly indicator
						end
						return #status > 0 and (" " .. table.concat(status, " ")) or "" -- Combine indicators
					end,
					hl = function(self)
						if self.modified then
							return { fg = colors.peach, bold = true } -- Highlight for modified
						elseif self.readonly then
							return { fg = colors.red } -- Highlight for readonly
						end
					end,
				},
				update = { "BufModifiedSet", "BufEnter", "BufWritePost" }, -- Update on relevant events
			}

			-- Git component: Displays Git branch and change statistics
			local Git = {
				condition = conditions.is_git_repo, -- Only show if buffer is in a Git repository
				init = function(self)
					local gitsigns = vim.b.gitsigns_status_dict
					if gitsigns then
						self.head = vim.b.gitsigns_head or "" -- Get Git branch name
						self.added = gitsigns.added or 0 -- Number of added lines
						self.changed = gitsigns.changed or 0 -- Number of changed lines
						self.removed = gitsigns.removed or 0 -- Number of removed lines
						self.has_changes = self.added > 0 or self.changed > 0 or self.removed > 0
					else
						self.head = ""
						self.has_changes = false
					end
				end,
				static = {
					icons = {
						added = "󰐕", -- Icon for added lines
						changed = "󰜥", -- Icon for changed lines
						removed = "󰍵", -- Icon for removed lines
						branch = "", -- Branch icon (empty in this configuration)
					},
				},
				{
					-- Subcomponent: Git branch
					provider = function(self)
						if is_empty(self.head) then
							return ""
						end
						return string.format(" %s %s", self.icons.branch, self.head) -- Display branch name
					end,
					hl = { fg = colors.peach, bold = true }, -- Highlight for branch
				},
				{
					-- Subcomponent: Git change statistics
					condition = function(self)
						return self.has_changes -- Only show if there are changes
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
						return " " .. table.concat(changes, " ") -- Combine change indicators
					end,
				},
				update = { "User", pattern = "GitSignsUpdate" }, -- Update on Git signs update
			}

			-- Diagnostics component: Displays LSP diagnostic counts
			local Diagnostics = {
				condition = conditions.has_diagnostics, -- Only show if diagnostics exist
				init = function(self)
					self.errors = #diagnostic.get(0, { severity = diagnostic.severity.ERROR }) -- Error count
					self.warnings = #diagnostic.get(0, { severity = diagnostic.severity.WARN }) -- Warning count
					self.infos = #diagnostic.get(0, { severity = diagnostic.severity.INFO }) -- Info count
					self.hints = #diagnostic.get(0, { severity = diagnostic.severity.HINT }) -- Hint count
				end,
				static = {
					icons = {
						error = "󰅚", -- Error icon
						warn = "󰀪", -- Warning icon
						info = "󰋽", -- Info icon
						hint = "󰌶", -- Hint icon
					},
				},
				{
					provider = function(self)
						return self.errors > 0 and string.format(" %s %d", self.icons.error, self.errors) or "" -- Error display
					end,
					hl = { fg = colors.red, bold = true },
				},
				{
					provider = function(self)
						return self.warnings > 0 and string.format(" %s %d", self.icons.warn, self.warnings) or "" -- Warning display
					end,
					hl = { fg = colors.yellow, bold = true },
				},
				{
					provider = function(self)
						return self.infos > 0 and string.format(" %s %d", self.icons.info, self.infos) or "" -- Info display
					end,
					hl = { fg = colors.blue, bold = true },
				},
				{
					provider = function(self)
						return self.hints > 0 and string.format(" %s %d", self.icons.hint, self.hints) or "" -- Hint display
					end,
					hl = { fg = colors.mauve, bold = true },
				},
				update = { "DiagnosticChanged", "BufEnter" }, -- Update on diagnostic changes or buffer enter
			}

			-- SearchInfo component: Displays search result count
			local SearchInfo = {
				condition = function()
					return vim.v.hlsearch ~= 0 -- Only show if search highlighting is active
				end,
				init = function(self)
					local ok, search = pcall(fn.searchcount) -- Get search count
					if ok and search.total and search.total > 0 then
						self.search = search
					else
						self.search = nil
					end
				end,
				provider = function(self)
					if not self.search then
						return ""
					end
					return string.format(" 󰍉 %d/%d", self.search.current, self.search.total) -- Display current/total search matches
				end,
				hl = { fg = colors.yellow, bold = true },
			}

			-- LSPClients component: Displays active LSP clients
			local LSPClients = {
				condition = conditions.lsp_attached, -- Only show if LSP clients are attached
				init = function(self)
					local clients = {}
					for _, client in ipairs(vim.lsp.get_clients { bufnr = 0 }) do
						local name = client.name
						if name ~= "null-ls" and name ~= "copilot" and name ~= "GitHub Copilot" then
							table.insert(clients, name) -- Filter out specific LSP clients
						end
					end
					self.clients = clients
				end,
				static = {
					max_len = 30, -- Maximum length for client names
					icon = "󰒋", -- LSP icon
				},
				provider = function(self)
					if #self.clients == 0 then
						return ""
					end
					local text = table.concat(self.clients, ", ")
					if #text > self.max_len then
						text = text:sub(1, self.max_len - 3) .. "..." -- Truncate long text
					end
					return string.format(" %s %s", self.icon, text) -- Display icon and client names
				end,
				hl = { fg = colors.mauve, bold = true },
				update = { "LspAttach", "LspDetach" }, -- Update on LSP attach/detach
			}

			-- FileEncoding component: Displays file encoding
			local FileEncoding = {
				provider = function()
					return string.format("󰈍 %s", bo.fileencoding) -- Display encoding with icon
				end,
				hl = { fg = colors.overlay2 },
			}

			-- Position component: Displays cursor position and percentage
			local Position = {
				init = function(self)
					local cursor = api.nvim_win_get_cursor(0)
					local lines = api.nvim_buf_line_count(0)
					self.row = cursor[1] -- Current row
					self.col = cursor[2] + 1 -- Current column (1-based)
					self.lines = lines -- Total lines
					self.percent = lines > 0 and math.floor((self.row / lines) * 100) or 0 -- Percentage position
				end,
				flexible = 1, -- Flexible component with multiple display modes
				{
					-- Full format: row/total, column, percentage
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
					-- Medium format: row/total, percentage
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
					-- Compact format: percentage only
					provider = function(self)
						return string.format("%d%%", self.percent)
					end,
					hl = { fg = colors.green },
				},
			}

			-- ScrollBar component: Visual representation of scroll position
			local ScrollBar = {
				static = {
					sbar = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" }, -- Scrollbar characters
				},
				provider = function(self)
					local curr_line = api.nvim_win_get_cursor(0)[1]
					local lines = api.nvim_buf_line_count(0)
					if lines <= 1 then
						return self.sbar[#self.sbar] -- Full bar for single-line buffers
					end
					local i = math.min(math.floor((curr_line - 1) / lines * #self.sbar) + 1, #self.sbar)
					return string.rep(self.sbar[i], 2) -- Display scroll position
				end,
				hl = { fg = colors.blue },
			}

			-- CodeCompanion
			local CodeCompanion = {
				static = {
					processing = false,
				},
				update = {
					"User",
					pattern = "CodeCompanionRequest*",
					callback = function(self, args)
						if args.match == "CodeCompanionRequestStarted" then
							self.processing = true
						elseif args.match == "CodeCompanionRequestFinished" then
							self.processing = false
						end
						vim.cmd "redrawstatus"
					end,
				},
				{
					condition = function(self)
						return self.processing
					end,
					provider = " ",
					hl = { fg = "yellow" },
				},
			}

			-- ========================================
			-- TABLINE COMPONENTS
			-- ========================================

			-- Tabline filename component
			local TablineFileName = {
				provider = function(self)
					local filename = self.filename
					filename = filename == "" and "[No Name]" or fn.fnamemodify(filename, ":t")
					return filename
				end,
				hl = function(self)
					return { bold = self.is_active or self.is_visible, italic = true }
				end,
			}

			-- Tabline file flags component
			local TablineFileFlags = {
				{
					condition = function(self)
						return api.nvim_get_option_value("modified", { buf = self.bufnr })
					end,
					provider = " [+]",
					hl = { fg = colors.green },
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

			-- Tabline filename block
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
						if button == "m" then -- close on mouse middle click
							vim.schedule(function()
								-- Safe buffer deletion with error handling
								local ok, err = pcall(function()
									if api.nvim_buf_is_valid(minwid) then
										api.nvim_buf_delete(minwid, { force = false })
									end
								end)
								if not ok then
									vim.notify("Error deleting buffer: " .. tostring(err), vim.log.levels.WARN)
								end
							end)
						else
							-- Safe buffer switching
							vim.schedule(function()
								local ok, err = pcall(function()
									if api.nvim_buf_is_valid(minwid) then
										api.nvim_win_set_buf(0, minwid)
									end
								end)
								if not ok then
									vim.notify("Error switching to buffer: " .. tostring(err), vim.log.levels.WARN)
								end
							end)
						end
					end,
					minwid = function(self)
						return self.bufnr
					end,
					name = "heirline_tabline_buffer_callback",
				},
				FileIcon,
				{ provider = " " },
				TablineFileName,
				TablineFileFlags,
			}

			-- Tabline close button
			local TablineCloseButton = {
				condition = function(self)
					return not api.nvim_get_option_value("modified", { buf = self.bufnr })
				end,
				{ provider = " " },
				{
					provider = "󰅖",
					hl = { fg = colors.overlay1 },
					on_click = {
						callback = function(_, minwid)
							vim.schedule(function()
								-- Safe buffer deletion with additional checks
								local ok, err = pcall(function()
									if api.nvim_buf_is_valid(minwid) and api.nvim_buf_is_loaded(minwid) then
										-- Check if buffer is modified before deletion
										local modified = api.nvim_get_option_value("modified", { buf = minwid })
										if not modified then
											api.nvim_buf_delete(minwid, { force = false })
											vim.cmd.redrawtabline()
										else
											vim.notify("Buffer is modified, save before closing", vim.log.levels.WARN)
										end
									end
								end)
								if not ok then
									vim.notify("Error closing buffer: " .. tostring(err), vim.log.levels.WARN)
								end
							end)
						end,
						minwid = function(self)
							return self.bufnr
						end,
						name = "heirline_tabline_close_buffer_callback",
					},
				},
			}

			-- Buffer picker component
			local TablinePicker = {
				condition = function(self)
					return self._show_picker
				end,
				init = function(self)
					local bufname = api.nvim_buf_get_name(self.bufnr)
					bufname = fn.fnamemodify(bufname, ":t")
					local label = bufname:sub(1, 1)
					local i = 2
					while self._picker_labels[label] do
						if i > #bufname then
							break
						end
						label = bufname:sub(i, i)
						i = i + 1
					end
					self._picker_labels[label] = self.bufnr
					self.label = label
				end,
				provider = function(self)
					return self.label
				end,
				hl = { fg = colors.red, bold = true },
			}

			-- Final tabline buffer block with styling
			local TablineBufferBlock = utils.surround({ "", "" }, function(self)
				if self.is_active then
					return utils.get_highlight("TabLineSel").bg
				else
					return utils.get_highlight("TabLine").bg
				end
			end, {
				TablinePicker,
				TablineFileNameBlock,
				TablineCloseButton,
			})

			-- Tabpage component
			local Tabpage = {
				provider = function(self)
					return "%" .. self.tabnr .. "T " .. self.tabnr .. " %T"
				end,
				hl = function(self)
					if not self.is_active then
						return "TabLine"
					else
						return "TabLineSel"
					end
				end,
			}

			-- Tabpage close button
			local TabpageClose = {
				provider = "%999X 󰅖 %X",
				hl = "TabLine",
			}

			-- Tab pages list
			local TabPages = {
				condition = function()
					return #api.nvim_list_tabpages() >= 2
				end,
				{ provider = "%=" },
				utils.make_tablist(Tabpage),
				TabpageClose,
			}

			-- NvimTree offset component
			local TabLineOffset = {
				condition = function(self)
					local win = api.nvim_tabpage_list_wins(0)[1]
					local bufnr = api.nvim_win_get_buf(win)
					self.winid = win

					if vim.bo[bufnr].filetype == "NvimTree" then
						self.title = "NvimTree"
						return true
					end
				end,

				provider = function(self)
					local title = self.title
					local width = api.nvim_win_get_width(self.winid)
					local pad = math.ceil((width - #title) / 2)
					return string.rep(" ", pad) .. title .. string.rep(" ", pad)
				end,

				hl = function(self)
					if api.nvim_get_current_win() == self.winid then
						return "TablineSel"
					else
						return "Tabline"
					end
				end,
			}

			-- Buffer list management with improved error handling
			local get_bufs = function()
				local ok, bufs = pcall(function()
					return vim.tbl_filter(function(bufnr)
						-- Additional safety checks
						return api.nvim_buf_is_valid(bufnr)
							and api.nvim_get_option_value("buflisted", { buf = bufnr })
							and api.nvim_buf_get_name(bufnr) ~= ""
					end, api.nvim_list_bufs())
				end)
				return ok and bufs or {}
			end

			local buflist_cache = {}

			-- Create the main buffer line
			local BufferLine = utils.make_buflist(
				TablineBufferBlock,
				{ provider = "󰍞", hl = { fg = colors.overlay1 } }, -- left truncation
				{ provider = "󰍟", hl = { fg = colors.overlay1 } }, -- right truncation
				function()
					return buflist_cache
				end,
				false -- no cache, as we're handling everything ourselves
			)

			-- Complete tabline
			local TabLine = {
				TabLineOffset,
				BufferLine,
				TabPages,
			}

			-- Main StatusLine: Combines all components
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
				CodeCompanion,
				LSPClients,
				Spacer,
				FileEncoding,
				Separator,
				Position,
				Spacer,
				ScrollBar,
			}

			-- Function to set up highlight groups
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

			-- Initialize Heirline with statusline and tabline
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
							},
						}, args.buf)
					end,
				},
			}

			-- Set up highlight groups
			setup_highlights()

			-- Create autocommand group for optimization
			local augroup = api.nvim_create_augroup("HeirlineOptimized", { clear = true })

			-- Buffer list management autocommand with improved error handling
			api.nvim_create_autocmd({ "VimEnter", "UIEnter", "BufAdd", "BufDelete" }, {
				group = augroup,
				callback = function()
					vim.schedule(function()
						-- Wrap in pcall to prevent errors from breaking the UI
						local ok, err = pcall(function()
							local buffers = get_bufs()
							for i, v in ipairs(buffers) do
								buflist_cache[i] = v
							end
							for i = #buffers + 1, #buflist_cache do
								buflist_cache[i] = nil
							end

							-- Show tabline only when there are multiple buffers
							if #buflist_cache > 1 then
								vim.o.showtabline = 2 -- always
							elseif vim.o.showtabline ~= 1 then
								vim.o.showtabline = 1 -- only when #tabpages > 1
							end
						end)

						if not ok then
							vim.notify("Error updating buffer list: " .. tostring(err), vim.log.levels.DEBUG)
						end
					end)
				end,
			})

			-- Buffer picker keymap with improved error handling
			vim.keymap.set("n", "gbp", function()
				local ok, err = pcall(function()
					local tabline = require("heirline").tabline
					if not tabline or not tabline._buflist or not tabline._buflist[1] then
						vim.notify("Tabline not properly initialized", vim.log.levels.WARN)
						return
					end

					local buflist = tabline._buflist[1]
					buflist._picker_labels = {}
					buflist._show_picker = true
					vim.cmd.redrawtabline()

					local char = fn.getcharstr()
					local bufnr = buflist._picker_labels[char]

					if bufnr and api.nvim_buf_is_valid(bufnr) then
						api.nvim_win_set_buf(0, bufnr)
					end

					buflist._show_picker = false
					vim.cmd.redrawtabline()
				end)

				if not ok then
					vim.notify("Error in buffer picker: " .. tostring(err), vim.log.levels.WARN)
				end
			end, { desc = "Pick buffer from tabline" })

			-- Update colors on colorscheme change
			api.nvim_create_autocmd("ColorScheme", {
				group = augroup,
				desc = "Update Heirline colors on colorscheme change",
				callback = function()
					colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")
					setup_highlights()
				end,
			})

			-- Optimize buffer listing
			api.nvim_create_autocmd("FileType", {
				group = augroup,
				desc = "Optimize buffer listing",
				callback = function()
					if vim.tbl_contains({ "wipe", "delete" }, bo.bufhidden) then
						bo.buflisted = false
					end
				end,
			})

			-- Reduce update frequency in insert mode for performance
			api.nvim_create_autocmd("InsertEnter", {
				group = augroup,
				desc = "Reduce update frequency in insert mode",
				callback = function()
					vim.opt.updatetime = 1000
				end,
			})

			-- Restore update frequency after insert mode
			api.nvim_create_autocmd("InsertLeave", {
				group = augroup,
				desc = "Restore update frequency after insert mode",
				callback = function()
					vim.opt.updatetime = 300
				end,
			})

			-- Refresh statusline on window resize
			api.nvim_create_autocmd("VimResized", {
				group = augroup,
				desc = "Refresh statusline on window resize",
				callback = function()
					vim.cmd "redrawstatus"
					vim.cmd "redrawtabline"
				end,
			})

			-- Additional tabline-specific keymaps with safer buffer operations
			vim.keymap.set("n", "<leader>bn", function()
				local ok, err = pcall(function()
					vim.cmd "bnext"
				end)
				if not ok then
					vim.notify("No next buffer available", vim.log.levels.INFO)
				end
			end, { desc = "Next buffer" })

			vim.keymap.set("n", "<leader>bp", function()
				local ok, err = pcall(function()
					vim.cmd "bprevious"
				end)
				if not ok then
					vim.notify("No previous buffer available", vim.log.levels.INFO)
				end
			end, { desc = "Previous buffer" })

			vim.keymap.set("n", "<leader>bd", function()
				local ok, err = pcall(function()
					vim.cmd "bdelete"
				end)
				if not ok then
					vim.notify("Cannot delete buffer: " .. tostring(err), vim.log.levels.WARN)
				end
			end, { desc = "Delete buffer" })
			-- Removed force delete buffer keymap (<leader>bD)
		end,
	},
}
