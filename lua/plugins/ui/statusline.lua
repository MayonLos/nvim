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

			-- 缓存常用函数
			local api = vim.api
			local fn = vim.fn
			local bo = vim.bo
			local diagnostic = vim.diagnostic

			-- 工具函数
			local function is_empty(s)
				return s == nil or s == ""
			end

			-- 基础组件
			local Space = { provider = " " }
			local Spacer = { provider = "  " }
			local Align = { provider = "%=" }
			local Separator = {
				provider = "  ",
				hl = { fg = colors.surface1 },
			}

			-- 模式组件 - 增强视觉效果
			local Mode = {
				init = function(self)
					self.mode = fn.mode()
				end,
				static = {
					mode_map = {
						n = { icon = "", name = "NORMAL", color = colors.blue },
						i = { icon = "", name = "INSERT", color = colors.green },
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

			-- 文件信息组件 - 改进布局
			local FileInfo = {
				init = function(self)
					self.filename = fn.expand("%:t")
					self.filepath = fn.expand("%:p")
					self.filetype = bo.filetype
					self.modified = bo.modified
					self.readonly = bo.readonly
				end,
				{
					-- 文件图标和名称
					provider = function(self)
						if is_empty(self.filename) then
							return "󰈔 [No Name]"
						end

						local icon, icon_color =
							devicons.get_icon_color(self.filename, fn.expand("%:e"), { default = true })

						return string.format("%s %s", icon or "󰈔", self.filename)
					end,
					hl = function(self)
						local _, icon_color =
							devicons.get_icon_color(self.filename, fn.expand("%:e"), { default = true })
						return { fg = icon_color or colors.text }
					end,
				},
				{
					-- 文件状态标识
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

			-- Git 信息组件 - 优化间距
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
					-- Git 分支
					provider = function(self)
						if is_empty(self.head) then
							return ""
						end
						return string.format(" %s %s", self.icons.branch, self.head)
					end,
					hl = { fg = colors.peach, bold = true },
				},
				{
					-- Git 变更统计
					condition = function(self)
						return self.has_changes
					end,
					provider = function(self)
						local changes = {}
						if self.added > 0 then
							table.insert(
								changes,
								string.format("%%#GitAdded#%s %d%%*", self.icons.added, self.added)
							)
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

			-- 诊断信息组件 - 修复间距问题
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
						return self.warnings > 0 and string.format(" %s %d", self.icons.warn, self.warnings)
							or ""
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

			-- 搜索信息组件
			local SearchInfo = {
				condition = function()
					return vim.v.hlsearch ~= 0
				end,
				init = function(self)
					local ok, search = pcall(fn.searchcount)
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
					return string.format(" 󰍉 %d/%d", self.search.current, self.search.total)
				end,
				hl = { fg = colors.yellow, bold = true },
			}

			-- LSP 客户端组件 - 修复间距问题
			local LSPClients = {
				condition = conditions.lsp_attached,
				init = function(self)
					local clients = {}
					for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
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
					-- 修复：确保图标和文本之间有空格
					return string.format(" %s %s", self.icon, text)
				end,
				hl = { fg = colors.mauve, bold = true },
				update = { "LspAttach", "LspDetach" },
			}

			-- 文件编码组件
			local FileEncoding = {
				-- condition = function()
				-- 	local enc = bo.fileencoding
				-- 	return not is_empty(enc) and enc ~= "utf-8"
				-- end,
				provider = function()
					return string.format("󰈍 %s", bo.fileencoding)
				end,
				hl = { fg = colors.overlay2 },
			}

			-- 文件格式组件
			local FileFormat = {
				-- condition = function()
				-- 	return bo.fileformat ~= "unix"
				-- end,
				static = {
					format_icons = {
						unix = "󰻀",
						dos = "󰍲",
						mac = "󰍴",
					},
				},
				provider = function(self)
					local format = bo.fileformat
					local icon = self.format_icons[format] or "󰈔"
					return string.format("%s %s", icon, format)
				end,
				hl = { fg = colors.overlay2 },
			}

			-- 位置信息组件 - 改进布局
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
					-- 完整格式：行/总行数 列号 百分比
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
					-- 中等格式：行/总行数 百分比
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
					-- 简洁格式：仅百分比
					provider = function(self)
						return string.format("%d%%", self.percent)
					end,
					hl = { fg = colors.green },
				},
			}

			-- 滚动条组件
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

			-- 主状态栏 - 优化布局
			local StatusLine = {
				hl = function()
					return conditions.is_active() and "StatusLine" or "StatusLineNC"
				end,

				-- 左侧区域
				Mode,
				Spacer,
				FileInfo,
				Git,
				Diagnostics,
				Space,
				SearchInfo,

				-- 中间对齐
				Align,

				-- 右侧区域
				LSPClients,
				Separator,
				FileEncoding,
				Space,
				FileFormat,
				Separator,
				Position,
				Spacer,
				ScrollBar,
			}

			-- 设置高亮组
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

			-- 初始化 Heirline
			require("heirline").setup({
				statusline = StatusLine,
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
			})

			-- 设置高亮组
			setup_highlights()

			-- 自动命令组
			local augroup = api.nvim_create_augroup("HeirlineOptimized", { clear = true })

			-- 主题更新
			api.nvim_create_autocmd("ColorScheme", {
				group = augroup,
				desc = "Update Heirline colors on colorscheme change",
				callback = function()
					colors = require("catppuccin.palettes").get_palette(vim.g.catppuccin_flavour or "mocha")
					setup_highlights()
				end,
			})

			-- 缓冲区优化
			api.nvim_create_autocmd("FileType", {
				group = augroup,
				desc = "Optimize buffer listing",
				callback = function()
					if vim.tbl_contains({ "wipe", "delete" }, bo.bufhidden) then
						bo.buflisted = false
					end
				end,
			})

			-- 性能优化：插入模式时降低更新频率
			api.nvim_create_autocmd("InsertEnter", {
				group = augroup,
				desc = "Reduce update frequency in insert mode",
				callback = function()
					vim.opt.updatetime = 1000
				end,
			})

			api.nvim_create_autocmd("InsertLeave", {
				group = augroup,
				desc = "Restore update frequency after insert mode",
				callback = function()
					vim.opt.updatetime = 300
				end,
			})

			-- 窗口大小变化时刷新状态栏
			api.nvim_create_autocmd("VimResized", {
				group = augroup,
				desc = "Refresh statusline on window resize",
				callback = function()
					vim.cmd("redrawstatus")
				end,
			})
		end,
	},
}
