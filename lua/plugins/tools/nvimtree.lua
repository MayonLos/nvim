return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    event = "VeryLazy",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
        local api = require("nvim-tree.api")
        local tree = api.tree

        -- ========== Sort Cycle ==========
        local SORT_METHODS = { "name", "case_sensitive", "modification_time", "extension" }
        local sort_index = 1
        local function cycle_sort()
            sort_index = sort_index % #SORT_METHODS + 1
            tree.reload()
        end
        local function sort_by()
            return SORT_METHODS[sort_index]
        end

        -- ========== Custom Actions ==========
        local actions = {}

        function actions.aria_left()
            local node = tree.get_node_under_cursor()
            if node.nodes and node.open then
                api.node.open.edit()
            else
                api.node.navigate.parent()
            end
        end

        function actions.aria_right()
            local node = tree.get_node_under_cursor()
            if node.nodes and not node.open then
                api.node.open.edit()
            end
        end

        function actions.edit_or_open()
            local node = tree.get_node_under_cursor()
            if node.nodes then
                api.node.open.edit()
            else
                api.node.open.edit()
                tree.close()
            end
        end

        function actions.vsplit_preview()
            local node = tree.get_node_under_cursor()
            if not node.nodes then
                api.node.open.vertical()
            else
                api.node.open.edit()
            end
            tree.focus()
        end

        function actions.open_tab_silent()
            api.node.open.tab()
            vim.cmd("tabprev")
        end

        function actions.git_add()
            local node = tree.get_node_under_cursor()
            local git_status = node.git_status and node.git_status.file
            git_status = git_status or (node.git_status.dir.direct and node.git_status.dir.direct[1])
            if git_status then
                local path = vim.fn.shellescape(node.absolute_path)
                if git_status:match("^[%?%s]") or git_status:match("M$") then
                    vim.fn.jobstart({ "git", "add", path }, { detach = true })
                elseif git_status:match("^[MA]") then
                    vim.fn.jobstart({ "git", "restore", "--staged", path }, { detach = true })
                end
            end
            tree.reload()
        end

        function actions.change_root_to_global()
            api.tree.change_root(vim.fn.getcwd(-1, -1))
        end

        -- ========== Marked File Ops ==========
        local function get_marked_or_current()
            local marks = api.marks.list()
            return #marks > 0 and marks or { tree.get_node_under_cursor() }
        end

        local marks = {}

        function marks.toggle_down()
            api.marks.toggle()
            vim.cmd.normal("j")
        end

        function marks.toggle_up()
            api.marks.toggle()
            vim.cmd.normal("k")
        end

        function marks.trash()
            local files = get_marked_or_current()
            vim.ui.input({ prompt = ("Trash %d file(s)? [y/N]: "):format(#files) }, function(input)
                if input and input:lower() == "y" then
                    for _, node in ipairs(files) do
                        api.fs.trash(node)
                    end
                    api.marks.clear()
                    tree.reload()
                end
            end)
        end

        function marks.remove()
            local files = get_marked_or_current()
            vim.ui.input({ prompt = ("Delete %d file(s)? [y/N]: "):format(#files) }, function(input)
                if input and input:lower() == "y" then
                    for _, node in ipairs(files) do
                        api.fs.remove(node)
                    end
                    api.marks.clear()
                    tree.reload()
                end
            end)
        end

        function marks.copy()
            for _, node in ipairs(get_marked_or_current()) do
                api.fs.copy.node(node)
            end
            api.marks.clear()
        end

        function marks.cut()
            for _, node in ipairs(get_marked_or_current()) do
                api.fs.cut(node)
            end
            api.marks.clear()
        end

        -- ========== Keymaps ==========
        local function on_attach(bufnr)
            local function map(key, fn, desc)
                vim.keymap.set("n", "<leader>e" .. key, fn, {
                    buffer = bufnr,
                    noremap = true,
                    silent = true,
                    nowait = true,
                    desc = "nvim-tree: " .. desc,
                })
            end

            api.config.mappings.default_on_attach(bufnr)

            -- Merge: Add direct h/l and arrow key bindings
            vim.keymap.set(
                "n",
                "h",
                actions.aria_left,
                { buffer = bufnr, noremap = true, silent = true, desc = "nvim-tree: Close node / Parent" }
            )
            vim.keymap.set(
                "n",
                "<Left>",
                actions.aria_left,
                { buffer = bufnr, noremap = true, silent = true, desc = "nvim-tree: Close node / Parent" }
            )
            vim.keymap.set(
                "n",
                "l",
                actions.aria_right,
                { buffer = bufnr, noremap = true, silent = true, desc = "nvim-tree: Open node" }
            )
            vim.keymap.set(
                "n",
                "<Right>",
                actions.aria_right,
                { buffer = bufnr, noremap = true, silent = true, desc = "nvim-tree: Open node" }
            )

            -- Existing keymaps from first config
            map("h", actions.aria_left, "Close node / Parent")
            map("l", actions.aria_right, "Open node")
            map("q", tree.close, "Close Tree")
            map("c", tree.collapse_all, "Collapse All")
            map("e", actions.edit_or_open, "Edit or Open")
            map("v", actions.vsplit_preview, "Vsplit Preview")
            map("t", actions.open_tab_silent, "Open in Tab (silent)")
            map("g", actions.git_add, "Git Add / Restore")
            map("r", actions.change_root_to_global, "Global CWD")
            map("j", marks.toggle_down, "Mark Down")
            map("k", marks.toggle_up, "Mark Up")
            map("d", marks.cut, "Cut Files")
            map("f", marks.trash, "Trash Files")
            map("D", marks.remove, "Delete Files")
            map("y", marks.copy, "Copy Files")
            map("s", cycle_sort, "Cycle Sort")
        end

        -- ========== Setup ==========
        require("nvim-tree").setup({
            view = { width = 30, side = "left" },
            git = { enable = true },
            live_filter = { prefix = "[FILTER]: ", always_show_folders = false },
            ui = { confirm = { remove = true, trash = false } },
            sort_by = sort_by,
            on_attach = on_attach,
            sync_root_with_cwd = true,
            respect_buf_cwd = true,
            update_focused_file = {
                enable = true,
                update_root = true,
                ignore_list = {},
            },
        })

        -- ========== Empty statusline ==========
        api.events.subscribe(api.events.Event.TreeOpen, function()
            local win = tree.winid()
            if win then
                vim.api.nvim_set_option_value("statusline", " ", { win = win })
            end
        end)

        -- ========== Smart Quit ==========
        vim.api.nvim_create_autocmd({ "BufEnter", "QuitPre" }, {
            callback = function(event)
                if not tree.is_visible() then
                    return
                end
                local wins = vim.tbl_filter(function(w)
                    return vim.api.nvim_win_get_config(w).focusable
                end, vim.api.nvim_list_wins())

                if event.event == "QuitPre" and #wins == 2 then
                    vim.cmd("qall")
                elseif event.event == "BufEnter" and #wins == 1 then
                    vim.defer_fn(function()
                        tree.toggle({ find_file = true, focus = true })
                        tree.toggle({ find_file = true, focus = false })
                    end, 10)
                end
            end,
        })

        -- ========== Global Toggle Key ==========
        vim.keymap.set("n", "<leader>e", ":NvimTreeToggle<CR>", {
            silent = true,
            noremap = true,
            desc = "Toggle NvimTree",
        })
    end,
}
