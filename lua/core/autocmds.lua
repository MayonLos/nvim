local M, config = {}, {}

local defaults = {
	yank = { enabled = true, higroup = "IncSearch", timeout = 200, priority = 150, on_macro = true, on_silent = true },
	cursor_restore = { enabled = true, exclude_filetypes = { "gitcommit", "gitrebase" } },
	comment_continuation = { disable = true, preserve_filetypes = { "gitcommit", "markdown" } },
	auto_mkdir = { enabled = true, verbose = false },
	terminal = {
		enabled = true,
		auto_insert = true,
		disable_numbers = true,
		disable_signcolumn = true,
		enable_wrap = true,
	},
}

local function is_excluded(ft_list, ft)
	for _, v in ipairs(ft_list or {}) do
		if v == ft then
			return true
		end
	end
	return false
end

-- ---------- features ----------
local function setup_yank(au)
	if not config.yank.enabled then
		return
	end
	vim.api.nvim_create_autocmd("TextYankPost", {
		group = au,
		desc = "Highlight yanked text",
		callback = function()
			vim.highlight.on_yank {
				higroup = config.yank.higroup,
				timeout = config.yank.timeout,
				priority = config.yank.priority,
				on_macro = config.yank.on_macro,
				on_silent = config.yank.on_silent,
			}
		end,
	})
end

local function setup_cursor_restore(au)
	if not config.cursor_restore.enabled then
		return
	end
	vim.api.nvim_create_autocmd("BufReadPost", {
		group = au,
		desc = "Restore last cursor position",
		callback = function()
			if is_excluded(config.cursor_restore.exclude_filetypes, vim.bo.filetype) then
				return
			end
			local mark = vim.api.nvim_buf_get_mark(0, '"')
			local lines = vim.api.nvim_buf_line_count(0)
			if mark[1] > 0 and mark[1] <= lines then
				if pcall(vim.api.nvim_win_set_cursor, 0, mark) then
					vim.cmd.normal "zz"
				end
			end
		end,
	})
end

local function setup_comment(au)
	if not config.comment_continuation.disable then
		return
	end
	vim.api.nvim_create_autocmd("FileType", {
		group = au,
		desc = "Disable comment continuation",
		callback = function()
			if is_excluded(config.comment_continuation.preserve_filetypes, vim.bo.filetype) then
				return
			end
			vim.opt_local.formatoptions:remove { "c", "r", "o" }
		end,
	})
end

local function setup_mkdir(au)
	if not config.auto_mkdir.enabled then
		return
	end
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = au,
		desc = "Create parent directory on save",
		callback = function(ev)
			local name = ev.match or ""
			if name:match "^%w+://" then
				return
			end
			local file = (vim.uv.fs_realpath(name) or name)
			local dir = vim.fn.fnamemodify(file, ":p:h")
			if dir ~= "" and vim.fn.isdirectory(dir) == 0 then
				local ok, err = pcall(vim.fn.mkdir, dir, "p")
				if not ok then
					vim.notify("mkdir failed: " .. (err or "unknown"), vim.log.levels.ERROR)
				elseif config.auto_mkdir.verbose then
					vim.notify("Created: " .. dir)
				end
			end
		end,
	})
end

local function setup_terminal(au)
	if not config.terminal.enabled then
		return
	end
	vim.api.nvim_create_autocmd("TermOpen", {
		group = au,
		desc = "Terminal UI tweaks",
		callback = function()
			if config.terminal.disable_numbers then
				vim.opt_local.number = false
				vim.opt_local.relativenumber = false
			end
			if config.terminal.disable_signcolumn then
				vim.opt_local.signcolumn = "no"
			end
			if config.terminal.enable_wrap then
				vim.opt_local.wrap = true
			end
			if config.terminal.auto_insert then
				vim.cmd "startinsert"
			end
		end,
	})
end

-- ---------- public ----------
function M.setup(user)
	config = vim.tbl_deep_extend("force", defaults, user or {})
	local au = vim.api.nvim_create_augroup("EnhancedEditor", { clear = true })
	setup_yank(au)
	setup_cursor_restore(au)
	setup_comment(au)
	setup_mkdir(au)
	setup_terminal(au)
end

function M.toggle_yank_highlight()
	config.yank.enabled = not config.yank.enabled
	vim.notify(("Yank highlight %s"):format(config.yank.enabled and "enabled" or "disabled"))
end

function M.get_config()
	return vim.deepcopy(config)
end

return M
