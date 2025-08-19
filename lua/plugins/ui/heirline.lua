return {
	-- Bufferline for buffer management
	{
		"akinsho/bufferline.nvim",
		version = "*",
		event = "VeryLazy",
		dependencies = {
			"nvim-tree/nvim-web-devicons",
			"catppuccin/nvim",
		},
		config = function()
			local bufferline = require "bufferline"
			local colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")

			bufferline.setup {
				options = {
					mode = "buffers",
					style_preset = bufferline.style_preset.default,
					themable = true,
					numbers = "none",
					close_command = "bdelete! %d",
					right_mouse_command = "bdelete! %d",
					left_mouse_command = "buffer %d",
					middle_mouse_command = nil,
					indicator = {
						icon = "▎",
						style = "icon",
					},
					buffer_close_icon = "󰅖",
					modified_icon = "●",
					close_icon = "",
					left_trunc_marker = "󰍞",
					right_trunc_marker = "󰍟",
					max_name_length = 30,
					max_prefix_length = 30,
					truncate_names = true,
					tab_size = 21,
					diagnostics = "nvim_lsp",
					diagnostics_update_in_insert = false,
					diagnostics_indicator = function(count, level, diagnostics_dict, context)
						local icon = level:match "error" and "󰅚"
							or level:match "warning" and "󰀪"
							or level:match "hint" and "󰌶"
							or "󰋽"
						return " " .. icon .. count
					end,
					color_icons = true,
					show_buffer_icons = true,
					show_buffer_close_icons = true,
					show_close_icon = true,
					show_tab_indicators = true,
					show_duplicate_prefix = true,
					persist_buffer_sort = true,
					move_wraps_at_ends = false,
					separator_style = "thin",
					enforce_regular_tabs = false,
					always_show_bufferline = false,
					hover = {
						enabled = true,
						delay = 200,
						reveal = { "close" },
					},
					sort_by = "insert_at_end",
					offsets = {
						{
							filetype = "NvimTree",
							text = "󰙅 Explorer",
							text_align = "center",
							separator = true,
						},
						{
							filetype = "neo-tree",
							text = "󰙅 Neo-tree",
							text_align = "center",
							separator = true,
						},
						{
							filetype = "Outline",
							text = "󰘬 Outline",
							text_align = "center",
							separator = true,
						},
						{
							filetype = "aerial",
							text = "󰤌 Aerial",
							text_align = "center",
							separator = true,
						},
					},
					custom_filter = function(buf_number, buf_numbers)
						-- Filter out filetypes you don't want to see
						local filetype = vim.bo[buf_number].filetype
						local buftype = vim.bo[buf_number].buftype

						local exclude_ft = {
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
						}

						-- Only show normal and terminal buffers
						if buftype ~= "" and buftype ~= "terminal" then
							return false
						end

						return not vim.tbl_contains(exclude_ft, filetype)
					end,
				},
				highlights = require("catppuccin.groups.integrations.bufferline").get {
					styles = { "italic", "bold" },
					custom = {
						all = {
							fill = { bg = colors.base },
						},
					},
				},
			}

			-- Auto-hide bufferline when only one buffer
			local augroup = vim.api.nvim_create_augroup("BufferlineAutoHide", { clear = true })
			vim.api.nvim_create_autocmd({ "BufAdd", "BufDelete", "BufWipeout" }, {
				group = augroup,
				callback = function()
					vim.schedule(function()
						local buffers = vim.tbl_filter(function(buf)
							return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buflisted
						end, vim.api.nvim_list_bufs())

						if #buffers > 1 then
							vim.o.showtabline = 2
						else
							vim.o.showtabline = 1
						end
					end)
				end,
			})

			-- Buffer navigation keymaps
			vim.keymap.set("n", "<Tab>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
			vim.keymap.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })
			vim.keymap.set("n", "<leader>bp", "<cmd>BufferLineTogglePin<cr>", { desc = "Pin/Unpin buffer" })
			vim.keymap.set(
				"n",
				"<leader>bP",
				"<cmd>BufferLineGroupClose ungrouped<cr>",
				{ desc = "Close unpinned buffers" }
			)
			vim.keymap.set("n", "<leader>br", "<cmd>BufferLineCloseRight<cr>", { desc = "Close buffers to right" })
			vim.keymap.set("n", "<leader>bl", "<cmd>BufferLineCloseLeft<cr>", { desc = "Close buffers to left" })
			vim.keymap.set("n", "<leader>bo", "<cmd>BufferLineCloseOthers<cr>", { desc = "Close other buffers" })
			vim.keymap.set("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Close buffer" })
			vim.keymap.set("n", "<leader>bD", "<cmd>bdelete!<cr>", { desc = "Force close buffer" })

			-- Buffer movement
			vim.keymap.set("n", "<leader>bmh", "<cmd>BufferLineMovePrev<cr>", { desc = "Move buffer left" })
			vim.keymap.set("n", "<leader>bml", "<cmd>BufferLineMoveNext<cr>", { desc = "Move buffer right" })

			-- Buffer picking
			vim.keymap.set("n", "<leader>bs", "<cmd>BufferLinePick<cr>", { desc = "Pick buffer" })
			vim.keymap.set("n", "<leader>bsd", "<cmd>BufferLinePickClose<cr>", { desc = "Pick buffer to close" })

			-- Quick buffer access (Ctrl+number)
			for i = 1, 9 do
				vim.keymap.set("n", "<C-" .. i .. ">", function()
					require("bufferline").go_to(i, true)
				end, { desc = "Switch to buffer " .. i })
			end

			-- Toggle last buffer
			vim.keymap.set("n", "<leader><leader>", "<cmd>buffer #<cr>", { desc = "Toggle last buffer" })

			-- Sort buffers
			vim.keymap.set("n", "<leader>be", "<cmd>BufferLineSortByExtension<cr>", { desc = "Sort by extension" })
			vim.keymap.set("n", "<leader>bd", "<cmd>BufferLineSortByDirectory<cr>", { desc = "Sort by directory" })

			-- Commands
			vim.api.nvim_create_user_command("BufferlineToggle", function()
				if vim.o.showtabline == 0 then
					vim.o.showtabline = 2
					vim.notify("Bufferline enabled", vim.log.levels.INFO)
				else
					vim.o.showtabline = 0
					vim.notify("Bufferline disabled", vim.log.levels.INFO)
				end
			end, { desc = "Toggle bufferline visibility" })
		end,
	},

	-- Heirline for statusline only
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
			local devicons = require "nvim-web-devicons"

			-- Get Catppuccin colors
			local colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")

			-- Cache frequently used APIs
			local api = vim.api
			local fn = vim.fn
			local diagnostic = vim.diagnostic

			-- ═══════════════════════════════════════════════════════════════════════
			-- 🛠️  UTILITY FUNCTIONS
			-- ═══════════════════════════════════════════════════════════════════════

			local M = {}

			-- Safe function execution
			function M.safe_call(func, fallback)
				local ok, result = pcall(func)
				return ok and result or fallback
			end

			-- Truncate text with ellipsis
			function M.truncate(str, max_len)
				if not str or str == "" then
					return ""
				end
				if #str <= max_len then
					return str
				end
				return str:sub(1, max_len - 3) .. "…"
			end

			-- Get responsive length
			function M.get_responsive_length(base_len)
				local cols = vim.o.columns
				if cols < 100 then
					return math.floor(base_len * 0.6)
				elseif cols < 150 then
					return base_len
				else
					return math.floor(base_len * 1.3)
				end
			end

			-- ═══════════════════════════════════════════════════════════════════════
			-- 🎨 PRIMITIVES
			-- ═══════════════════════════════════════════════════════════════════════

			local Space = { provider = " " }
			local Align = { provider = "%=" }
			local Separator = {
				provider = function()
					return vim.o.columns > 120 and "  │  " or "  "
				end,
				hl = { fg = colors.surface1 },
			}

			-- ═══════════════════════════════════════════════════════════════════════
			-- 🚀 STATUSLINE COMPONENTS
			-- ═══════════════════════════════════════════════════════════════════════

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 📍 Mode Component                                                   │
			-- └─────────────────────────────────────────────────────────────────────┘

			local Mode = {
				init = function(self)
					self.mode = fn.mode()
				end,

				static = {
					modes = {
						n = { "󰰆", "NORMAL", colors.blue },
						i = { "󰰅", "INSERT", colors.green },
						v = { "󰰈", "VISUAL", colors.mauve },
						V = { "󰰉", "V-LINE", colors.mauve },
						["\22"] = { "󰰊", "V-BLOCK", colors.mauve },
						c = { "󰞷", "COMMAND", colors.peach },
						t = { "󰓫", "TERMINAL", colors.yellow },
						R = { "󰛔", "REPLACE", colors.red },
						r = { "󰛔", "REPLACE", colors.red },
					},
				},

				provider = function(self)
					local mode_info = self.modes[self.mode] or { "󰜅", self.mode:upper(), colors.surface1 }
					return string.format("  %s %s  ", mode_info[1], mode_info[2])
				end,

				hl = function(self)
					local mode_info = self.modes[self.mode] or { "", "", colors.surface1 }
					return { fg = colors.base, bg = mode_info[3], bold = true }
				end,

				update = { "ModeChanged", "BufEnter" },
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 📄 File Info Component                                              │
			-- └─────────────────────────────────────────────────────────────────────┘

			local FileInfo = {
				init = function(self)
					self.filename = fn.expand "%:t"
					self.filetype = vim.bo.filetype
					self.modified = vim.bo.modified
					self.readonly = vim.bo.readonly
					self.buftype = vim.bo.buftype
				end,

				-- File icon
				{
					provider = function(self)
						if self.filename == "" then
							return self.buftype == "terminal" and "󰓫 " or "󰈔 "
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

						local _, color = devicons.get_icon_color(self.filename, fn.expand "%:e", { default = true })
						return { fg = color or colors.text }
					end,
				},

				-- Filename
				{
					provider = function(self)
						if self.filename == "" then
							return self.buftype == "terminal" and "Terminal" or "[Untitled]"
						end
						return M.truncate(self.filename, M.get_responsive_length(30))
					end,

					hl = function(self)
						return {
							bold = self.modified,
							fg = self.buftype == "terminal" and colors.yellow
								or self.readonly and colors.red
								or self.modified and colors.peach
								or colors.text,
						}
					end,
				},

				-- File flags
				{
					provider = function(self)
						local flags = {}
						if self.modified then
							table.insert(flags, "󰜄")
						end
						if self.readonly then
							table.insert(flags, "󰌾")
						end
						if vim.bo.buftype == "help" then
							table.insert(flags, "󰘥")
						end
						return #flags > 0 and (" " .. table.concat(flags, " ")) or ""
					end,

					hl = function(self)
						return {
							fg = self.modified and colors.green or self.readonly and colors.red or colors.blue,
							bold = true,
						}
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
					local git_dict = vim.b.gitsigns_status_dict
					if git_dict then
						self.head = vim.b.gitsigns_head or ""
						self.added = git_dict.added or 0
						self.changed = git_dict.changed or 0
						self.removed = git_dict.removed or 0
					else
						self.head = ""
					end
				end,

				-- Branch name
				{
					condition = function(self)
						return self.head ~= ""
					end,
					provider = function(self)
						return string.format(" 󰘬 %s", M.truncate(self.head, M.get_responsive_length(20)))
					end,
					hl = { fg = colors.lavender, bold = true },
				},

				-- Git changes
				{
					condition = function(self)
						return self.added and (self.added > 0 or self.changed > 0 or self.removed > 0)
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
					self.errors = #diagnostic.get(0, { severity = diagnostic.severity.ERROR })
					self.warnings = #diagnostic.get(0, { severity = diagnostic.severity.WARN })
					self.hints = #diagnostic.get(0, { severity = diagnostic.severity.HINT })
				end,

				{
					condition = function(self)
						return self.errors > 0
					end,
					provider = function(self)
						return " 󰅚 " .. self.errors
					end,
					hl = { fg = colors.red, bold = true },
				},
				{
					condition = function(self)
						return self.warnings > 0
					end,
					provider = function(self)
						return " 󰀪 " .. self.warnings
					end,
					hl = { fg = colors.yellow, bold = true },
				},
				{
					condition = function(self)
						return self.hints > 0
					end,
					provider = function(self)
						return " 󰌶 " .. self.hints
					end,
					hl = { fg = colors.teal, bold = true },
				},

				update = { "DiagnosticChanged", "BufEnter" },
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 🔧 LSP Component                                                    │
			-- └─────────────────────────────────────────────────────────────────────┘

			local LSP = {
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
					return string.format(" 󰒋 %s", M.truncate(text, M.get_responsive_length(25)))
				end,

				hl = { fg = colors.sapphire, bold = true },
				update = { "LspAttach", "LspDetach" },
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 📍 Position Component                                               │
			-- └─────────────────────────────────────────────────────────────────────┘

			local Position = {
				provider = function()
					local line = vim.fn.line "."
					local col = vim.fn.col "."
					local total = vim.fn.line "$"
					local percent = total > 0 and math.floor((line / total) * 100) or 0
					return string.format(" 󰍎 %d:%d  %d%% ", line, col, percent)
				end,
				hl = { fg = colors.blue, bold = true },
			}

			-- ┌─────────────────────────────────────────────────────────────────────┐
			-- │ 📊 Scroll Bar Component                                             │
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
			-- 🎯 STATUSLINE ASSEMBLY
			-- ═══════════════════════════════════════════════════════════════════════

			local StatusLine = {
				hl = function()
					return conditions.is_active() and "StatusLine" or "StatusLineNC"
				end,

				-- Left side
				Mode,
				{ provider = "  " },
				FileInfo,
				Git,
				Diagnostics,
				Space,

				-- Center
				Align,

				-- Right side
				LSP,
				Space,
				Position,
				ScrollBar,
			}

			-- ═══════════════════════════════════════════════════════════════════════
			-- 🎨 HIGHLIGHT GROUPS
			-- ═══════════════════════════════════════════════════════════════════════

			local function setup_highlights()
				local highlights = {
					HeirlineStatusLine = { link = "StatusLine" },
					HeirlineStatusLineNC = { link = "StatusLineNC" },
				}

				for group, opts in pairs(highlights) do
					api.nvim_set_hl(0, group, opts)
				end
			end

			-- ═══════════════════════════════════════════════════════════════════════
			-- ⚡ HEIRLINE SETUP (statusline only)
			-- ═══════════════════════════════════════════════════════════════════════

			heirline.setup {
				statusline = StatusLine,
				-- No tabline - using bufferline.nvim instead
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
								"qf",
								"help",
								"man",
								"checkhealth",
							},
						}, args.buf)
					end,
				},
			}

			setup_highlights()

			-- ═══════════════════════════════════════════════════════════════════════
			-- 🔄 AUTOCOMMANDS
			-- ═══════════════════════════════════════════════════════════════════════

			local augroup = api.nvim_create_augroup("HeirlineStatusline", { clear = true })

			-- Refresh on colorscheme change
			api.nvim_create_autocmd("ColorScheme", {
				group = augroup,
				callback = function()
					vim.schedule(function()
						colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")
						setup_highlights()
						vim.cmd "redrawstatus"
					end)
				end,
				desc = "Update colors on colorscheme change",
			})

			vim.notify("🚀 Heirline statusline loaded!", vim.log.levels.INFO)
		end,
	},
}
