local M = {}

-- Configuration with better defaults and more options
local default_config = {
	-- Yank highlighting settings
	yank = {
		enabled = true,
		higroup = "IncSearch",
		timeout = 200,
		priority = 150,
		on_macro = true,
		on_silent = true,
	},

	-- Cursor position restoration
	cursor_restore = {
		enabled = true,
		exclude_filetypes = { "gitcommit", "gitrebase" },
	},

	-- Comment continuation settings
	comment_continuation = {
		disable = true,
		preserve_filetypes = {}, -- Filetypes where comment continuation should remain enabled
	},

	-- Auto-directory creation
	auto_mkdir = {
		enabled = true,
		verbose = false, -- Show message when directories are created
	},

	-- Terminal settings
	terminal = {
		enabled = true,
		auto_insert = true,
		disable_numbers = true,
		disable_signcolumn = true,
		enable_wrap = true,
	},

	-- Auto-save settings
	auto_save = {
		enabled = true,
		events = { "FocusLost", "BufLeave" },
		exclude_filetypes = { "oil" }, -- Exclude certain filetypes
		show_message = false,
	},
}

local config = {}

-- Utility functions
local function is_excluded_filetype(filetypes, current_ft)
	for _, ft in ipairs(filetypes) do
		if ft == current_ft then
			return true
		end
	end
	return false
end

local function safe_write()
	local ok, err = pcall(vim.cmd, "silent! write")
	if not ok and config.auto_save.show_message then
		vim.notify("Auto-save failed: " .. (err or "unknown error"), vim.log.levels.WARN)
	elseif ok and config.auto_save.show_message then
		vim.notify("File auto-saved", vim.log.levels.INFO)
	end
end

-- Setup autocmds
local function setup_yank_highlight(augroup)
	if not config.yank.enabled then
		return
	end

	vim.api.nvim_create_autocmd("TextYankPost", {
		group = augroup,
		desc = "Highlight yanked text with configurable options",
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

local function setup_cursor_restore(augroup)
	if not config.cursor_restore.enabled then
		return
	end

	vim.api.nvim_create_autocmd("BufReadPost", {
		group = augroup,
		desc = "Restore cursor position to last known location",
		callback = function()
			-- Skip for excluded filetypes
			if is_excluded_filetype(config.cursor_restore.exclude_filetypes, vim.bo.filetype) then
				return
			end

			local mark = vim.api.nvim_buf_get_mark(0, '"')
			local line_count = vim.api.nvim_buf_line_count(0)

			-- Validate mark position
			if mark[1] > 0 and mark[1] <= line_count then
				local ok = pcall(vim.api.nvim_win_set_cursor, 0, mark)
				if ok then
					-- Center the line in the window
					vim.cmd "normal! zz"
				end
			end
		end,
	})
end

local function setup_comment_continuation(augroup)
	if not config.comment_continuation.disable then
		return
	end

	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		desc = "Configure comment continuation behavior",
		callback = function()
			-- Skip if filetype should preserve comment continuation
			if is_excluded_filetype(config.comment_continuation.preserve_filetypes, vim.bo.filetype) then
				return
			end

			-- Remove comment continuation options
			vim.opt_local.formatoptions:remove { "c", "r", "o" }
		end,
	})
end

local function setup_auto_mkdir(augroup)
	if not config.auto_mkdir.enabled then
		return
	end

	vim.api.nvim_create_autocmd("BufWritePre", {
		group = augroup,
		desc = "Create parent directories automatically when saving",
		callback = function(event)
			local file = vim.uv.fs_realpath(event.match) or event.match
			local dir = vim.fn.fnamemodify(file, ":p:h")

			-- Check if directory creation is needed
			if vim.fn.isdirectory(dir) == 0 then
				local ok, err = pcall(vim.fn.mkdir, dir, "p")
				if not ok then
					vim.notify("Failed to create directory: " .. (err or "unknown error"), vim.log.levels.ERROR)
				elseif config.auto_mkdir.verbose then
					vim.notify("Created directory: " .. dir, vim.log.levels.INFO)
				end
			end
		end,
	})
end

local function setup_terminal_config(augroup)
	if not config.terminal.enabled then
		return
	end

	vim.api.nvim_create_autocmd("TermOpen", {
		group = augroup,
		desc = "Configure terminal buffer appearance and behavior",
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

			-- Auto-enter insert mode
			if config.terminal.auto_insert then
				vim.schedule(function()
					if vim.api.nvim_get_current_buf() == vim.fn.bufnr "%" then
						vim.cmd "startinsert"
					end
				end)
			end
		end,
	})
end

local function setup_auto_save(augroup)
	if not config.auto_save.enabled then
		return
	end

	vim.api.nvim_create_autocmd(config.auto_save.events, {
		group = augroup,
		desc = "Auto-save modified buffers",
		callback = function()
			-- Check if buffer should be saved
			local should_save = vim.bo.modified
				and not vim.bo.readonly
				and vim.fn.expand "%" ~= ""
				and not is_excluded_filetype(config.auto_save.exclude_filetypes, vim.bo.filetype)

			if should_save then
				safe_write()
			end
		end,
	})
end

-- Main setup function
function M.setup(user_config)
	-- Merge user configuration with defaults
	config = vim.tbl_deep_extend("force", default_config, user_config or {})

	-- Create augroup with clear option
	local augroup = vim.api.nvim_create_augroup("EnhancedEditor", { clear = true })

	-- Setup all features
	setup_yank_highlight(augroup)
	setup_cursor_restore(augroup)
	setup_comment_continuation(augroup)
	setup_auto_mkdir(augroup)
	setup_terminal_config(augroup)
	setup_auto_save(augroup)
end

-- Utility functions for runtime configuration changes
function M.toggle_auto_save()
	config.auto_save.enabled = not config.auto_save.enabled
	local status = config.auto_save.enabled and "enabled" or "disabled"
	vim.notify("Auto-save " .. status, vim.log.levels.INFO)
end

function M.toggle_yank_highlight()
	config.yank.enabled = not config.yank.enabled
	local status = config.yank.enabled and "enabled" or "disabled"
	vim.notify("Yank highlighting " .. status, vim.log.levels.INFO)
end

-- Get current configuration
function M.get_config()
	return vim.deepcopy(config)
end

return M
