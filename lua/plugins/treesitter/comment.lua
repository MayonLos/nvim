return {
    "numToStr/Comment.nvim",
    dependencies = {
        "JoosepAlviste/nvim-ts-context-commentstring",
    },
    keys = {
        { "<C-/>",      desc = "Toggle line comment",            mode = { "n", "i", "v" } },
        { "<C-_>",      desc = "Toggle line comment (fallback)", mode = { "n", "i", "v" } },
        { "<leader>/",  desc = "Toggle line comment",            mode = { "n", "v" } },
        { "<C-S-A>",    desc = "Toggle block comment",           mode = { "n", "v" } },
        { "<leader>bc", desc = "Toggle block comment",           mode = { "n", "v" } },
    },
    event = { "BufReadPost", "BufNewFile" },
    config = function()
        -- Setup ts-context-commentstring
        vim.g.skip_ts_context_commentstring_module = true
        require("ts_context_commentstring").setup({
            enable_autocmd = false,
        })

        local comment_api = require("Comment.api")
        local esc = vim.api.nvim_replace_termcodes("<ESC>", true, false, true)

        -- Enhanced comment functions
        local function toggle_current_line()
            comment_api.toggle.linewise.current()
        end

        local function toggle_current_block()
            comment_api.toggle.blockwise.current()
        end

        local function toggle_linewise_op(motion)
            return function()
                comment_api.toggle.linewise(motion)
            end
        end

        local function toggle_blockwise_op(motion)
            return function()
                comment_api.toggle.blockwise(motion)
            end
        end

        local function toggle_linewise_visual()
            vim.api.nvim_feedkeys(esc, "nx", false)
            comment_api.toggle.linewise(vim.fn.visualmode())
        end

        local function toggle_blockwise_visual()
            vim.api.nvim_feedkeys(esc, "nx", false)
            comment_api.toggle.blockwise(vim.fn.visualmode())
        end

        -- Setup Comment.nvim with disabled default mappings
        require("Comment").setup({
            padding = true,
            sticky = true,
            ignore = "^$",
            toggler = {
                line = nil, -- Disable default mappings
                block = nil,
            },
            opleader = {
                line = nil, -- Disable default mappings
                block = nil,
            },
            extra = {
                above = nil, -- Disable default mappings
                below = nil,
                eol = nil,
            },
            mappings = {
                basic = false, -- Disable all default mappings
                extra = false,
            },
            pre_hook = require("ts_context_commentstring.integrations.comment_nvim").create_pre_hook(),
            post_hook = function(ctx)
                -- Auto-indent after commenting
                if ctx.range.srow == ctx.range.erow then
                    vim.cmd("normal! ==")
                end
            end,
        })

        -- VSCode-style keymaps
        local keymap_opts = { noremap = true, silent = true }

        -- Primary toggle comment keybind (Ctrl+/)
        vim.keymap.set(
            "n",
            "<C-/>",
            toggle_current_line,
            vim.tbl_extend("force", keymap_opts, { desc = "Toggle line comment" })
        )
        vim.keymap.set("i", "<C-/>", function()
            vim.api.nvim_feedkeys(esc, "nx", false)
            toggle_current_line()
            vim.cmd("startinsert!")
        end, vim.tbl_extend("force", keymap_opts, { desc = "Toggle line comment" }))
        vim.keymap.set(
            "v",
            "<C-/>",
            toggle_linewise_visual,
            vim.tbl_extend("force", keymap_opts, { desc = "Toggle line comment" })
        )

        -- Fallback for terminals that send Ctrl+/ as Ctrl+_
        vim.keymap.set(
            "n",
            "<C-_>",
            toggle_current_line,
            vim.tbl_extend("force", keymap_opts, { desc = "Toggle line comment (fallback)" })
        )
        vim.keymap.set("i", "<C-_>", function()
            vim.api.nvim_feedkeys(esc, "nx", false)
            toggle_current_line()
            vim.cmd("startinsert!")
        end, vim.tbl_extend("force", keymap_opts, { desc = "Toggle line comment (fallback)" }))
        vim.keymap.set(
            "v",
            "<C-_>",
            toggle_linewise_visual,
            vim.tbl_extend("force", keymap_opts, { desc = "Toggle line comment (fallback)" })
        )

        -- Alternative leader-based mapping
        vim.keymap.set(
            "n",
            "<leader>/",
            toggle_current_line,
            vim.tbl_extend("force", keymap_opts, { desc = "Toggle line comment" })
        )
        vim.keymap.set(
            "v",
            "<leader>/",
            toggle_linewise_visual,
            vim.tbl_extend("force", keymap_opts, { desc = "Toggle line comment" })
        )

        -- Block comment toggle (Ctrl+Shift+A)
        vim.keymap.set(
            "n",
            "<C-S-A>",
            toggle_current_block,
            vim.tbl_extend("force", keymap_opts, { desc = "Toggle block comment" })
        )
        vim.keymap.set(
            "v",
            "<C-S-A>",
            toggle_blockwise_visual,
            vim.tbl_extend("force", keymap_opts, { desc = "Toggle block comment" })
        )

        -- Alternative block comment mapping
        vim.keymap.set(
            "n",
            "<leader>bc",
            toggle_current_block,
            vim.tbl_extend("force", keymap_opts, { desc = "Toggle block comment" })
        )
        vim.keymap.set(
            "v",
            "<leader>bc",
            toggle_blockwise_visual,
            vim.tbl_extend("force", keymap_opts, { desc = "Toggle block comment" })
        )

        -- Additional utility mappings
        vim.keymap.set("n", "<leader>ca", function()
            comment_api.insert.linewise.above()
        end, vim.tbl_extend("force", keymap_opts, { desc = "Add comment above" }))

        vim.keymap.set("n", "<leader>cb", function()
            comment_api.insert.linewise.below()
        end, vim.tbl_extend("force", keymap_opts, { desc = "Add comment below" }))

        vim.keymap.set("n", "<leader>ce", function()
            comment_api.insert.linewise.eol()
        end, vim.tbl_extend("force", keymap_opts, { desc = "Add comment at end of line" }))

        -- Operator pending mappings for more advanced usage
        vim.keymap.set(
            "n",
            "gc",
            toggle_linewise_op("g@"),
            vim.tbl_extend("force", keymap_opts, { desc = "Comment operator" })
        )
        vim.keymap.set(
            "n",
            "gb",
            toggle_blockwise_op("g@"),
            vim.tbl_extend("force", keymap_opts, { desc = "Block comment operator" })
        )

        -- Setup filetype-specific comment strings
        local ft = require("Comment.ft")

        -- Programming languages
        ft.set("lua", { "--%s", "--[[%s]]" })
        ft.set("vim", { '"%s' })
        ft.set("c", { "//%s", "/*%s*/" })
        ft.set("cpp", { "//%s", "/*%s*/" })
        ft.set("javascript", { "//%s", "/*%s*/" })
        ft.set("typescript", { "//%s", "/*%s*/" })
        ft.set("python", { "#%s" })
        ft.set("rust", { "//%s", "/*%s*/" })
        ft.set("go", { "//%s", "/*%s*/" })
        ft.set("java", { "//%s", "/*%s*/" })
        ft.set("php", { "//%s", "/*%s*/" })
        ft.set("ruby", { "#%s" })
        ft.set("perl", { "#%s" })
        ft.set("bash", { "#%s" })
        ft.set("sh", { "#%s" })
        ft.set("zsh", { "#%s" })
        ft.set("fish", { "#%s" })

        -- Markup and config languages
        ft.set("html", { "<!--%s-->" })
        ft.set("css", { "/*%s*/" })
        ft.set("scss", { "//%s", "/*%s*/" })
        ft.set("sass", { "//%s", "/*%s*/" })
        ft.set("yaml", { "#%s" })
        ft.set("toml", { "#%s" })
        ft.set("json", { "//%s" })
        ft.set("jsonc", { "//%s" })
        ft.set("xml", { "<!--%s-->" })
        ft.set("markdown", { "<!--%s-->" })

        -- Database
        ft.set("sql", { "--%s", "/*%s*/" })

        -- Other
        ft.set("dockerfile", { "#%s" })
        ft.set("gitignore", { "#%s" })
        ft.set("gitcommit", { "#%s" })
        ft.set("conf", { "#%s" })
        ft.set("dosini", { ";%s" })

        -- Create user commands for advanced usage
        vim.api.nvim_create_user_command("CommentToggle", function()
            toggle_current_line()
        end, { desc = "Toggle line comment" })

        vim.api.nvim_create_user_command("CommentBlock", function()
            toggle_current_block()
        end, { desc = "Toggle block comment" })

        vim.api.nvim_create_user_command("CommentAbove", function()
            comment_api.insert.linewise.above()
        end, { desc = "Add comment above current line" })

        vim.api.nvim_create_user_command("CommentBelow", function()
            comment_api.insert.linewise.below()
        end, { desc = "Add comment below current line" })

        vim.api.nvim_create_user_command("CommentEOL", function()
            comment_api.insert.linewise.eol()
        end, { desc = "Add comment at end of line" })
    end,
}
