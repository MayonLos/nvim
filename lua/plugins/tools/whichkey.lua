return {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
        preset = "modern",
        delay = 300,
        expand = 1,
        notify = true,

        filter = function(mapping)
            return mapping.desc and mapping.desc ~= ""
        end,

        spec = {
            mode = { "n", "v" },
            { "<leader>f", group = "Find/File", icon = "" },
            { "<leader>s", group = "Session/Split", icon = "" },
            { "<leader>g", group = "Git", icon = "" },
            { "<leader>h", group = "Hunk", icon = "" },
            { "<leader>l", group = "LSP", icon = "" },
            { "<leader>x", group = "Diagnostics", icon = "" },
            { "<leader>m", group = "Markdown", icon = "" },
            { "<leader>a", group = "AI", icon = "ﮧ" },
            { "<leader>t", group = "Terminal/Toggle", icon = "" },
            { "<leader>b", group = "Buffer", icon = "" },
            { "<leader>d", group = "Debug", icon = "" },
            { "<leader>r", group = "Refactor", icon = "" },
            { "<leader>n", group = "Notes", icon = "" },
            { "<leader>u", group = "UI/Utils", icon = "" },
            { "<leader>w", group = "Window", icon = "" },
            { "<leader>c", group = "Code", icon = "" },
            { "<leader>p", group = "Project", icon = "" },
            { "<leader>q", group = "Quit/Session", icon = "" },
            { "<leader>o", group = "Open", icon = "" },
            { "<leader>e", group = "Explorer", icon = "" },

            -- Common vim operations
            { "g", group = "Goto" },
            { "z", group = "Fold" },
            { "]", group = "Next" },
            { "[", group = "Previous" },
            { "<C-w>", group = "Window" },

            -- Visual mode groups
            { mode = "v", "<leader>", group = "Leader" },
            { mode = "v", "<leader>h", group = "Hunk" },
            { mode = "v", "<leader>l", group = "LSP" },
            { mode = "v", "<leader>c", group = "Code" },
            { mode = "v", "<leader>r", group = "Refactor" },
            { mode = "v", "<leader>a", group = "AI" },
        },

        win = {
            border = "none",
            title = false,
            padding = { 0, 2 },
            zindex = 1000,
        },

        layout = {
            height = { min = 4, max = 25 },
            width = { min = 25, max = 60 },
            spacing = 2,
            align = "center",
        },
        keys = {
            scroll_down = "<c-d>",
            scroll_up = "<c-u>",
        },

        sort = { "local", "order", "group", "alphanum", "mod" },

        replace = {
            ["<leader>"] = "SPC",
            ["<cr>"] = "RET",
            ["<tab>"] = "TAB",
            ["<space>"] = "SPC",
        },

        icons = {
            breadcrumb = "»",
            separator = "➜",
            group = "+",
            ellipsis = "…",
            mappings = true,
            rules = {},
            colors = true,
            keys = {
                Up = " ",
                Down = " ",
                Left = " ",
                Right = " ",
                C = "󰘴 ",
                M = "󰘵 ",
                D = "󰘳 ",
                S = "󰘶 ",
                CR = "󰌑 ",
                Esc = "󱊷 ",
                ScrollWheelDown = "󱕐 ",
                ScrollWheelUp = "󱕑 ",
                NL = "󰌑 ",
                BS = "󰁮",
                Space = "󱁐 ",
                Tab = "󰌒 ",
                F1 = "󱊫",
                F2 = "󱊬",
                F3 = "󱊭",
                F4 = "󱊮",
                F5 = "󱊯",
                F6 = "󱊰",
                F7 = "󱊱",
                F8 = "󱊲",
                F9 = "󱊳",
                F10 = "󱊴",
                F11 = "󱊵",
                F12 = "󱊶",
            },
        },

        show_help = true,
        show_keys = true,

        disable = {
            bt = {},
            ft = {},
        },

        debug = false,
    },

    config = function(_, opts)
        local wk = require("which-key")
        wk.setup(opts)

        -- Add additional key mappings for specific contexts
        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "markdown", "md" },
            callback = function()
                wk.add({
                    { "<leader>m",  group = "Markdown", buffer = true },
                    { "<leader>mp", desc = "Preview",   buffer = true },
                    { "<leader>mt", desc = "Toggle",    buffer = true },
                    { "<leader>mi", desc = "Insert",    buffer = true },
                    { "<leader>ml", desc = "Link",      buffer = true },
                    { "<leader>mb", desc = "Bold",      buffer = true },
                    { "<leader>mc", desc = "Code",      buffer = true },
                })
            end,
        })

        vim.api.nvim_create_autocmd("FileType", {
            pattern = { "python", "lua", "javascript", "typescript", "rust", "go" },
            callback = function()
                wk.add({
                    { "<leader>c",  group = "Code",  buffer = true },
                    { "<leader>cr", desc = "Run",    buffer = true },
                    { "<leader>ct", desc = "Test",   buffer = true },
                    { "<leader>cd", desc = "Debug",  buffer = true },
                    { "<leader>cf", desc = "Format", buffer = true },
                    { "<leader>ci", desc = "Import", buffer = true },
                })
            end,
        })

        -- Add LSP-specific mappings when LSP is attached
        vim.api.nvim_create_autocmd("LspAttach", {
            callback = function(args)
                local buffer = args.buf
                wk.add({
                    { "<leader>l",  group = "LSP",            buffer = buffer },
                    { "<leader>lr", desc = "Rename",          buffer = buffer },
                    { "<leader>la", desc = "Code Action",     buffer = buffer },
                    { "<leader>lf", desc = "Format",          buffer = buffer },
                    { "<leader>ld", desc = "Definition",      buffer = buffer },
                    { "<leader>lD", desc = "Declaration",     buffer = buffer },
                    { "<leader>li", desc = "Implementation",  buffer = buffer },
                    { "<leader>lt", desc = "Type Definition", buffer = buffer },
                    { "<leader>lh", desc = "Hover",           buffer = buffer },
                    { "<leader>ls", desc = "Signature Help",  buffer = buffer },
                    { "<leader>lR", desc = "References",      buffer = buffer },
                    { "<leader>lw", desc = "Workspace",       buffer = buffer },
                })
            end,
        })

        -- Add Git-specific mappings for Git repos
        vim.api.nvim_create_autocmd("BufEnter", {
            callback = function()
                if vim.fn.isdirectory(".git") == 1 then
                    wk.add({
                        { "<leader>g",  group = "Git" },
                        { "<leader>gs", desc = "Status" },
                        { "<leader>ga", desc = "Add" },
                        { "<leader>gc", desc = "Commit" },
                        { "<leader>gp", desc = "Push" },
                        { "<leader>gP", desc = "Pull" },
                        { "<leader>gb", desc = "Branch" },
                        { "<leader>gd", desc = "Diff" },
                        { "<leader>gl", desc = "Log" },
                        { "<leader>gf", desc = "Fetch" },
                        { "<leader>gm", desc = "Merge" },
                        { "<leader>gr", desc = "Reset" },
                        { "<leader>gh", desc = "Hunk" },
                    })
                end
            end,
        })

        -- Terminal-specific mappings
        vim.api.nvim_create_autocmd("TermOpen", {
            callback = function()
                wk.add({
                    { "<leader>t",  group = "Terminal",  buffer = true },
                    { "<leader>tt", desc = "Toggle",     buffer = true },
                    { "<leader>th", desc = "Horizontal", buffer = true },
                    { "<leader>tv", desc = "Vertical",   buffer = true },
                    { "<leader>tf", desc = "Float",      buffer = true },
                    { "<leader>tc", desc = "Close",      buffer = true },
                    { "<leader>tn", desc = "New",        buffer = true },
                })
            end,
        })
    end,
}
