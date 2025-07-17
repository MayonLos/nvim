return {
    {
        "rebelot/heirline.nvim",  -- Plugin for customizable statusline and winbar
        event = "VeryLazy",       -- Load plugin on VeryLazy event to optimize startup time
        dependencies = {
            "nvim-tree/nvim-web-devicons", -- Provides file type icons
            "neovim/nvim-lspconfig", -- LSP configuration for Neovim
            "lewis6991/gitsigns.nvim", -- Git integration for signs and status
            "catppuccin/nvim",    -- Catppuccin theme for color palette
        },
        config = function()
            -- Import required modules
            local conditions = require("heirline.conditions")
            local devicons = require("nvim-web-devicons")
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
                provider = "  ",      -- Separator with custom highlight
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

            -- FileInfo component: Displays file name, icon, and status (modified/readonly)
            local FileInfo = {
                init = function(self)
                    self.filename = fn.expand("%:t") -- Get file name
                    self.filepath = fn.expand("%:p") -- Get full file path
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
                            devicons.get_icon_color(self.filename, fn.expand("%:e"), { default = true })
                        return string.format("%s %s", icon or "󰈔", self.filename) -- Display icon and file name
                    end,
                    hl = function(self)
                        local _, icon_color =
                            devicons.get_icon_color(self.filename, fn.expand("%:e"), { default = true })
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
                    hl = { fg = colors.peach, bold = true },       -- Highlight for branch
                },
                {
                    -- Subcomponent: Git change statistics
                    condition = function(self)
                        return self.has_changes -- Only show if there are changes
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
                        return " " .. table.concat(changes, " ") -- Combine change indicators
                    end,
                },
                update = { "User", pattern = "GitSignsUpdate" }, -- Update on Git signs update
            }

            -- Diagnostics component: Displays LSP diagnostic counts
            local Diagnostics = {
                condition = conditions.has_diagnostics,                          -- Only show if diagnostics exist
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
                        return self.errors > 0 and string.format(" %s %d", self.icons.error, self.errors) or
                        ""                                                                    -- Error display
                    end,
                    hl = { fg = colors.red, bold = true },
                },
                {
                    provider = function(self)
                        return self.warnings > 0 and string.format(" %s %d", self.icons.warn, self.warnings)
                            or "" -- Warning display
                    end,
                    hl = { fg = colors.yellow, bold = true },
                },
                {
                    provider = function(self)
                        return self.infos > 0 and string.format(" %s %d", self.icons.info, self.infos) or
                        ""                                                                 -- Info display
                    end,
                    hl = { fg = colors.blue, bold = true },
                },
                {
                    provider = function(self)
                        return self.hints > 0 and string.format(" %s %d", self.icons.hint, self.hints) or
                        ""                                                                 -- Hint display
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
                    for _, client in ipairs(vim.lsp.get_clients({ bufnr = 0 })) do
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

            -- FileFormat component: Displays file format (unix/dos/mac)
            local FileFormat = {
                static = {
                    format_icons = {
                        unix = "󰻀", -- Unix format icon
                        dos = "󰍲", -- DOS format icon
                        mac = "󰍴", -- Mac format icon
                    },
                },
                provider = function(self)
                    local format = bo.fileformat
                    local icon = self.format_icons[format] or "󰈔"
                    return string.format("%s %s", icon, format) -- Display format with icon
                end,
                hl = { fg = colors.overlay2 },
            }

            -- Position component: Displays cursor position and percentage
            local Position = {
                init = function(self)
                    local cursor = api.nvim_win_get_cursor(0)
                    local lines = api.nvim_buf_line_count(0)
                    self.row = cursor[1]                                    -- Current row
                    self.col = cursor[2] + 1                                -- Current column (1-based)
                    self.lines = lines                                      -- Total lines
                    self.percent = lines > 0 and math.floor((self.row / lines) * 100) or 0 -- Percentage position
                end,
                flexible = 1,                                               -- Flexible component with multiple display modes
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

            -- Main StatusLine: Combines all components
            local StatusLine = {
                hl = function()
                    return conditions.is_active() and "StatusLine" or
                    "StatusLineNC"                                    -- Highlight based on window activity
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
                Separator,
                FileEncoding,
                Space,
                FileFormat,
                Separator,
                Position,
                Spacer,
                ScrollBar,
            }

            -- Function to set up highlight groups
            local function setup_highlights()
                local highlights = {
                    GitAdded = { fg = colors.green, bold = true }, -- Highlight for Git added lines
                    GitChanged = { fg = colors.yellow, bold = true }, -- Highlight for Git changed lines
                    GitRemoved = { fg = colors.red, bold = true }, -- Highlight for Git removed lines
                }
                for group, hl in pairs(highlights) do
                    api.nvim_set_hl(0, group, hl) -- Apply highlights
                end
            end

            -- Initialize Heirline with the statusline configuration
            require("heirline").setup({
                statusline = StatusLine,
                opts = {
                    colors = colors, -- Use Catppuccin color palette
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
                        }, args.buf) -- Disable winbar for specific buffer types/filetypes
                    end,
                },
            })

            -- Set up highlight groups
            setup_highlights()

            -- Create autocommand group for optimization
            local augroup = api.nvim_create_augroup("HeirlineOptimized", { clear = true })

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
                        bo.buflisted = false -- Exclude certain buffers from listing
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
                    vim.cmd("redrawstatus")
                end,
            })
        end,
    },
}
