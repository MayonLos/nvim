return {
	"echasnovski/mini.statusline",
	version = "*", -- Use the latest version
	event = "VeryLazy",
	dependencies = {
		"nvim-tree/nvim-web-devicons", -- For file icons
		"neovim/nvim-lspconfig", -- For LSP status
	},
	config = function()
		local statusline = require("mini.statusline")
		local devicons = require("nvim-web-devicons")
		local neocodeium = require("neocodeium")

		-- Mode display with Nerd Font icons
		local function section_mode()
			local mode_data = {
				n = " NORMAL", -- Normal mode (Nerd Font: vim icon)
				i = " INSERT", -- Insert mode (Nerd Font: pencil)
				v = "󰒅 VISUAL", -- Visual mode (Nerd Font: visual select)
				V = "󰒅 V-LINE", -- Visual line mode
				["\22"] = "󰒅 V-BLOCK", -- Visual block mode
				c = "󰞷 COMMAND", -- Command mode (Nerd Font: terminal)
				R = "󰏤 REPLACE", -- Replace mode (Nerd Font: replace)
				t = "󰓫 TERM", -- Terminal mode (Nerd Font: terminal)
				s = "󰒅 SELECT", -- Select mode
				S = "󰒅 S-LINE", -- Select line mode
			}
			return mode_data[vim.fn.mode()] or "󰜅 " .. vim.fn.mode() -- Fallback icon
		end

		-- File information with icon and modification status
		local function section_file_info()
			local filename = vim.fn.expand("%:t")
			if filename == "" then
				return "󰈔 [No Name]" -- Nerd Font: file icon
			end

			local icon, hl_group = devicons.get_icon(filename, vim.fn.expand("%:e"), { default = true })
			local modified = vim.bo.modified and "󰜄 " or "" -- Nerd Font: modified indicator

			return string.format("%s %s%s", icon or "󰈔", filename, modified)
		end

		-- Git status with branch and change indicators
		local function section_git()
			if not vim.b.gitsigns_head then
				return ""
			end

			local icons = {
				added = "󰐕 ", -- Nerd Font: plus
				changed = "󰦒 ", -- Nerd Font: change
				removed = "󰍴 ", -- Nerd Font: minus
			}
			local stats = vim.b.gitsigns_status_dict or {}
			local parts = {}

			if stats.added and stats.added > 0 then
				table.insert(parts, icons.added .. stats.added)
			end
			if stats.changed and stats.changed > 0 then
				table.insert(parts, icons.changed .. stats.changed)
			end
			if stats.removed and stats.removed > 0 then
				table.insert(parts, icons.removed .. stats.removed)
			end

			return #parts > 0 and string.format("󰊢 %s | %s", vim.b.gitsigns_head, table.concat(parts, " "))
				or string.format("󰊢 %s", vim.b.gitsigns_head) -- Nerd Font: git branch
		end

		-- Diagnostics with severity-based icons
		local function section_diagnostics()
			local types = {
				{ severity = vim.diagnostic.severity.ERROR, icon = "󰅚 " }, -- Nerd Font: error
				{ severity = vim.diagnostic.severity.WARN, icon = "󰀪 " }, -- Nerd Font: warning
				{ severity = vim.diagnostic.severity.INFO, icon = "󰋽 " }, -- Nerd Font: info
				{ severity = vim.diagnostic.severity.HINT, icon = "󰌶 " }, -- Nerd Font: hint
			}

			local parts = {}
			for _, type in ipairs(types) do
				local count = #vim.diagnostic.get(0, { severity = type.severity })
				if count > 0 then
					table.insert(parts, string.format("%s%d", type.icon, count))
				end
			end

			return #parts > 0 and table.concat(parts, " ") or ""
		end

		-- LSP client information
		local function section_lsp()
			local unique_servers = {}
			for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
				if client.name ~= "null-ls" then
					unique_servers[client.name] = true
				end
			end

			local server_names = vim.tbl_keys(unique_servers)
			if #server_names == 0 then
				return ""
			end

			return "󰒋 " .. table.concat(server_names, ", ") -- Nerd Font: lsp icon
		end

		-- Neocodeium status with connection indicators
		local function section_neocodeium()
			local status, server_status = neocodeium.get_status()
			local status_icons = {
				[0] = "󰬫 ", -- Enabled (Nerd Font: AI icon)
				[1] = "󰚛 ", -- Disabled Globally (Nerd Font: disabled)
				[2] = "󰓅 ", -- Disabled for Buffer (Nerd Font: buffer)
			}
			local server_icons = {
				[0] = "󰖟 ", -- Connected (Nerd Font: connected)
				[1] = "󰠕 ", -- Connecting (Nerd Font: connecting)
				[2] = "󰲜 ", -- Disconnected (Nerd Font: disconnected)
			}

			local status_icon = status_icons[status] or ""
			local server_icon = server_icons[server_status] or ""

			return status_icon .. server_icon
		end

		-- Cursor location with percentage
		local function section_location()
			local line = vim.fn.line(".")
			local col = vim.fn.virtcol(".")
			local percent = math.floor(line / vim.fn.line("$") * 100)

			return string.format("󰍎 %d:%-2d 󰛻 %2d%%", line, col, percent) -- Nerd Font: location, percentage
		end

		-- Statusline configuration
		statusline.setup({
			use_icons = true,
			set_vim_settings = false,
			content = {
				active = function()
					local mode = section_mode()
					local file_info = section_file_info()
					local git = section_git()
					local diag = section_diagnostics()
					local ai = section_neocodeium()
					local lsp = section_lsp()
					local location = section_location()

					-- Layout: Left-aligned main info, right-aligned auxiliary info
					return table.concat({
						"%<", -- Truncation point
						mode,
						git ~= "" and "│ " .. git or "",
						diag ~= "" and "│ " .. diag or "",
						ai ~= "" and "│ " .. ai or "",
						"%=", -- Right-align separator
						lsp ~= "" and lsp .. " │ " or "",
						location,
					})
				end,
				inactive = function()
					return "%f %h%w%q" -- Minimal inactive statusline
				end,
			},
		})

		-- Statusline redraw on relevant events
		vim.api.nvim_create_autocmd({ "User", "DiagnosticChanged", "LspAttach", "LspDetach" }, {
			pattern = {
				"NeoCodeiumStatusChanged",
				"NeoCodeiumServerStatusChanged",
				"GitSignsUpdate",
				"DiagnosticChanged",
				"LspAttach",
				"LspDetach",
			},
			callback = vim.schedule_wrap(function()
				vim.cmd.redrawstatus()
			end),
		})
	end,
}
