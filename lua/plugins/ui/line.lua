return {
	{
		"akinsho/bufferline.nvim",
		version = "*",
		event = "VeryLazy",
		keys = function()
			return require("core.keymaps").plugin("bufferline")
		end,
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"catppuccin/nvim",
		},
		config = function()
			local bufferline = require "bufferline"

			local function diag_indicator(_, _, diag)
				local parts = {}
				if diag.error and diag.error > 0 then
					parts[#parts + 1] = "󰅚 " .. diag.error
				end
				if diag.warning and diag.warning > 0 then
					parts[#parts + 1] = " " .. diag.warning
				end
				if diag.info and diag.info > 0 then
					parts[#parts + 1] = " " .. diag.info
				end
				if diag.hint and diag.hint > 0 then
					parts[#parts + 1] = "󰌶 " .. diag.hint
				end
				return (#parts > 0) and (" " .. table.concat(parts, " ")) or ""
			end

			bufferline.setup {
				options = {
					mode = "buffers",
					themable = true,
					numbers = "none",

					left_mouse_command = "buffer %d",
					right_mouse_command = nil,
					middle_mouse_command = nil,

					close_command = "bdelete %d",
					buffer_close_icon = "󰅖",
					modified_icon = "●",
					close_icon = "",

					indicator = { icon = "▎", style = "icon" },

					max_name_length = 28,
					max_prefix_length = 20,
					truncate_names = true,
					tab_size = 18,

					diagnostics = "nvim_lsp",
					diagnostics_update_in_insert = false,
					diagnostics_indicator = diag_indicator,

					color_icons = true,
					show_buffer_icons = true,
					show_buffer_close_icons = false,
					show_close_icon = false,
					show_tab_indicators = true,
					show_duplicate_prefix = true,

					persist_buffer_sort = true,
					move_wraps_at_ends = false,
					separator_style = "thin",
					enforce_regular_tabs = false,

					always_show_bufferline = false,

					hover = { enabled = true, delay = 150, reveal = { "close" } },
					sort_by = "insert_after_current",

					offsets = {
						{ filetype = "neo-tree", text = "󰙅  Neo-tree", text_align = "center", separator = true },
						{ filetype = "NvimTree", text = "󰙅  Explorer", text_align = "center", separator = true },
						{ filetype = "Outline", text = "󰘬  Outline", text_align = "center", separator = true },
						{ filetype = "aerial", text = "󰤌  Aerial", text_align = "center", separator = true },
					},

					custom_filter = function(bufnr)
						local ft = vim.bo[bufnr].filetype
						local bt = vim.bo[bufnr].buftype
						if bt ~= "" and bt ~= "terminal" then
							return false
						end
						local exclude = {
							help = true,
							alpha = true,
							dashboard = true,
							NvimTree = true,
							["neo-tree"] = true,
							Trouble = true,
							lir = true,
							Outline = true,
							spectre_panel = true,
							toggleterm = true,
							TelescopePrompt = true,
							lazy = true,
							mason = true,
							notify = true,
							noice = true,
							aerial = true,
							qf = true,
							fugitive = true,
							gitcommit = true,
							startuptime = true,
							lspinfo = true,
							checkhealth = true,
						}
						return not exclude[ft]
					end,
				},

				highlights = (function()
					local ok, integ = pcall(require, "catppuccin.groups.integrations.bufferline")
					if ok and integ then
						local get = integ.get_theme or integ.get
						if get then
							return get {
								styles = { "italic", "bold" },
							}
						end
					end
					return {}
				end)(),
			}
		end,
	},

	{
		"rebelot/heirline.nvim",
		event = "VeryLazy",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"lewis6991/gitsigns.nvim",
			"catppuccin/nvim",
			"SmiteshP/nvim-navic",
		},
		config = function()
			local heirline = require "heirline"
			local conditions = require "heirline.conditions"
			local devicons = require "nvim-web-devicons"
			local api, fn = vim.api, vim.fn
			local diag = vim.diagnostic

			require("nvim-navic").setup({
				highlight = true,
				separator = " > ",
				lazy_update_context = false,
				safe_output = true,
			})

			local colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")

			local M = {}
			function M.truncate(s, n)
				if not s or s == "" or #s <= n then
					return s or ""
				end
				return s:sub(1, math.max(n - 3, 1)) .. "…"
			end
			function M.adapt(n)
				local cols = vim.o.columns
				if cols < 100 then
					return math.floor(n * 0.6)
				elseif cols < 150 then
					return n
				else
					return math.floor(n * 1.3)
				end
			end

			local Space, Align = { provider = " " }, { provider = "%=" }

			-- Mode
			local Mode = {
				init = function(self)
					self.mode = fn.mode(1)
				end,
				static = {
					map = {
						n = { "󰰆", "NORMAL", colors.blue },
						i = { "󰰅", "INSERT", colors.green },
						v = { "󰰈", "VISUAL", colors.mauve },
						V = { "󰰉", "V-LINE", colors.mauve },
						["\22"] = { "󰰊", "V-BLOCK", colors.mauve },
						c = { "󰞷", "CMD", colors.peach },
						t = { "󰓫", "TERM", colors.yellow },
						R = { "󰛔", "REPL", colors.red },
					},
				},
				provider = function(self)
					local m = self.map[self.mode] or { "󰜅", self.mode, colors.surface1 }
					return ("  %s %s  "):format(m[1], m[2])
				end,
				hl = function(self)
					local m = self.map[self.mode] or { "", "", colors.surface1 }
					return { fg = colors.base, bg = m[3], bold = true }
				end,
				update = { "ModeChanged" },
			}

			-- File info
			local FileInfo = {
				init = function(self)
					self.filename = fn.expand "%:t"
					self.filetype = vim.bo.filetype
					self.modified = vim.bo.modified
					self.readonly = vim.bo.readonly
					self.buftype = vim.bo.buftype
				end,
				{
					provider = function(self)
						if self.filename == "" then
							return (self.buftype == "terminal") and "󰓫 " or "󰈔 "
						end
						local icon = devicons.get_icon(self.filename, fn.expand "%:e", { default = true })
						return (icon or "󰈔") .. " "
					end,
					hl = function(self)
						if self.buftype == "terminal" then
							return { fg = colors.yellow }
						end
						if self.filename == "" then
							return { fg = colors.text }
						end
						local _, c = devicons.get_icon_color(self.filename, fn.expand "%:e", { default = true })
						return { fg = c or colors.text }
					end,
				},
				{
					provider = function(self)
						if self.filename == "" then
							return (self.buftype == "terminal") and "Terminal" or "[Untitled]"
						end
						return M.truncate(self.filename, M.adapt(30))
					end,
					hl = function(self)
						return {
							bold = self.modified,
							fg = (self.buftype == "terminal") and colors.yellow
								or (self.readonly and colors.red)
								or (self.modified and colors.peach)
								or colors.text,
						}
					end,
				},
				{
					provider = function(self)
						local t = {}
						if self.modified then
							t[#t + 1] = "󰜄 "
						end
						if self.readonly then
							t[#t + 1] = "󰌾 "
						end
						if vim.bo.buftype == "help" then
							t[#t + 1] = "󰘥 "
						end
						return (#t > 0) and (" " .. table.concat(t, " ")) or ""
					end,
					hl = { bold = true, fg = colors.blue },
				},
				update = { "BufModifiedSet", "BufEnter", "BufWritePost" },
			}

			-- Git (gitsigns)
			local Git = {
				condition = conditions.is_git_repo,
				init = function(self)
					local d = vim.b.gitsigns_status_dict
					if d then
						self.head = vim.b.gitsigns_head or ""
						self.added, self.changed, self.removed = d.added or 0, d.changed or 0, d.removed or 0
					else
						self.head = ""
					end
				end,
				{
					condition = function(self)
						return self.head ~= ""
					end,
					provider = function(self)
						return (" 󰘬 %s"):format(M.truncate(self.head, M.adapt(20)))
					end,
					hl = { fg = colors.lavender, bold = true },
				},
				{
					condition = function(self)
						return (self.added > 0) or (self.changed > 0) or (self.removed > 0)
					end,
					provider = function(self)
						local t = {}
						if self.added > 0 then
							t[#t + 1] = "+" .. self.added
						end
						if self.changed > 0 then
							t[#t + 1] = "~" .. self.changed
						end
						if self.removed > 0 then
							t[#t + 1] = "-" .. self.removed
						end
						return " (" .. table.concat(t, " ") .. ")"
					end,
					hl = { fg = colors.subtext1 },
				},
				update = { "User", pattern = "GitSignsUpdate" },
			}

			local Diagnostics = {
				condition = conditions.has_diagnostics,
				init = function(self)
					self.err = #diag.get(0, { severity = diag.severity.ERROR })
					self.warn = #diag.get(0, { severity = diag.severity.WARN })
					self.hint = #diag.get(0, { severity = diag.severity.HINT })
					self.info = #diag.get(0, { severity = diag.severity.INFO })
				end,
				{
					condition = function(s)
						return s.err > 0
					end,
					provider = function(s)
						return " 󰅚 " .. s.err
					end,
					hl = { fg = colors.red, bold = true },
				},
				{
					condition = function(s)
						return s.warn > 0
					end,
					provider = function(s)
						return "  " .. s.warn
					end,
					hl = { fg = colors.yellow, bold = true },
				},
				{
					condition = function(s)
						return s.info > 0
					end,
					provider = function(s)
						return "  " .. s.info
					end,
					hl = { fg = colors.sky },
				},
				{
					condition = function(s)
						return s.hint > 0
					end,
					provider = function(s)
						return " 󰌶 " .. s.hint
					end,
					hl = { fg = colors.teal },
				},
				update = { "DiagnosticChanged", "BufEnter" },
			}

			local Navic = {
				condition = function()
					local ok, navic = pcall(require, "nvim-navic")
					return ok and navic.is_available()
				end,
				update = "CursorMoved",
				provider = function()
					return (" %s"):format(
						require("nvim-navic").get_location({
							separator = " > ",
							highlight = true,
							safe_output = true,
						})
					)
				end,
				hl = { fg = colors.subtext1 },
			}

			local LSP = {
				condition = require("heirline.conditions").lsp_attached,
				init = function(self)
					local seen, names = {}, {}
					for _, c in pairs(vim.lsp.get_clients { bufnr = 0 }) do
						if c.name ~= "null-ls" and c.name ~= "copilot" and not seen[c.name] then
							table.insert(names, c.name)
							seen[c.name] = true
						end
					end
					self.clients = names
				end,
				provider = function(self)
					if #self.clients == 0 then
						return ""
					end
					return " 󰒋 " .. table.concat(self.clients, "·")
				end,
				hl = {
					fg = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha").sapphire,
					bold = true,
				},
				update = { "LspAttach", "LspDetach" },
			}

			local Position = {
				provider = function()
					local l, c = fn.line ".", fn.col "."
					local total = fn.line "$"
					local pct = (total > 0) and math.floor(l / total * 100) or 0
					return (" 󰍎 %d:%d  %d%% "):format(l, c, pct)
				end,
				hl = { fg = colors.blue, bold = true },
			}

			local ScrollBar = {
				static = { sbar = { "▁", "▂", "▃", "▄", "▅", "▆", "▇", "█" } },
				provider = function(self)
					local l = api.nvim_win_get_cursor(0)[1]
					local total = api.nvim_buf_line_count(0)
					if total <= 1 then
						return " " .. self.sbar[#self.sbar]
					end
					local i = math.min(math.floor((l - 1) / total * #self.sbar) + 1, #self.sbar)
					return " " .. self.sbar[i]
				end,
				hl = function()
					local l = api.nvim_win_get_cursor(0)[1]
					local total = api.nvim_buf_line_count(0)
					local r = (total > 0) and l / total or 0
					if r < 0.2 then
						return { fg = colors.green }
					elseif r < 0.4 then
						return { fg = colors.yellow }
					elseif r < 0.6 then
						return { fg = colors.peach }
					elseif r < 0.8 then
						return { fg = colors.mauve }
					else
						return { fg = colors.red }
					end
				end,
			}
			local StatusLine = {
				hl = function()
					return conditions.is_active() and "StatusLine" or "StatusLineNC"
				end,
				Mode,
				Space,
				FileInfo,
				Git,
				Diagnostics,
				Navic,
				Align,
				Space,
				LSP,
				Space,
				Position,
				ScrollBar,
			}

			heirline.setup {
				statusline = StatusLine,
				opts = {
					colors = colors,
				},
			}

			local aug = api.nvim_create_augroup("HeirlineStatusline", { clear = true })
			api.nvim_create_autocmd("ColorScheme", {
				group = aug,
				callback = function()
					vim.schedule(function()
						colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")
						vim.cmd "redrawstatus"
					end)
				end,
				desc = "Update heirline colors on colorscheme change",
			})
		end,
	},
}
