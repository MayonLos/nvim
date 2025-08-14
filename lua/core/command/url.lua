local M, cfg =
	{}, {
		notify = true,
		url_patterns = { "^https?://", "^ftp://", "^file://" },
		search_engine = "https://www.google.com/search?q=%s",
	}

local function n(msg, l)
	if cfg.notify then
		(vim.notify or print)(msg, l or vim.log.levels.INFO)
	end
end
local function is_url(s)
	if not s or s == "" then
		return false
	end
	for _, p in ipairs(cfg.url_patterns) do
		if s:match(p) then
			return true
		end
	end
	return false
end
local function cursor_text()
	local line = vim.api.nvim_get_current_line()
	local col = vim.api.nvim_win_get_cursor(0)[2] + 1
	local s, e = col, col
	while s > 1 and not line:sub(s - 1, s - 1):match "[%s<>\"'`() ]" do
		s = s - 1
	end
	while e < #line and not line:sub(e + 1, e + 1):match "[%s<>\"'`() ]" do
		e = e + 1
	end
	return (line:sub(s, e):gsub("^%s+", ""):gsub("%s+$", ""))
end
local function encode(str)
	return (str:gsub("([^%w%-_%.~])", function(c)
		return string.format("%%%02X", string.byte(c))
	end))
end
local function open_external(t)
	if vim.ui and vim.ui.open then
		pcall(vim.ui.open, t)
		return
	end
	local cmd = (vim.fn.has "mac" == 1 and "open") or (vim.fn.has "win32" == 1 and "start") or "xdg-open"
	if vim.fn.jobstart({ cmd, t }, { detach = true }) <= 0 then
		n("Failed to start open command", vim.log.levels.ERROR)
	end
end

function M.setup(user)
	cfg = vim.tbl_deep_extend("force", cfg, user or {})
	vim.api.nvim_create_user_command("OpenURL", function(o)
		local t = (o.args ~= "" and o.args) or cursor_text()
		if is_url(t) then
			open_external(t)
			n("Opened: " .. t)
		else
			n("No valid URL: " .. (t or ""), vim.log.levels.WARN)
		end
	end, {
		nargs = "?",
		desc = "Open URL under cursor",
		complete = function()
			return { cursor_text() }
		end,
	})

	vim.api.nvim_create_user_command("CopyURL", function(o)
		local t = (o.args ~= "" and o.args) or cursor_text()
		if not is_url(t) then
			return n("No valid URL: " .. (t or ""), vim.log.levels.WARN)
		end
		if not pcall(vim.fn.setreg, "+", t) then
			vim.fn.setreg('"', t)
			n("Copied to unnamed register", vim.log.levels.WARN)
		else
			n "Copied to clipboard"
		end
	end, {
		nargs = "?",
		desc = "Copy URL under cursor",
		complete = function()
			return { cursor_text() }
		end,
	})

	vim.api.nvim_create_user_command("SearchWeb", function(o)
		local q = (o.args ~= "" and o.args) or cursor_text()
		if not q or q == "" then
			return n("No query", vim.log.levels.WARN)
		end
		open_external(cfg.search_engine:format(encode(q)))
		n("Searching: " .. q)
	end, {
		nargs = "?",
		desc = "Search web",
		complete = function()
			return { cursor_text() }
		end,
	})
end

return M
