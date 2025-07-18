return {
    "stevearc/oil.nvim",
    cmd = { "Oil" },
    keys = {
        { "<leader>o", "<cmd>Oil --float<CR>", desc = "Oil (floating file explorer)" },
        { "-",         "<cmd>Oil<CR>",         desc = "Open parent directory" },
    },
    dependencies = {
        "nvim-tree/nvim-web-devicons",
        "MunifTanjim/nui.nvim",
    },
    config = function()
        local keymaps = {
            ["q"] = "actions.close",
            ["<CR>"] = "actions.select",
            ["<BS>"] = "actions.parent",
            ["<C-s>"] = { "actions.select", opts = { vertical = true } },
            ["<C-v>"] = { "actions.select", opts = { horizontal = true } },
            ["<C-t>"] = { "actions.select", opts = { tab = true } },
            ["~"] = "actions.tcd",
            ["g."] = "actions.toggle_hidden",
            ["g?"] = "actions.show_help",
        }
        local view_options = {
            show_hidden = true,
            natural_order = "fast",
            sort = { { "type", "asc" }, { "name", "asc" } },
        }
        local float_config = {
            padding = 2,
            max_width = 0.8,
            max_height = 0.6,
            border = "rounded",
            win_options = {
                winblend = 10,
                winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
            },
            preview_split = "right",
        }
        local win_options = {
            signcolumn = "yes",
            cursorline = false,
            cursorcolumn = false,
        }
        local git_config = {
            add = function(path)
                return true
            end,
            mv = function(src, dest)
                return true
            end,
            rm = function(path)
                return true
            end,
        }
        local preview_config = {
            preview_method = "fast_scratch",
            update_on_cursor_moved = false,
        }
        local performance_config = {
            watch_for_changes = false,
            cleanup_delay_ms = 2000,
        }
        require("oil").setup({
            default_file_explorer = true,
            delete_to_trash = true,
            skip_confirm_for_simple_edits = false,
            constrain_cursor = "editable",
            view_options = view_options,
            float = float_config,
            win_options = win_options,
            keymaps = keymaps,
            use_default_keymaps = false,
            git = git_config,
            preview_win = preview_config,
            watch_for_changes = performance_config.watch_for_changes,
            cleanup_delay_ms = performance_config.cleanup_delay_ms,
        })
    end,
}
