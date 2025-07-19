local M = {}

-- Configuration with defaults
local config = {
    open_cmd = nil, -- Auto-detect based on OS
    notify = true,
    url_patterns = {
        "^https?://",
        "^ftp://",
        "^file://",
    },
}

-- Detect system open command
local function get_open_cmd()
    if config.open_cmd then
        return config.open_cmd
    end

    if vim.fn.has("mac") == 1 then
        return "open"
    elseif vim.fn.has("unix") == 1 then
        return "xdg-open"
    elseif vim.fn.has("win32") == 1 then
        return "start"
    else
        return "xdg-open" -- fallback
    end
end

-- Safe notification function
local function notify(msg, level)
    if not config.notify then
        return
    end

    if vim.notify then
        vim.notify(msg, level or vim.log.levels.INFO)
    else
        print(msg)
    end
end

-- Validate URL against configured patterns
local function is_valid_url(text)
    if not text or text == "" then
        return false
    end

    for _, pattern in ipairs(config.url_patterns) do
        if text:match(pattern) then
            return true
        end
    end
    return false
end

-- Get text under cursor with better word boundary detection
local function get_cursor_text()
    local line = vim.api.nvim_get_current_line()
    local col = vim.api.nvim_win_get_cursor(0)[2]

    -- Find URL boundaries more intelligently
    local start_col = col
    local end_col = col

    -- Expand backwards to find start
    while start_col > 0 do
        local char = line:sub(start_col, start_col)
        if char:match("[%s<>\"'`]") then
            start_col = start_col + 1
            break
        end
        start_col = start_col - 1
    end

    -- Expand forwards to find end
    while end_col <= #line do
        local char = line:sub(end_col + 1, end_col + 1)
        if char:match("[%s<>\"'`]") or char == "" then
            break
        end
        end_col = end_col + 1
    end

    local text = line:sub(start_col, end_col)
    return text:gsub("^%s+", ""):gsub("%s+$", "") -- trim whitespace
end

-- Open URL in browser
local function open_url(url)
    local cmd = get_open_cmd()
    local job_id = vim.fn.jobstart({ cmd, url }, {
        detach = true,
        on_exit = function(_, exit_code)
            if exit_code ~= 0 then
                notify("Failed to open URL: " .. url, vim.log.levels.ERROR)
            end
        end,
    })

    if job_id <= 0 then
        notify("Failed to start browser command", vim.log.levels.ERROR)
    else
        notify("Opened: " .. url)
    end
end

-- Copy text to clipboard with fallback
local function copy_to_clipboard(text)
    local success = pcall(vim.fn.setreg, "+", text)
    if not success then
        -- Fallback to unnamed register
        vim.fn.setreg('"', text)
        notify("Copied to unnamed register: " .. text, vim.log.levels.WARN)
    else
        notify("Copied to clipboard: " .. text)
    end
end

-- URL encode function for search queries
local function url_encode(str)
    return str:gsub("([^%w%-_%.~])", function(c)
        return string.format("%%%02X", string.byte(c))
    end)
end

-- Setup function with optional user config
function M.setup(user_config)
    config = vim.tbl_deep_extend("force", config, user_config or {})

    -- Open URL under cursor
    vim.api.nvim_create_user_command("OpenURL", function(opts)
        local text = opts.args ~= "" and opts.args or get_cursor_text()

        if is_valid_url(text) then
            open_url(text)
        else
            notify("No valid URL found: " .. text, vim.log.levels.WARN)
        end
    end, {
        desc = "Open URL under cursor or provided URL in browser",
        nargs = "?",
        complete = function()
            return { get_cursor_text() }
        end,
    })

    -- Copy URL under cursor
    vim.api.nvim_create_user_command("CopyURL", function(opts)
        local text = opts.args ~= "" and opts.args or get_cursor_text()

        if is_valid_url(text) then
            copy_to_clipboard(text)
        else
            notify("No valid URL found: " .. text, vim.log.levels.WARN)
        end
    end, {
        desc = "Copy URL under cursor or provided URL to clipboard",
        nargs = "?",
        complete = function()
            return { get_cursor_text() }
        end,
    })

    -- Search text via search engine
    vim.api.nvim_create_user_command("SearchWeb", function(opts)
        local query = opts.args ~= "" and opts.args or get_cursor_text()

        if query and query ~= "" then
            local search_url = "https://www.google.com/search?q=" .. url_encode(query)
            open_url(search_url)
        else
            notify("No search query provided", vim.log.levels.WARN)
        end
    end, {
        desc = "Search text under cursor or provided text via Google",
        nargs = "?",
        complete = function()
            return { get_cursor_text() }
        end,
    })
end

-- Expose utility functions
M.is_valid_url = is_valid_url
M.get_cursor_text = get_cursor_text
M.open_url = open_url
M.copy_to_clipboard = copy_to_clipboard

return M
