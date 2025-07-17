return {
    "akinsho/toggleterm.nvim",
    version = "*",
    keys = {
        { "<leader>tf", desc = "Terminal Float" },
        { "<leader>tv", desc = "Terminal Vertical" },
        { "<leader>tt", desc = "Terminal Split" },
        { "<leader>tg", desc = "Terminal Lazygit" },
        { "<leader>tn", desc = "Terminal Node" },
        { "<leader>tp", desc = "Terminal Python" },
        { "<C-\\>",     desc = "Terminal Toggle",  mode = { "n", "t" } },
    },
    cmd = {
        "ToggleTerm",
        "TermExec",
        "ToggleTermSendCurrentLine",
        "ToggleTermSendVisualLines",
        "ToggleTermSendVisualSelection",
    },
    opts = {
        size = function(term)
            if term.direction == "horizontal" then
                return 15
            elseif term.direction == "vertical" then
                return vim.o.columns * 0.4
            end
        end,
        direction = "horizontal",
        hide_numbers = true,
        shade_terminals = false,
        start_in_insert = true,
        auto_scroll = true,
        persist_size = true,
        persist_mode = true,
        close_on_exit = true,
        shell = vim.o.shell,
        float_opts = {
            border = "rounded",
            width = function()
                return math.floor(vim.o.columns * 0.8)
            end,
            height = function()
                return math.floor(vim.o.lines * 0.8)
            end,
            winblend = 0,
        },
        winbar = { enabled = false },
    },
    config = function(_, opts)
        require("toggleterm").setup(opts)

        local Terminal = require("toggleterm.terminal").Terminal
        local term_manager = {}

        local function create_terminal(key, config)
            if not term_manager[key] then
                term_manager[key] = Terminal:new(vim.tbl_deep_extend("force", config, {
                    on_open = function()
                        vim.cmd("startinsert!")
                    end,
                    on_close = function()
                        vim.cmd("stopinsert!")
                    end,
                    on_exit = function()
                        term_manager[key] = nil
                    end,
                }))
            end
            return term_manager[key]
        end

        local function toggle_terminal(key, config)
            return function()
                local term = create_terminal(key, config or {})
                term:toggle()
            end
        end

        local keymap_opts = { noremap = true, silent = true }
        local keymaps = {
            ["<leader>tf"] = {
                func = toggle_terminal("float", { direction = "float" }),
                desc = "Terminal Float",
                modes = { "n", "t" },
            },
            ["<leader>tv"] = {
                func = toggle_terminal("vertical", { direction = "vertical" }),
                desc = "Terminal Vertical",
                modes = { "n", "t" },
            },
            ["<leader>tt"] = {
                func = toggle_terminal("split", { direction = "horizontal" }),
                desc = "Terminal Split",
                modes = { "n", "t" },
            },
            ["<leader>tg"] = {
                func = toggle_terminal(
                    "lazygit",
                    { direction = "float", cmd = "lazygit", close_on_exit = true }
                ),
                desc = "Terminal Lazygit",
                modes = { "n", "t" },
            },
            ["<leader>tn"] = {
                func = toggle_terminal("node", { direction = "float", cmd = "node", close_on_exit = true }),
                desc = "Terminal Node",
                modes = { "n", "t" },
            },
            ["<leader>tp"] = {
                func = toggle_terminal(
                    "python",
                    { direction = "float", cmd = "python3", close_on_exit = true }
                ),
                desc = "Terminal Python",
                modes = { "n", "t" },
            },
            ["<C-\\>"] = {
                func = toggle_terminal("main", { direction = "float" }),
                desc = "Terminal Toggle",
                modes = { "n", "t" },
            },
        }

        for key, config in pairs(keymaps) do
            vim.keymap.set(
                config.modes,
                key,
                config.func,
                vim.tbl_extend("force", keymap_opts, { desc = config.desc })
            )
        end

        local term_group = vim.api.nvim_create_augroup("ToggleTermCustom", { clear = true })

        vim.api.nvim_create_autocmd("TermOpen", {
            group = term_group,
            pattern = "term://*",
            callback = function()
                local buf_opts = { buffer = 0, silent = true }
                vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], buf_opts)
                vim.keymap.set("t", "jk", [[<C-\><C-n>]], buf_opts)
                vim.keymap.set("t", "<C-h>", [[<Cmd>wincmd h<CR>]], buf_opts)
                vim.keymap.set("t", "<C-j>", [[<Cmd>wincmd j<CR>]], buf_opts)
                vim.keymap.set("t", "<C-k>", [[<Cmd>wincmd k<CR>]], buf_opts)
                vim.keymap.set("t", "<C-l>", [[<Cmd>wincmd l<CR>]], buf_opts)
                vim.keymap.set("t", "<C-q>", [[<C-\><C-n>:q<CR>]], buf_opts)
                vim.opt_local.number = false
                vim.opt_local.relativenumber = false
                vim.opt_local.signcolumn = "no"
                vim.opt_local.foldcolumn = "0"
                vim.opt_local.spell = false
                vim.cmd("startinsert!")
            end,
        })

        vim.api.nvim_create_autocmd("VimResized", {
            group = term_group,
            callback = function()
                vim.cmd("wincmd =")
            end,
        })

        vim.api.nvim_create_autocmd("VimLeavePre", {
            group = term_group,
            callback = function()
                for _, term in pairs(term_manager) do
                    if term then
                        term:close()
                    end
                end
            end,
        })

        vim.api.nvim_create_user_command("TerminalSendLine", function()
            vim.cmd("ToggleTermSendCurrentLine")
        end, { desc = "Send current line to terminal" })

        vim.api.nvim_create_user_command("TerminalSendSelection", function()
            vim.cmd("ToggleTermSendVisualSelection")
        end, { range = true, desc = "Send selection to terminal" })

        vim.api.nvim_create_user_command("TerminalClear", function()
            for key, term in pairs(term_manager) do
                if term then
                    term:close()
                end
                term_manager[key] = nil
            end
        end, { desc = "Clear all terminals" })
    end,
}
