local M = {}

-- Configuration options with defaults
local config = {
    higroup = "IncSearch",
    timeout = 200,
    priority = 150,
    on_macro = true,
    on_silent = true,
}

-- Setup function with optional configuration
function M.setup(opts)
    opts = opts or {}

    -- Merge user options with defaults
    config = vim.tbl_extend("force", config, opts)

    -- Create main augroup for all autocmds
    local augroup = vim.api.nvim_create_augroup("EnhancedEditor", { clear = true })

    -- Yank highlighting
    vim.api.nvim_create_autocmd("TextYankPost", {
        group = augroup,
        desc = "Highlight yanked text",
        callback = function()
            vim.highlight.on_yank({
                higroup = config.higroup,
                timeout = config.timeout,
                priority = config.priority,
                on_macro = config.on_macro,
                on_silent = config.on_silent,
            })
        end,
    })

    -- Jump to last cursor position when opening a file
    vim.api.nvim_create_autocmd("BufReadPost", {
        group = augroup,
        desc = "Jump to last cursor position",
        callback = function()
            local mark = vim.api.nvim_buf_get_mark(0, '"')
            local line_count = vim.api.nvim_buf_line_count(0)

            -- Check if mark is valid and within buffer bounds
            if mark[1] > 0 and mark[1] <= line_count then
                -- Use pcall to safely set cursor position
                pcall(vim.api.nvim_win_set_cursor, 0, mark)
            end
        end,
    })

    -- Disable automatic comment continuation
    vim.api.nvim_create_autocmd("FileType", {
        group = augroup,
        desc = "Disable automatic comment continuation",
        callback = function()
            vim.opt_local.formatoptions:remove({ "c", "r", "o" })
        end,
    })

    -- Auto-create directories when saving files
    vim.api.nvim_create_autocmd("BufWritePre", {
        group = augroup,
        desc = "Auto-create directories when saving",
        callback = function(event)
            local file = vim.uv.fs_realpath(event.match) or event.match
            local dir = vim.fn.fnamemodify(file, ":p:h")

            -- Only create directory if it doesn't exist
            if vim.fn.isdirectory(dir) == 0 then
                vim.fn.mkdir(dir, "p")
            end
        end,
    })

    -- Terminal buffer settings
    vim.api.nvim_create_autocmd("TermOpen", {
        group = augroup,
        desc = "Configure terminal buffer settings",
        callback = function()
            vim.opt_local.number = false
            vim.opt_local.relativenumber = false
            vim.opt_local.signcolumn = "no"
            vim.opt_local.wrap = true

            -- Enter insert mode automatically
            vim.cmd("startinsert")
        end,
    })

    -- Additional useful autocmd: Auto-save when focus is lost
    vim.api.nvim_create_autocmd({ "FocusLost", "BufLeave" }, {
        group = augroup,
        desc = "Auto-save on focus loss",
        callback = function()
            if vim.bo.modified and not vim.bo.readonly and vim.fn.expand("%") ~= "" then
                vim.cmd("silent! write")
            end
        end,
    })
end

return M
