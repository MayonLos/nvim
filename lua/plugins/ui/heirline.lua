return {
	"rebelot/heirline.nvim",
	event = "VeryLazy",
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"neovim/nvim-lspconfig",
		"lewis6991/gitsigns.nvim",
		"catppuccin/nvim",
	},
	config = function()
		local heirline = require "heirline"
		local conditions = require "heirline.conditions"
		local utils = require "heirline.utils"
		local devicons = require "nvim-web-devicons"
		local colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")

		-- Cache frequently used APIs
		local api, fn, bo = vim.api, vim.fn, vim.bo

		-- ═══════════════════════════════════════════════════════════════════════
		-- 🛠️  UTILITY FUNCTIONS
		-- ═══════════════════════════════════════════════════════════════════════

		local function safe_call(func, fallback)
			local ok, result = pcall(func)
			return ok and result or fallback
		end

		local function is_empty(str)
			return not str or str == ""
		end

		local function truncate(str, max_len)
			return #str <= max_len and str or str:sub(1, max_len - 1) .. "…"
		end

		-- ═══════════════════════════════════════════════════════════════════════
		-- 🎨 COMPONENTS
		-- ═══════════════════════════════════════════════════════════════════════

		local Space = { provider = " " }
		local Align = { provider = "%=" }

		-- ┌─────────────────────────────────────────────────────────────────────┐
		-- │ 📍 Mode Component                                                   │
		-- └─────────────────────────────────────────────────────────────────────┘
		local Mode = {
			init = function(self)
				self.mode = fn.mode()
			end,

			static = {
				mode_map = {
					n = { name = "NORMAL", color = colors.blue },
					i = { name = "INSERT", color = colors.green },
					v = { name = "VISUAL", color = colors.mauve },
					V = { name = "V-LINE", color = colors.mauve },
					["\22"] = { name = "V-BLOCK", color = colors.mauve },
					c = { name = "COMMAND", color = colors.peach },
					t = { name = "TERMINAL", color = colors.yellow },
					R = { name = "REPLACE", color = colors.red },
					r = { name = "REPLACE", color = colors.red },
				},
			},

			provider = function(self)
				local mode_info = self.mode_map[self.mode] or { name = self.mode:upper(), color = colors.text }
				return string.format("  %s  ", mode_info.name)
			end,

			hl = function(self)
				local mode_info = self.mode_map[self.mode] or { color = colors.text }
				return { fg = colors.base, bg = mode_info.color, bold = true }
			end,

			update = { "ModeChanged", "BufEnter" },
		}

		-- ┌─────────────────────────────────────────────────────────────────────┐
		-- │ 📄 File Info Component                                              │
		-- └─────────────────────────────────────────────────────────────────────┘
		local FileInfo = {
			init = function(self)
				self.filename = fn.expand "%:t"
				self.modified = bo.modified
				self.readonly = bo.readonly
			end,

			-- File icon
			{
				provider = function(self)
					if is_empty(self.filename) then
						return "󰈔"
					end
					local icon = devicons.get_icon(self.filename, fn.expand "%:e", { default = true })
					return icon or "󰈔"
				end,
				hl = function(self)
					if is_empty(self.filename) then
						return { fg = colors.text }
					end
					local _, color = devicons.get_icon_color(self.filename, fn.expand "%:e", { default = true })
					return { fg = color or colors.text }
				end,
			},

			Space,

			-- Filename
			{
				provider = function(self)
					if is_empty(self.filename) then
						return "[No Name]"
					end
					return truncate(self.filename, 30)
				end,
				hl = function(self)
					if self.readonly then
						return { fg = colors.red, bold = self.modified }
					elseif self.modified then
						return { fg = colors.peach, bold = true }
					else
						return { fg = colors.text, bold = self.modified }
					end
				end,
			},

			-- File status indicators
			{
				provider = function(self)
					local indicators = {}
					if self.modified then
						table.insert(indicators, "●")
					end
					if self.readonly then
						table.insert(indicators, "")
					end
					return #indicators > 0 and (" " .. table.concat(indicators, " ")) or ""
				end,
				hl = function(self)
					if self.modified then
						return { fg = colors.green, bold = true }
					elseif self.readonly then
						return { fg = colors.red, bold = true }
					end
				end,
			},

			update = { "BufModifiedSet", "BufEnter", "BufWritePost" },
		}

		-- ┌─────────────────────────────────────────────────────────────────────┐
		-- │ 🌿 Git Component                                                    │
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

			-- Branch name
			{
				condition = function(self)
					return not is_empty(self.head)
				end,
				provider = function(self)
					return string.format("  %s", truncate(self.head, 20))
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
						table.insert(changes, "+" .. self.added)
					end
					if self.changed > 0 then
						table.insert(changes, "~" .. self.changed)
					end
					if self.removed > 0 then
						table.insert(changes, "-" .. self.removed)
					end
					return " (" .. table.concat(changes, " ") .. ")"
				end,
				hl = { fg = colors.subtext1 },
			},

			update = { "User", pattern = "GitSignsUpdate" },
		}

		-- ┌─────────────────────────────────────────────────────────────────────┐
		-- │ 🩺 Diagnostics Component                                            │
		-- └─────────────────────────────────────────────────────────────────────┘
		local Diagnostics = {
			condition = conditions.has_diagnostics,

			init = function(self)
				self.errors = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.ERROR })
				self.warnings = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.WARN })
				self.infos = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.INFO })
				self.hints = #vim.diagnostic.get(0, { severity = vim.diagnostic.severity.HINT })
			end,

			{
				provider = function(self)
					return self.errors > 0 and string.format("  %d", self.errors) or ""
				end,
				hl = { fg = colors.red, bold = true },
			},
			{
				provider = function(self)
					return self.warnings > 0 and string.format("  %d", self.warnings) or ""
				end,
				hl = { fg = colors.yellow, bold = true },
			},
			{
				provider = function(self)
					return self.infos > 0 and string.format("  %d", self.infos) or ""
				end,
				hl = { fg = colors.sky },
			},
			{
				provider = function(self)
					return self.hints > 0 and string.format("  %d", self.hints) or ""
				end,
				hl = { fg = colors.teal },
			},

			update = { "DiagnosticChanged", "BufEnter" },
		}

		-- ┌─────────────────────────────────────────────────────────────────────┐
		-- │ 🔧 LSP Clients Component                                            │
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

			provider = function(self)
				if #self.clients == 0 then
					return ""
				end
				local text = table.concat(self.clients, "·")
				return string.format("  %s", truncate(text, 25))
			end,

			hl = { fg = colors.sapphire },
			update = { "LspAttach", "LspDetach" },
		}

		-- ┌─────────────────────────────────────────────────────────────────────┐
		-- │ 📍 Position Component                                               │
		-- └─────────────────────────────────────────────────────────────────────┘
		local Position = {
			provider = function()
				local row, col = unpack(api.nvim_win_get_cursor(0))
				local total_lines = api.nvim_buf_line_count(0)
				local percent = total_lines > 0 and math.floor((row / total_lines) * 100) or 0
				return string.format("  %d:%d %d%% ", row, col + 1, percent)
			end,
			hl = { fg = colors.blue },
		}

		-- ═══════════════════════════════════════════════════════════════════════
		-- 📑 TABLINE COMPONENTS
		-- ═══════════════════════════════════════════════════════════════════════

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
				local filetype = safe_call(function()
					return vim.bo[bufnr].filetype
				end, "")

				self.winid = win

				local sidebars = {
					NvimTree = "  Files",
					["neo-tree"] = "  Neo-tree",
					Outline = "  Outline",
					aerial = "  Aerial",
				}

				if sidebars[filetype] then
					self.title = sidebars[filetype]
					return true
				end

				return false
			end,

			provider = function(self)
				local width = safe_call(function()
					return api.nvim_win_is_valid(self.winid) and api.nvim_win_get_width(self.winid) or 0
				end, 0)

				if width == 0 then
					return ""
				end

				local title = self.title
				local title_len = vim.fn.strdisplaywidth(title)
				local pad = math.max(0, math.floor((width - title_len) / 2))
				local right_pad = math.max(0, width - title_len - pad)

				return string.rep(" ", pad) .. title .. string.rep(" ", right_pad)
			end,

			hl = { bg = colors.surface0, fg = colors.blue, bold = true },
		}

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
					return { bg = colors.mantle, fg = colors.subtext0 }
				end
			end,

			on_click = {
				callback = function(_, minwid, _, button)
					if button == "m" then -- Middle click to close
						vim.schedule(function()
							pcall(api.nvim_buf_delete, minwid, {})
						end)
					else -- Left click to switch
						vim.schedule(function()
							pcall(api.nvim_win_set_buf, 0, minwid)
						end)
					end
				end,
				minwid = function(self)
					return self.bufnr
				end,
				name = "heirline_tabline_buffer_callback",
			},

			{ provider = " " },
			-- File icon
			{
				provider = function(self)
					if is_empty(self.filename) then
						return "󰈔"
					end
					local icon =
						devicons.get_icon(self.filename, vim.fn.fnamemodify(self.filename, ":e"), { default = true })
					return icon or "󰈔"
				end,
				hl = function(self)
					if is_empty(self.filename) then
						return { fg = self.is_active and colors.text or colors.overlay0 }
					end
					local _, color = devicons.get_icon_color(
						self.filename,
						vim.fn.fnamemodify(self.filename, ":e"),
						{ default = true }
					)
					return { fg = self.is_active and (color or colors.text) or colors.overlay1 }
				end,
			},
			{ provider = " " },
			-- Filename
			{
				provider = function(self)
					local filename = self.filename
					if is_empty(filename) then
						return "Untitled"
					end
					filename = vim.fn.fnamemodify(filename, ":t")
					return truncate(filename, 18)
				end,
				hl = function(self)
					return {
						bold = self.is_active,
						fg = self.is_active and colors.text or colors.subtext0,
					}
				end,
			},
			-- Modified indicator
			{
				condition = function(self)
					return safe_call(function()
						return api.nvim_get_option_value("modified", { buf = self.bufnr })
					end, false)
				end,
				provider = " ●",
				hl = function(self)
					return { fg = self.is_active and colors.green or colors.overlay1 }
				end,
			},
			{ provider = " " },
		}

		local TablineBufferBlock = utils.surround({ "", "" }, function(self)
			return self.is_active and colors.blue or colors.surface1
		end, { TablineFileNameBlock })

		-- ═══════════════════════════════════════════════════════════════════════
		-- 📋 BUFFER MANAGEMENT
		-- ═══════════════════════════════════════════════════════════════════════

		local buflist_cache = {}

		local function get_bufs()
			return vim.tbl_filter(function(bufnr)
				return api.nvim_buf_is_valid(bufnr)
					and api.nvim_get_option_value("buflisted", { buf = bufnr })
					and api.nvim_get_option_value("buftype", { buf = bufnr }) == ""
			end, api.nvim_list_bufs())
		end

		local BufferLine = {
			TablineOffset,
			utils.make_buflist(
				TablineBufferBlock,
				{ provider = " … ", hl = { fg = colors.overlay1 } },
				{ provider = " … ", hl = { fg = colors.overlay1 } },
				function()
					return buflist_cache
				end,
				false
			),
		}

		-- ═══════════════════════════════════════════════════════════════════════
		-- 🎯 MAIN COMPONENTS
		-- ═══════════════════════════════════════════════════════════════════════

		local StatusLine = {
			hl = function()
				return conditions.is_active() and "StatusLine" or "StatusLineNC"
			end,

			Mode,
			Space,
			FileInfo,
			Git,
			Diagnostics,
			Align,
			LSPClients,
			Position,
		}

		-- ═══════════════════════════════════════════════════════════════════════
		-- ⚡ SETUP & AUTOCOMMANDS
		-- ═══════════════════════════════════════════════════════════════════════

		heirline.setup {
			statusline = StatusLine,
			tabline = BufferLine,
			opts = { colors = colors },
		}

		-- Update buffer list
		local function update_buflist()
			local buffers = get_bufs()
			for i = 1, #buflist_cache do
				buflist_cache[i] = nil
			end
			for i, bufnr in ipairs(buffers) do
				buflist_cache[i] = bufnr
			end
			vim.o.showtabline = #buffers > 1 and 2 or 1
		end

		local augroup = api.nvim_create_augroup("HeirlineConfig", { clear = true })

		api.nvim_create_autocmd({
			"VimEnter",
			"BufAdd",
			"BufDelete",
			"BufWipeout",
		}, {
			group = augroup,
			callback = function()
				vim.schedule(update_buflist)
			end,
		})

		api.nvim_create_autocmd("ColorScheme", {
			group = augroup,
			callback = function()
				colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")
				vim.cmd "redrawstatus | redrawtabline"
			end,
		})

		-- ═══════════════════════════════════════════════════════════════════════
		-- ⌨️  KEYMAPS
		-- ═══════════════════════════════════════════════════════════════════════

		-- Buffer navigation
		vim.keymap.set("n", "<Tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
		vim.keymap.set("n", "<S-Tab>", "<cmd>bprevious<cr>", { desc = "Previous buffer" })
		vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
		vim.keymap.set("n", "<leader><leader>", "<cmd>buffer #<cr>", { desc = "Toggle last buffer" })

		-- Quick buffer access
		for i = 1, 9 do
			vim.keymap.set("n", "<C-" .. i .. ">", function()
				local buffers = get_bufs()
				if buffers[i] and api.nvim_buf_is_valid(buffers[i]) then
					api.nvim_win_set_buf(0, buffers[i])
				end
			end, { desc = "Switch to buffer " .. i })
		end

		-- Commands
		vim.api.nvim_create_user_command("BufferCloseOthers", function()
			local current = api.nvim_get_current_buf()
			for _, bufnr in ipairs(get_bufs()) do
				if bufnr ~= current then
					pcall(api.nvim_buf_delete, bufnr, {})
				end
			end
		end, { desc = "Close all other buffers" })

		-- Initial setup
		update_buflist()
	end,
}
