return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    config = function()
        local api = require("nvim-tree.api")
        local tree = api.tree

        -- ===============================
        -- Sort method cycle support
        -- ===============================
        local SORT_METHODS = { "name", "case_sensitive", "modification_time", "extension" }
        local sort_current = 1

        local function cycle_sort()
            if sort_current >= #SORT_METHODS then
                sort_current = 1
            else
                sort_current = sort_current + 1
            end
            api.tree.reload()
        end

        local function sort_by()
            return SORT_METHODS[sort_current]
        end

        -- ===============================
        -- Custom action functions
        -- ===============================
        local custom_actions = {}

        function custom_actions.aria_left()
            local node = tree.get_node_under_cursor()
            if node.nodes and node.open then
                api.node.open.edit()
            else
                api.node.navigate.parent()
            end
        end

        function custom_actions.aria_right()
            local node = tree.get_node_under_cursor()
            if node.nodes and not node.open then
                api.node.open.edit()
            end
        end

        function custom_actions.edit_or_open()
            local node = tree.get_node_under_cursor()
            if node.nodes then
                api.node.open.edit()
            else
                api.node.open.edit()
                tree.close()
            end
        end

        function custom_actions.vsplit_preview()
            local node = tree.get_node_under_cursor()
            if node.nodes then
                api.node.open.edit()
            else
                api.node.open.vertical()
            end
            tree.focus()
        end

        function custom_actions.open_tab_silent(node)
            api.node.open.tab(node)
            vim.cmd.tabprev()
        end

        function custom_actions.git_add()
            local node = tree.get_node_under_cursor()
            local git_status = node.git_status.file
            if not git_status then
                git_status = (node.git_status.dir.direct and node.git_status.dir.direct[1])
                    or (node.git_status.dir.indirect and node.git_status.dir.indirect[1])
            end
            if git_status then
                if git_status:match("^[%?%s]") or git_status:match("M$") then
                    vim.cmd("silent !git add " .. vim.fn.shellescape(node.absolute_path))
                elseif git_status:match("^[MA]") then
                    vim.cmd("silent !git restore --staged " .. vim.fn.shellescape(node.absolute_path))
                end
            end
            tree.reload()
        end

        local function change_root_to_global_cwd()
            local global_cwd = vim.fn.getcwd(-1, -1)
            api.tree.change_root(global_cwd)
        end

        -- ===============================
        -- Mark operations
        -- ===============================
        local mark_operations = {}

        function mark_operations.mark_move_j()
            api.marks.toggle()
            vim.cmd("normal! j")
        end

        function mark_operations.mark_move_k()
            api.marks.toggle()
            vim.cmd("normal! k")
        end

        local function get_marked_or_current()
            local marks = api.marks.list()
            if #marks == 0 then
                marks = { tree.get_node_under_cursor() }
            end
            return marks
        end

        function mark_operations.trash_files()
            local marks = get_marked_or_current()
            vim.ui.input({ prompt = string.format("Trash %d file(s)? [y/N]: ", #marks) }, function(input)
                if input and input:lower() == "y" then
                    for _, node in ipairs(marks) do
                        api.fs.trash(node)
                    end
                    api.marks.clear()
                    tree.reload()
                end
            end)
        end

        function mark_operations.remove_files()
            local marks = get_marked_or_current()
            vim.ui.input(
                { prompt = string.format("Permanently delete %d file(s)? [y/N]: ", #marks) },
                function(input)
                    if input and input:lower() == "y" then
                        for _, node in ipairs(marks) do
                            api.fs.remove(node)
                        end
                        api.marks.clear()
                        tree.reload()
                    end
                end
            )
        end

        function mark_operations.copy_files()
            local marks = get_marked_or_current()
            for _, node in ipairs(marks) do
                api.fs.copy.node(node)
            end
            api.marks.clear()
            tree.reload()
        end

        function mark_operations.cut_files()
            local marks = get_marked_or_current()
            for _, node in ipairs(marks) do
                api.fs.cut(node)
            end
            api.marks.clear()
            tree.reload()
        end

        -- ===============================
        -- Keymap configuration
        -- ===============================
        local function setup_keymaps(bufnr)
            local function opts(desc)
                return {
                    desc = "nvim-tree: " .. desc,
                    buffer = bufnr,
                    noremap = true,
                    silent = true,
                    nowait = true,
                }
            end

            api.config.mappings.default_on_attach(bufnr)

            local core_mappings = {
                ["<Left>"] = { custom_actions.aria_left, "ARIA: Left Arrow / Close Node / Parent" },
                ["<Right>"] = { custom_actions.aria_right, "ARIA: Right Arrow / Open Node" },
                ["h"] = { tree.close, "Close Current Tree" },
                ["H"] = { tree.collapse_all, "Collapse All Trees" },
                ["l"] = { custom_actions.edit_or_open, "Edit Or Open / Close Tree" },
                ["L"] = { custom_actions.vsplit_preview, "Vsplit Preview / Keep Focus on Tree" },
                ["T"] = { custom_actions.open_tab_silent, "Open Tab Silent" },
                ["ga"] = { custom_actions.git_add, "Git Add/Restore" },
                ["<C-c>"] = { change_root_to_global_cwd, "Change Root To Global CWD" },
                ["J"] = { mark_operations.mark_move_j, "Toggle Bookmark Down" },
                ["K"] = { mark_operations.mark_move_k, "Toggle Bookmark Up" },
                ["dd"] = { mark_operations.cut_files, "Cut File(s)" },
                ["df"] = { mark_operations.trash_files, "Trash File(s)" },
                ["dF"] = { mark_operations.remove_files, "Remove File(s)" },
                ["yy"] = { mark_operations.copy_files, "Copy File(s)" },
                ["<leader>t"] = { cycle_sort, "Cycle Sort Method" },
            }

            for key, mapping in pairs(core_mappings) do
                vim.keymap.set("n", key, mapping[1], opts(mapping[2]))
            end
        end

        -- ===============================
        -- nvim-tree setup
        -- ===============================
        require("nvim-tree").setup({
            view = {
                width = 30,
                side = "left",
            },
            git = {
                enable = true,
            },
            live_filter = {
                prefix = "[FILTER]: ",
                always_show_folders = false,
            },
            ui = {
                confirm = {
                    remove = true,
                    trash = false,
                },
            },
            sort_by = sort_by,
            on_attach = setup_keymaps,
        })

        -- ===============================
        -- Empty statusline on tree window
        -- ===============================
        api.events.subscribe(api.events.Event.TreeOpen, function()
            local tree_winid = tree.winid()
            if tree_winid then
                vim.api.nvim_set_option_value("statusline", " ", { win = tree_winid })
            end
        end)

        -- ===============================
        -- Smart quit
        -- ===============================
        local function setup_smart_quit()
            vim.api.nvim_create_autocmd({ "BufEnter", "QuitPre" }, {
                nested = false,
                callback = function(event)
                    if not tree.is_visible() then
                        return
                    end

                    local focusable_wins = vim.tbl_filter(function(winid)
                        return vim.api.nvim_win_get_config(winid).focusable
                    end, vim.api.nvim_list_wins())

                    local win_count = #focusable_wins

                    if event.event == "QuitPre" and win_count == 2 then
                        vim.api.nvim_cmd({ cmd = "qall" }, {})
                    elseif event.event == "BufEnter" and win_count == 1 then
                        vim.defer_fn(function()
                            tree.toggle({ find_file = true, focus = true })
                            tree.toggle({ find_file = true, focus = false })
                        end, 10)
                    end
                end,
            })
        end

        setup_smart_quit()

        -- ===============================
        -- Global toggle keymap
        -- ===============================
        vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", {
            silent = true,
            noremap = true,
            desc = "Toggle NvimTree",
        })
    end,
}
