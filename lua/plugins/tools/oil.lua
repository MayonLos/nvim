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
        -- ===============================
        -- Keymap configuration
        -- ===============================
        local keymaps = {
            -- Basic operations
            ["q"] = "actions.close",
            ["<CR>"] = "actions.select",
            ["<BS>"] = "actions.parent",

            -- Split window open
            ["<C-s>"] = { "actions.select", opts = { vertical = true } },
            ["<C-v>"] = { "actions.select", opts = { horizontal = true } },
            ["<C-t>"] = { "actions.select", opts = { tab = true } },

            -- Directory operations
            ["~"] = "actions.tcd",

            -- Display controls
            ["g."] = "actions.toggle_hidden",
            ["g?"] = "actions.show_help",
        }

        -- ===============================
        -- View options configuration
        -- ===============================
        local view_options = {
            show_hidden = true,
            natural_order = "fast",
            sort = {
                { "type", "asc" },
                { "name", "asc" },
            },
        }

        -- ===============================
        -- Floating window configuration
        -- ===============================
        local float_config = {
            padding = 2,
            max_width = 80,
            max_height = 30,
            border = "rounded",
            win_options = {
                winblend = 10,
                winhighlight = "Normal:Normal,FloatBorder:FloatBorder",
            },
            preview_split = "right",
        }

        -- ===============================
        -- Window options configuration
        -- ===============================
        local win_options = {
            signcolumn = "yes",
            cursorline = false,
            cursorcolumn = false,
        }

        -- ===============================
        -- Git integration configuration
        -- ===============================
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

        -- ===============================
        -- Preview window configuration
        -- ===============================
        local preview_config = {
            preview_method = "fast_scratch",
            update_on_cursor_moved = false,
        }

        -- ===============================
        -- Performance configuration
        -- ===============================
        local performance_config = {
            watch_for_changes = false,
            cleanup_delay_ms = 1000,
        }

        -- ===============================
        -- Main configuration
        -- ===============================
        require("oil").setup({
            -- Basic settings
            default_file_explorer = true,
            delete_to_trash = true,
            skip_confirm_for_simple_edits = true,
            constrain_cursor = false,

            -- Feature module configuration
            view_options = view_options,
            float = float_config,
            win_options = win_options,
            keymaps = keymaps,
            git = git_config,
            preview_win = preview_config,

            -- Performance configuration
            watch_for_changes = performance_config.watch_for_changes,
            cleanup_delay_ms = performance_config.cleanup_delay_ms,
        })
    end,
}
