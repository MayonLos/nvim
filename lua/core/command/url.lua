local M = {}

local cfg = {
	notify = true,
	url_patterns = { "^https?://", "^ftp://", "^file://" },
	search_engine = "https://www.google.com/search?q=%s",
}

local function notify(msg, level)
	if cfg.notify then
		vim.notify(msg, level or vim.log.levels.INFO)
	end
end

local function is_url(str)
	if not str or str == "" then
		return false
	end
	for _, pattern in ipairs(cfg.url_patterns) do
		if str:match(pattern) then
			return true
		end
	end
	return false
end

local function get_cursor_text()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1
	local start_col = col
	local end_col = col

	while start_col > 1 and not line:sub(start_col - 1, start_col - 1):match("[%s<>\"'`() ]") do
		start_col = start_col - 1
	end

	while end_col < #line and not line:sub(end_col + 1, end_col + 1):match("[%s<>\"'`() ]") do
		end_col = end_col + 1
	end

	return line:sub(start_col, end_col):match("^%s*(.-)%s*$")
end

local function url_encode(str)
	return str:gsub("([^%w%-_%.~])", function(c)
		return ("%%%02X"):format(c:byte())
	end)
end

local function open_external(url)
	local ok, err = pcall(vim.ui.open, url)
	if ok then
		return
	end

	local opener
	if vim.fn.has("mac") == 1 then
		opener = "open"
	elseif vim.fn.has("win32") == 1 then
		opener = "start"
	else
		opener = "xdg-open"
	end

	if vim.fn.executable(opener) == 0 then
		notify(("Opener '%s' not found"):format(opener), vim.log.levels.ERROR)
		return
	end

	local job_id = vim.fn.jobstart({ opener, url }, { detach = true })
	if job_id <= 0 then
		notify("Failed to open URL", vim.log.levels.ERROR)
	end
end

function M.setup(user_cfg)
	cfg = vim.tbl_deep_extend("force", cfg, user_cfg or {})

	vim.api.nvim_create_user_command("OpenURL", function(opts)
		local target = opts.args ~= "" and opts.args or get_cursor_text()
		if is_url(target) then
			open_external(target)
			notify(("Opened: %s"):format(target))
		else
			notify(("No valid URL: %s"):format(target or ""), vim.log.levels.WARN)
		end
	end, {
		nargs = "?",
		desc = "Open URL under cursor or provided",
		complete = function()
			return { get_cursor_text() }
		end,
	})

	vim.api.nvim_create_user_command("CopyURL", function(opts)
		local target = opts.args ~= "" and opts.args or get_cursor_text()
		if not is_url(target) then
			notify(("No valid URL: %s"):format(target or ""), vim.log.levels.WARN)
			return
		end
		local ok, err = pcall(vim.fn.setreg, "+", target)
		if not ok then
			vim.fn.setreg('"', target)
			notify(
				"Copied to unnamed register (clipboard failed: " .. (err or "unknown") .. ")",
				vim.log.levels.WARN
			)
		else
			notify("Copied to clipboard")
		end
	end, {
		nargs = "?",
		desc = "Copy URL under cursor or provided",
		complete = function()
			return { get_cursor_text() }
		end,
	})

	vim.api.nvim_create_user_command("SearchWeb", function(opts)
		local query = opts.args ~= "" and opts.args or get_cursor_text()
		if not query or query == "" then
			notify("No search query provided", vim.log.levels.WARN)
			return
		end
		local url = cfg.search_engine:format(url_encode(query))
		open_external(url)
		notify(("Searching: %s"):format(query))
	end, {
		nargs = "?",
		desc = "Search web with query under cursor or provided",
		complete = function()
			return { get_cursor_text() }
		end,
	})
end

return M
