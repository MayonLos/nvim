return {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
        signs = {
            add = { text = "▎" },
            change = { text = "▎" },
            delete = { text = "▁" },
            topdelete = { text = "▔" },
            changedelete = { text = "▒" },
            untracked = { text = "┆" },
        },

        signs_staged = {
            add = { text = "▎" },
            change = { text = "▎" },
            delete = { text = "▁" },
            topdelete = { text = "▔" },
            changedelete = { text = "▒" },
        },

        signcolumn = true,
        numhl = true,
        linehl = false,
        word_diff = false,
        watch_gitdir = { interval = 1000, follow_files = true },
        attach_to_untracked = true,
        current_line_blame = false,

        current_line_blame_opts = {
            virt_text = true,
            virt_text_pos = "eol",
            delay = 1000,
            ignore_whitespace = false,
            virt_text_priority = 100,
        },

        sign_priority = 6,
        update_debounce = 100,
        status_formatter = nil,
        max_file_length = 40000,
        preview_config = {
            border = "rounded",
            style = "minimal",
            relative = "cursor",
            row = 0,
            col = 1,
        },

        on_attach = function(bufnr)
            local gs = require("gitsigns")

            local function map(mode, l, r, opts)
                opts = opts or {}
                opts.buffer = bufnr
                vim.keymap.set(mode, l, r, opts)
            end

            -- Navigation
            map("n", "]c", function()
                if vim.wo.diff then
                    vim.cmd.normal({ "]c", bang = true })
                else
                    gs.nav_hunk("next")
                end
            end, { desc = "Next hunk" })

            map("n", "[c", function()
                if vim.wo.diff then
                    vim.cmd.normal({ "[c", bang = true })
                else
                    gs.nav_hunk("prev")
                end
            end, { desc = "Previous hunk" })

            -- Actions
            map("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
            map("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
            map("v", "<leader>hs", function()
                gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end, { desc = "Stage hunk (visual)" })
            map("v", "<leader>hr", function()
                gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
            end, { desc = "Reset hunk (visual)" })

            map("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
            map("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
            map("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
            map("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })

            map("n", "<leader>hb", function()
                gs.blame_line({ full = true })
            end, { desc = "Blame line" })

            map("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
            map("n", "<leader>hD", function()
                gs.diffthis("~")
            end, { desc = "Diff this (cached)" })

            -- Toggles
            map("n", "<leader>gb", gs.toggle_current_line_blame, { desc = "Toggle current line blame" })
            map("n", "<leader>gd", gs.toggle_deleted, { desc = "Toggle deleted" })
            map("n", "<leader>gw", gs.toggle_word_diff, { desc = "Toggle word diff" })
            map("n", "<leader>gl", gs.toggle_linehl, { desc = "Toggle line highlight" })
            map("n", "<leader>gn", gs.toggle_numhl, { desc = "Toggle number highlight" })
            map("n", "<leader>gs", gs.toggle_signs, { desc = "Toggle signs" })

            -- Text object
            map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "Select hunk" })
        end,
    },
}
