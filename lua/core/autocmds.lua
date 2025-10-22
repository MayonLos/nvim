---@class EnhancedEditor
local M = {}

local config = {
	yank = { enabled = true, timeout = 200, higroup = "IncSearch" },
	cursor_restore = { enabled = true, exclude_ft = { "gitcommit", "help", "qf" } },
	auto_mkdir = { enabled = true, verbose = false },
	terminal = { enabled = true, auto_insert = true, disable_ui = true },
	comment = { disable_continuation = true, preserve_ft = { "markdown" } },
}

local state = { augroup = nil, timers = {} }

local function is_excluded(list, item)
	for _, v in ipairs(list or {}) do
		if v == item then
			return true
		end
	end
	return false
end

local function notify(msg, level)
	vim.schedule(function()
		vim.notify(msg, level or vim.log.levels.INFO, { title = "EnhancedEditor" })
	end)
end

local function debounce(fn, delay, key)
	return function(...)
		local args = { ... }
		if state.timers[key] then
			state.timers[key]:stop()
		end
		state.timers[key] = vim.defer_fn(function()
			fn(unpack(args))
			state.timers[key] = nil
		end, delay)
	end
end

local features = {
	yank = function()
		if not config.yank.enabled then
			return
		end

		vim.api.nvim_create_autocmd("TextYankPost", {
			group = state.augroup,
			desc = "Highlight yanked text",
			callback = function()
				pcall(vim.highlight.on_yank, {
					higroup = config.yank.higroup,
					timeout = config.yank.timeout,
				})
			end,
		})
	end,

	cursor_restore = function()
		if not config.cursor_restore.enabled then
			return
		end

		vim.api.nvim_create_autocmd("BufReadPost", {
			group = state.augroup,
			desc = "Restore cursor position",
			callback = function()
				local ft = vim.bo.filetype
				if is_excluded(config.cursor_restore.exclude_ft, ft) or vim.bo.buftype ~= "" then
					return
				end

				local mark = vim.api.nvim_buf_get_mark(0, '"')
				local lines = vim.api.nvim_buf_line_count(0)

				if mark[1] > 0 and mark[1] <= lines then
					vim.schedule(function()
						if pcall(vim.api.nvim_win_set_cursor, 0, mark) then
							vim.cmd.normal("zz")
						end
					end)
				end
			end,
		})
	end,

	auto_mkdir = function()
		if not config.auto_mkdir.enabled then
			return
		end

		vim.api.nvim_create_autocmd("BufWritePre", {
			group = state.augroup,
			desc = "Auto create directory",
			callback = function(ev)
				local file = ev.match
				if not file or file:match("^%w+://") then
					return
				end

				local dir = vim.fn.fnamemodify(file, ":p:h")
				if vim.fn.isdirectory(dir) == 0 then
					local ok, err = pcall(vim.fn.mkdir, dir, "p")
					if not ok then
						notify(
							"Failed to create directory: " .. tostring(err),
							vim.log.levels.ERROR
						)
					elseif config.auto_mkdir.verbose then
						notify("Created: " .. dir)
					end
				end
			end,
		})
	end,

	terminal = function()
		if not config.terminal.enabled then
			return
		end

		vim.api.nvim_create_autocmd("TermOpen", {
			group = state.augroup,
			desc = "Terminal enhancements",
			callback = function()
				if config.terminal.disable_ui then
					vim.opt_local.number = false
					vim.opt_local.relativenumber = false
					vim.opt_local.signcolumn = "no"
				end

				if config.terminal.auto_insert then
					vim.schedule(function()
						vim.cmd.startinsert()
					end)
				end
			end,
		})
	end,

	comment = function()
		if not config.comment.disable_continuation then
			return
		end

		vim.api.nvim_create_autocmd("FileType", {
			group = state.augroup,
			desc = "Disable comment continuation",
			callback = function()
				local ft = vim.bo.filetype
				if is_excluded(config.comment.preserve_ft, ft) then
					return
				end
				vim.opt_local.formatoptions:remove({ "c", "r", "o" })
			end,
		})
	end,
}

function M.setup(opts)
	config = vim.tbl_deep_extend("force", config, opts or {})

	if state.augroup then
		vim.api.nvim_del_augroup_by_id(state.augroup)
	end

	state.augroup = vim.api.nvim_create_augroup("EnhancedEditor", { clear = true })

	for name, setup_fn in pairs(features) do
		local ok, err = pcall(setup_fn)
		if not ok then
			notify(string.format("Failed to setup %s: %s", name, err), vim.log.levels.WARN)
		end
	end

end

function M.toggle_yank()
	config.yank.enabled = not config.yank.enabled
	notify("Yank highlight " .. (config.yank.enabled and "enabled" or "disabled"))
end

function M.get_config()
	return vim.deepcopy(config)
end

function M.status()
	local enabled = {}
	for feature, conf in pairs(config) do
		if type(conf) == "table" and conf.enabled ~= nil then
			enabled[feature] = conf.enabled
		elseif feature == "comment" then
			enabled[feature] = conf.disable_continuation
		else
			enabled[feature] = true
		end
	end

	return {
		features = enabled,
		augroup = state.augroup,
	}
end

function M.reload()
	M.setup(config)
end

return M
