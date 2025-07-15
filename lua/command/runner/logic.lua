local utils = require("utils.filepath")
local runners = require("command.runner.runners").runners
local ui = require("command.runner.ui")

local M = {}

local function shellescape_list(list)
	local esc = {}
	for _, v in ipairs(list) do
		esc[#esc + 1] = vim.fn.shellescape(v)
	end
	return esc
end

function M.compile_and_run()
	if vim.bo.modified then
		vim.cmd.write()
	end

	local file = utils.get_file_info()
	local runner = runners[file.ext]

	if not runner then
		vim.notify(("Unsupported file type: %s"):format(file.ext), vim.log.levels.ERROR)
		return
	end

	local cmd_parts = {
		"cd",
		vim.fn.shellescape(file.dir),
		"&&",
		runner.cmd,
		unpack(shellescape_list(runner.args(file))),
	}

	if runner.run then
		local run_cmd = type(runner.run) == "function" and runner.run(file) or runner.run
		table.insert(cmd_parts, "&&")
		table.insert(cmd_parts, run_cmd)
	end

	local final_cmd = table.concat(cmd_parts, " ")
	ui.open_floating_terminal(final_cmd)
end

return M
