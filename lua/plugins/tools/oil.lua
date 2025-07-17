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
        -- 键位映射配置
        -- ===============================
        local keymaps = {
            -- 基础操作
            ["q"] = "actions.close",
            ["<CR>"] = "actions.select",
            ["<BS>"] = "actions.parent",

            -- 分割窗口打开
            ["<C-s>"] = { "actions.select", opts = { vertical = true } },
            ["<C-v>"] = { "actions.select", opts = { horizontal = true } },
            ["<C-t>"] = { "actions.select", opts = { tab = true } },

            -- 目录操作
            ["~"] = "actions.tcd",

            -- 显示控制
            ["g."] = "actions.toggle_hidden",
            ["g?"] = "actions.show_help",
        }

        -- ===============================
        -- 视图选项配置
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
        -- 浮动窗口配置
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
        -- 窗口选项配置
        -- ===============================
        local win_options = {
            signcolumn = "yes",
            cursorline = false,
            cursorcolumn = false,
        }

        -- ===============================
        -- Git 集成配置
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
        -- 预览窗口配置
        -- ===============================
        local preview_config = {
            preview_method = "fast_scratch",
            update_on_cursor_moved = false,
        }

        -- ===============================
        -- 性能配置
        -- ===============================
        local performance_config = {
            watch_for_changes = false,
            cleanup_delay_ms = 1000,
        }

        -- ===============================
        -- 主配置
        -- ===============================
        require("oil").setup({
            -- 基础设置
            default_file_explorer = true,
            delete_to_trash = true,
            skip_confirm_for_simple_edits = true,
            constrain_cursor = false,

            -- 功能模块配置
            view_options = view_options,
            float = float_config,
            win_options = win_options,
            keymaps = keymaps,
            git = git_config,
            preview_win = preview_config,

            -- 性能配置
            watch_for_changes = performance_config.watch_for_changes,
            cleanup_delay_ms = performance_config.cleanup_delay_ms,
        })
    end,
}
