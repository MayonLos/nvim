local Format = require("noice.text.format")
local Message = require("noice.message")
local Manager = require("noice.message.manager")
local Router = require("noice.message.router")

local ThrottleTime = 200
local M = {}
M.handles = {}

function M.init()
    local ok, _ = pcall(require, "noice")
    if not ok then
        vim.notify("noice.nvim is required for companion-notification", vim.log.levels.WARN)
        return
    end

    local group = vim.api.nvim_create_augroup("NoiceCompanionRequests", { clear = true })

    vim.api.nvim_create_autocmd("User", {
        pattern = "CodeCompanionRequestStarted",
        group = group,
        callback = function(request)
            if not request.data or not request.data.id then
                vim.notify("Invalid request data", vim.log.levels.ERROR)
                return
            end

            local handle = M.create_progress_message(request)
            M.store_progress_handle(request.data.id, handle)
            M.update(handle)
        end,
    })

    vim.api.nvim_create_autocmd("User", {
        pattern = "CodeCompanionRequestFinished",
        group = group,
        callback = function(request)
            if not request.data or not request.data.id then
                return
            end

            local message = M.pop_progress_message(request.data.id)
            if message then
                message.opts.progress.message = M.report_exit_status(request)
                M.finish_progress_message(message)
            end
        end,
    })
end

function M.store_progress_handle(id, handle)
    M.handles[id] = handle
end

function M.pop_progress_message(id)
    local handle = M.handles[id]
    M.handles[id] = nil
    return handle
end

function M.create_progress_message(request)
    local msg = Message("lsp", "progress")
    local id = request.data.id or "unknown"

    msg.opts.progress = {
        client_id = "codecompanion_" .. id,
        client = M.llm_role_title(request.data.adapter or {}),
        id = id,
        message = "󰔟 Awaiting Response...",
        percentage = nil,
    }
    return msg
end

function M.update(message)
    if not message or not message.opts or not message.opts.progress then
        return
    end

    local id = message.opts.progress.id
    if M.handles[id] then
        pcall(function()
            Manager.add(Format.format(message, "lsp_progress"))
        end)

        vim.defer_fn(function()
            M.update(message)
        end, ThrottleTime)
    end
end

function M.finish_progress_message(message)
    if not message then
        return
    end

    pcall(function()
        Manager.add(Format.format(message, "lsp_progress"))
        Router.update()

        vim.defer_fn(function()
            Manager.remove(message)
        end, 2000)
    end)
end

function M.llm_role_title(adapter)
    local parts = {}

    if adapter.formatted_name then
        table.insert(parts, adapter.formatted_name)
    else
        table.insert(parts, "CodeCompanion")
    end

    if adapter.model and adapter.model ~= "" then
        table.insert(parts, "(" .. adapter.model .. ")")
    end

    return table.concat(parts, " ")
end

function M.report_exit_status(request)
    if not request.data or not request.data.status then
        return "󰅙 Unknown Status"
    end

    if request.data.status == "success" then
        return "󰄬 Completed"
    elseif request.data.status == "error" then
        return "󰅚 Error"
    else
        return "󰜺 Cancelled"
    end
end

return M
