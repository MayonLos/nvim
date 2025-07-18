return {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    cmd = "Telescope",
    dependencies = {
        "nvim-lua/plenary.nvim",
        {
            "nvim-telescope/telescope-fzf-native.nvim",
            build = "make",
            cond = function()
                return vim.fn.executable("make") == 1
            end,
        },
        {
            "nvim-telescope/telescope-ui-select.nvim",
            config = function()
                require("telescope").load_extension("ui-select")
            end,
        },
    },
    keys = {
        -- File operations
        { "<leader>ff", "<cmd>Telescope find_files<cr>",           desc = "Find Files" },
        {
            "<leader>fF",
            "<cmd>Telescope find_files hidden=true no_ignore=true<cr>",
            desc = "Find All Files",
        },
        { "<leader>fg", "<cmd>Telescope live_grep<cr>",            desc = "Live Grep" },
        { "<leader>fw", "<cmd>Telescope grep_string<cr>",          desc = "Grep Word Under Cursor" },
        { "<leader>fb", "<cmd>Telescope buffers<cr>",              desc = "Buffers" },
        { "<leader>fo", "<cmd>Telescope oldfiles<cr>",             desc = "Recent Files" },
        { "<leader>fr", "<cmd>Telescope resume<cr>",               desc = "Resume Last Search" },

        -- LSP & Navigation
        { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Document Symbols" },
        {
            "<leader>fS",
            "<cmd>Telescope lsp_dynamic_workspace_symbols<cr>",
            desc = "Workspace Symbols",
        },
        { "<leader>fd", "<cmd>Telescope diagnostics<cr>",         desc = "Diagnostics" },
        { "<leader>fD", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "Buffer Diagnostics" },
        { "<leader>fj", "<cmd>Telescope jumplist<cr>",            desc = "Jump List" },
        { "<leader>fm", "<cmd>Telescope marks<cr>",               desc = "Marks" },
        { "<leader>fq", "<cmd>Telescope quickfix<cr>",            desc = "Quickfix List" },
        { "<leader>fl", "<cmd>Telescope loclist<cr>",             desc = "Location List" },

        -- Git
        { "<leader>gc", "<cmd>Telescope git_commits<cr>",         desc = "Git Commits" },
        { "<leader>gC", "<cmd>Telescope git_bcommits<cr>",        desc = "Buffer Git Commits" },

        -- Vim internals
        { "<leader>fh", "<cmd>Telescope help_tags<cr>",           desc = "Help Tags" },
        { "<leader>fk", "<cmd>Telescope keymaps<cr>",             desc = "Keymaps" },
        { "<leader>fc", "<cmd>Telescope commands<cr>",            desc = "Commands" },
        { "<leader>fC", "<cmd>Telescope command_history<cr>",     desc = "Command History" },
        { "<leader>f/", "<cmd>Telescope search_history<cr>",      desc = "Search History" },
        { "<leader>fR", "<cmd>Telescope registers<cr>",           desc = "Registers" },
        { "<leader>fa", "<cmd>Telescope autocommands<cr>",        desc = "Autocommands" },
        { "<leader>fH", "<cmd>Telescope highlights<cr>",          desc = "Highlights" },
        { "<leader>fv", "<cmd>Telescope vim_options<cr>",         desc = "Vim Options" },
        { "<leader>ft", "<cmd>ThemePicker<cr>",                   desc = "Theme Picker" },

        -- Current directory search
        {
            "<leader>f.",
            function()
                require("telescope.builtin").find_files({
                    cwd = vim.fn.expand("%:p:h"),
                    prompt_title = "Find Files (Current Directory)",
                })
            end,
            desc = "Find Files in Current Directory",
        },
    },

    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")

        -- Custom actions
        local function copy_to_clipboard(prompt_bufnr)
            local entry = action_state.get_selected_entry()
            if entry then
                local value = entry.path or entry.value or entry.display
                vim.fn.setreg("+", value)
                vim.notify("Copied: " .. vim.fn.fnamemodify(value, ":t"), vim.log.levels.INFO)
            end
        end

        local function open_in_split(prompt_bufnr)
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if entry then
                vim.cmd("split " .. vim.fn.fnameescape(entry.path))
            end
        end

        local function open_in_vsplit(prompt_bufnr)
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if entry then
                vim.cmd("vsplit " .. vim.fn.fnameescape(entry.path))
            end
        end

        telescope.setup({
            defaults = {
                prompt_prefix = "🔍 ",
                selection_caret = "➤ ",
                entry_prefix = "  ",
                multi_icon = "✓",

                layout_strategy = "horizontal",
                layout_config = {
                    horizontal = {
                        prompt_position = "top",
                        preview_width = 0.6,
                        width = 0.9,
                        height = 0.9,
                    },
                    vertical = {
                        prompt_position = "top",
                        preview_height = 0.6,
                        width = 0.9,
                        height = 0.9,
                    },
                },

                sorting_strategy = "ascending",
                path_display = { "truncate" },
                dynamic_preview_title = true,
                results_title = false,

                file_ignore_patterns = {
                    "%.git/",
                    "node_modules/",
                    "%.venv/",
                    "__pycache__/",
                    "%.pyc",
                    "%.pyo",
                    "%.class",
                    "%.o",
                    "%.a",
                    "%.so",
                    "%.dylib",
                    "%.dll",
                    "%.exe",
                    "%.zip",
                    "%.tar",
                    "%.gz",
                    "%.7z",
                    "%.rar",
                    "%.DS_Store",
                    "%.tmp",
                    "%.swp",
                    "%.swo",
                    "%.log",
                    "dist/",
                    "build/",
                    "target/",
                    "%.min%.js",
                    "%.min%.css",
                    "package-lock.json",
                    "yarn.lock",
                },

                mappings = {
                    i = {
                        ["<C-j>"] = actions.move_selection_next,
                        ["<C-k>"] = actions.move_selection_previous,
                        ["<C-n>"] = actions.cycle_history_next,
                        ["<C-p>"] = actions.cycle_history_prev,
                        ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
                        ["<C-y>"] = copy_to_clipboard,
                        ["<C-s>"] = open_in_split,
                        ["<C-v>"] = open_in_vsplit,
                        ["<C-t>"] = actions.select_tab,
                        ["<C-u>"] = false,
                        ["<C-d>"] = actions.delete_buffer,
                        ["<C-f>"] = actions.preview_scrolling_down,
                        ["<C-b>"] = actions.preview_scrolling_up,
                        ["<C-/>"] = actions.which_key,
                    },
                    n = {
                        ["<C-j>"] = actions.move_selection_next,
                        ["<C-k>"] = actions.move_selection_previous,
                        ["<C-q>"] = actions.smart_send_to_qflist + actions.open_qflist,
                        ["<C-y>"] = copy_to_clipboard,
                        ["<C-s>"] = open_in_split,
                        ["<C-v>"] = open_in_vsplit,
                        ["<C-t>"] = actions.select_tab,
                        ["<C-d>"] = actions.delete_buffer,
                        ["<C-f>"] = actions.preview_scrolling_down,
                        ["<C-b>"] = actions.preview_scrolling_up,
                        ["?"] = actions.which_key,
                        ["q"] = actions.close,
                        ["<esc>"] = actions.close,
                    },
                },

                cache_picker = {
                    num_pickers = 10,
                    limit_entries = 1000,
                },

                -- Image preview with chafa
                preview = {
                    mime_hook = function(filepath, bufnr, opts)
                        local is_image = function(path)
                            local image_extensions = { "png", "jpg", "jpeg", "gif", "webp", "svg" }
                            local ext = vim.fn.fnamemodify(path, ":e"):lower()
                            return vim.tbl_contains(image_extensions, ext)
                        end

                        if is_image(filepath) and vim.fn.executable("chafa") == 1 then
                            local term = vim.api.nvim_open_term(bufnr, {})
                            vim.fn.jobstart({
                                "chafa",
                                filepath,
                                "--format=sixels",
                                "--size=80x24",
                                "--animate=off",
                            }, {
                                on_stdout = function(_, data, _)
                                    for _, d in ipairs(data) do
                                        vim.api.nvim_chan_send(term, d .. "\r\n")
                                    end
                                end,
                                stdout_buffered = true,
                            })
                        end
                    end,
                },

                winblend = 0,
            },

            pickers = {
                find_files = {
                    hidden = true,
                    find_command = vim.fn.executable("fd") == 1
                        and { "fd", "--type", "f", "--strip-cwd-prefix", "--exclude", ".git" }
                        or { "find", ".", "-type", "f", "-not", "-path", "*/.git/*" },
                    theme = "dropdown",
                    previewer = false,
                    layout_config = { width = 0.6, height = 0.6 },
                },

                live_grep = {
                    additional_args = function()
                        return vim.fn.executable("rg") == 1 and { "--hidden", "--glob", "!.git/*" } or {}
                    end,
                    theme = "ivy",
                },

                grep_string = {
                    additional_args = function()
                        return vim.fn.executable("rg") == 1 and { "--hidden", "--glob", "!.git/*" } or {}
                    end,
                    theme = "ivy",
                },

                buffers = {
                    sort_lastused = true,
                    sort_mru = true,
                    show_all_buffers = false,
                    theme = "dropdown",
                    previewer = false,
                    layout_config = { width = 0.6, height = 0.6 },
                    mappings = {
                        i = { ["<C-d>"] = actions.delete_buffer },
                        n = { ["<C-d>"] = actions.delete_buffer },
                    },
                },

                oldfiles = {
                    theme = "dropdown",
                    previewer = false,
                    layout_config = { width = 0.6, height = 0.6 },
                },

                help_tags = { theme = "ivy" },
                keymaps = { theme = "ivy" },
                commands = { theme = "ivy" },

                colorscheme = {
                    enable_preview = true,
                    theme = "dropdown",
                    layout_config = { width = 0.5, height = 0.7 },
                },

                diagnostics = {
                    theme = "ivy",
                    layout_config = { preview_width = 0.6 },
                },

                lsp_references = {
                    theme = "ivy",
                    layout_config = { preview_width = 0.6 },
                },

                lsp_definitions = {
                    theme = "ivy",
                    layout_config = { preview_width = 0.6 },
                },

                git_commits = { theme = "ivy" },
                git_bcommits = { theme = "ivy" },
            },

            extensions = {
                fzf = {
                    fuzzy = true,
                    override_generic_sorter = true,
                    override_file_sorter = true,
                    case_mode = "smart_case",
                },
                ["ui-select"] = {
                    require("telescope.themes").get_dropdown({
                        layout_config = { width = 0.6, height = 0.6 },
                    }),
                },
            },
        })

        -- Load extensions
        pcall(telescope.load_extension, "fzf")
        pcall(telescope.load_extension, "ui-select")

        -- Theme picker functionality
        local theme_file = vim.fn.stdpath("data") .. "/last_theme"

        local function ensure_colorscheme_loaded(name)
            local colorscheme_plugins = {
                catppuccin = "catppuccin",
                tokyonight = "tokyonight.nvim",
                gruvbox = "gruvbox.nvim",
                kanagawa = "kanagawa.nvim",
                rose_pine = "rose-pine",
            }

            for pattern, plugin in pairs(colorscheme_plugins) do
                if name:match(pattern) then
                    pcall(require("lazy").load, { plugins = { plugin } })
                    break
                end
            end
        end

        vim.api.nvim_create_user_command("ThemePicker", function()
            require("telescope.builtin").colorscheme({
                enable_preview = true,
                theme = "dropdown",
                layout_config = { width = 0.5, height = 0.7 },
                attach_mappings = function(prompt_bufnr, map)
                    local function apply_theme()
                        local entry = action_state.get_selected_entry()
                        if entry and entry.value then
                            local name = entry.value
                            ensure_colorscheme_loaded(name)

                            -- Save theme preference
                            vim.fn.writefile({ name }, theme_file)

                            vim.schedule(function()
                                pcall(vim.cmd.colorscheme, name)
                                vim.notify("Applied theme: " .. name, vim.log.levels.INFO)
                            end)
                        end
                        actions.close(prompt_bufnr)
                    end

                    map("i", "<CR>", apply_theme)
                    map("n", "<CR>", apply_theme)
                    return true
                end,
            })
        end, { desc = "Pick and apply colorscheme" })

        -- Auto-load saved theme
        vim.api.nvim_create_autocmd("VimEnter", {
            callback = function()
                if vim.fn.filereadable(theme_file) == 1 then
                    local theme = vim.fn.readfile(theme_file)[1]
                    if theme then
                        ensure_colorscheme_loaded(theme)
                        vim.schedule(function()
                            pcall(vim.cmd.colorscheme, theme)
                        end)
                    end
                end
            end,
        })
    end,
}
