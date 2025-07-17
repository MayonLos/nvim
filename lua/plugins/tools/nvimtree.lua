return {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    config = function()
        local api = require("nvim-tree.api")
        local tree = api.tree

        -- ===============================
        -- Sorting module
        -- ===============================
        local sort_module = {
            methods = {
                "name",
                "case_sensitive",
                "modification_time",
                "extension",
                "natural",
            },
            current = 1,
        }

        -- Natural sorting comparison function
        local function natural_compare(left, right)
            local left_name = left.name:lower()
            local right_name = right.name:lower()

            -- Extract number and text chunks
            local function extract_chunks(str)
                local chunks = {}
                for chunk in str:gmatch("[0-9]+|[^0-9]+") do
                    local num = tonumber(chunk)
                    table.insert(chunks, num or chunk)
                end
                return chunks
            end

            local left_chunks = extract_chunks(left_name)
            local right_chunks = extract_chunks(right_name)

            for i = 1, math.max(#left_chunks, #right_chunks) do
                local l_chunk = left_chunks[i] or ""
                local r_chunk = right_chunks[i] or ""

                -- Number comparison
                if type(l_chunk) == "number" and type(r_chunk) == "number" then
                    if l_chunk ~= r_chunk then
                        return l_chunk < r_chunk
                    end
                    -- String comparison
                elseif l_chunk ~= r_chunk then
                    return tostring(l_chunk) < tostring(r_chunk)
                end
            end

            return false
        end

        -- Sorting function
        local function sort_nodes(nodes)
            local method = sort_module.methods[sort_module.current]

            if method == "natural" then
                table.sort(nodes, natural_compare)
            else
                table.sort(nodes, function(a, b)
                    if method == "name" then
                        return a.name:lower() < b.name:lower()
                    elseif method == "case_sensitive" then
                        return a.name < b.name
                    elseif method == "modification_time" then
                        return (a.modified or 0) > (b.modified or 0)
                    elseif method == "extension" then
                        local a_ext = a.name:match("^.+(%..+)$") or ""
                        local b_ext = b.name:match("^.+(%..+)$") or ""
                        return a_ext ~= b_ext and a_ext < b_ext or a.name < b.name
                    else
                        return a.name < b.name
                    end
                end)
            end

            return nodes
        end

        -- Cycle sorting method
        local function cycle_sort()
            sort_module.current = sort_module.current >= #sort_module.methods and 1
                or sort_module.current + 1

            tree.reload()
            vim.notify("Sort method: " .. sort_module.methods[sort_module.current], vim.log.levels.INFO)
        end

        -- ===============================
        -- Custom action functions
        -- ===============================
        local custom_actions = {}

        -- ARIA navigation - left arrow behavior
        function custom_actions.aria_left()
            local node = tree.get_node_under_cursor()
            if node.nodes and node.open then
                api.node.open.edit() -- Close opened directory
            else
                api.node.navigate.parent() -- Move to parent directory
            end
        end

        -- ARIA navigation - right arrow behavior
        function custom_actions.aria_right()
            local node = tree.get_node_under_cursor()
            if node.nodes and not node.open then
                api.node.open.edit() -- Open closed directory
            end
        end

        -- Edit or open file and close tree
        function custom_actions.edit_or_open()
            local node = tree.get_node_under_cursor()

            if node.nodes then
                api.node.open.edit() -- Expand/collapse directory
            else
                api.node.open.edit() -- Open file
                tree.close() -- Close tree
            end
        end

        -- Vertical split preview, keep focus on tree
        function custom_actions.vsplit_preview()
            local node = tree.get_node_under_cursor()

            if node.nodes then
                api.node.open.edit() -- Expand/collapse directory
            else
                api.node.open.vertical() -- Open file in vertical split
            end

            tree.focus() -- Refocus tree
        end

        -- Silently open new tab
        function custom_actions.open_tab_silent(node)
            api.node.open.tab(node)
            vim.cmd.tabprev() -- Go back to previous tab
        end

        -- Git stage/unstage
        function custom_actions.git_add()
            local node = tree.get_node_under_cursor()
            local git_status = node.git_status.file

            -- If directory, get child status
            if not git_status then
                git_status = (node.git_status.dir.direct and node.git_status.dir.direct[1])
                    or (node.git_status.dir.indirect and node.git_status.dir.indirect[1])
            end

            if git_status then
                -- Stage untracked/unstaged files
                if git_status:match("^[%?%s]") or git_status:match("M$") then
                    vim.cmd("silent !git add " .. vim.fn.shellescape(node.absolute_path))
                    -- Unstage staged files
                elseif git_status:match("^[MA]") then
                    vim.cmd("silent !git restore --staged " .. vim.fn.shellescape(node.absolute_path))
                end
            end

            tree.reload()
        end

        -- ===============================
        -- Mark operations
        -- ===============================
        local mark_operations = {}

        -- Mark and move down
        function mark_operations.mark_move_j()
            api.marks.toggle()
            vim.cmd("normal! j")
        end

        function mark_operations.mark_move_k()
            api.marks.toggle()
            vim.cmd("normal! k")
        end

        -- Get marked files or current file
        local function get_marked_or_current()
            local marks = api.marks.list()
            if #marks == 0 then
                marks = { tree.get_node_under_cursor() }
            end
            return marks
        end

        -- Move files to trash
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

        -- Permanently delete files
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

        -- Copy files
        function mark_operations.copy_files()
            local marks = get_marked_or_current()
            for _, node in ipairs(marks) do
                api.fs.copy.node(node)
            end
            api.marks.clear()
            tree.reload()
        end

        -- Cut files
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

            -- Load default mappings
            api.config.mappings.default_on_attach(bufnr)

            -- Core key mappings
            local core_mappings = {
                -- Navigation
                ["<Left>"] = { custom_actions.aria_left, "ARIA: Left Arrow / Close Node / Parent" },
                ["<Right>"] = { custom_actions.aria_right, "ARIA: Right Arrow / Open Node" },
                ["h"] = { tree.close, "Close Current Tree" },
                ["H"] = { tree.collapse_all, "Collapse All Trees" },
                ["l"] = { custom_actions.edit_or_open, "Edit Or Open / Close Tree" },
                ["L"] = { custom_actions.vsplit_preview, "Vsplit Preview / Keep Focus on Tree" },

                -- File operations
                ["T"] = { custom_actions.open_tab_silent, "Open Tab Silent" },
                ["ga"] = { custom_actions.git_add, "Git Add/Restore" },

                -- Mark operations
                ["J"] = { mark_operations.mark_move_j, "Toggle Bookmark Down" },
                ["K"] = { mark_operations.mark_move_k, "Toggle Bookmark Up" },

                -- File operations
                ["dd"] = { mark_operations.cut_files, "Cut File(s)" },
                ["df"] = { mark_operations.trash_files, "Trash File(s)" },
                ["dF"] = { mark_operations.remove_files, "Remove File(s)" },
                ["yy"] = { mark_operations.copy_files, "Copy File(s)" },

                -- Sorting
                ["<leader>t"] = { cycle_sort, "Cycle Sort" },
            }

            -- Apply key mappings
            for key, mapping in pairs(core_mappings) do
                vim.keymap.set("n", key, mapping[1], opts(mapping[2]))
            end
        end

        -- ===============================
        -- nvim-tree configuration
        -- ===============================
        require("nvim-tree").setup({
            view = {
                width = 30,
                side = "left",
            },
            git = {
                enable = true,
            },
            sort_by = sort_nodes,
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
            on_attach = setup_keymaps,
        })

        -- ===============================
        -- Window and statusline configuration
        -- ===============================

        -- Set empty statusline
        api.events.subscribe(api.events.Event.TreeOpen, function()
            local tree_winid = tree.winid()
            if tree_winid then
                vim.api.nvim_set_option_value("statusline", " ", { win = tree_winid })
            end
        end)

        -- Smart quit behavior
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
        -- Global keymap
        -- ===============================
        vim.keymap.set(
            "n",
            "<leader>e",
            ":NvimTreeToggle<CR>",
            { silent = true, noremap = true, desc = "Toggle NvimTree" }
        )
    end,
}
