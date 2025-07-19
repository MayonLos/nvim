local M = {}

function M.setup()
    -- Open URL under cursor in browser
    vim.api.nvim_create_user_command("OpenURL", function()
        local url = vim.fn.expand("<cWORD>")
        if url:match("^https?://") then
            vim.fn.jobstart({ "xdg-open", url }, { detach = true })
        else
            vim.notify("Invalid URL: " .. url, vim.log.levels.WARN)
        end
    end, { desc = "Open URL under cursor in browser" })

    -- Copy URL under cursor to clipboard
    vim.api.nvim_create_user_command("CopyURL", function()
        local url = vim.fn.expand("<cWORD>")
        if url:match("^https?://") then
            vim.fn.setreg("+", url)
            vim.notify("Copied to clipboard: " .. url, vim.log.levels.INFO)
        else
            vim.notify("Invalid URL: " .. url, vim.log.levels.WARN)
        end
    end, { desc = "Copy URL under cursor to clipboard" })

    -- Search word under cursor via Google
    vim.api.nvim_create_user_command("SearchURL", function()
        local word = vim.fn.expand("<cWORD>")
        local url = "https://www.google.com/search?q=" .. vim.fn.escape(word, " ")
        vim.fn.jobstart({ "xdg-open", url }, { detach = true })
    end, { desc = "Search word under cursor via Google" })
end

return M
