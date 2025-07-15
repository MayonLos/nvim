local M = {}

local function find_source_files(extensions)
	local files = {}
	for _, ext in ipairs(extensions) do
		local found = vim.fn.glob("*." .. ext, false, true)
		for _, f in ipairs(found) do
			table.insert(files, f)
		end
	end
	return files
end

local function write_cmakelists(project_name, sources)
	local lines = {
		"cmake_minimum_required(VERSION 3.10)",
		"project(" .. project_name .. ")",
		"set(CMAKE_CXX_STANDARD 23)",
		"",
		"add_executable(" .. project_name,
	}

	for _, src in ipairs(sources) do
		table.insert(lines, "  " .. src)
	end

	table.insert(lines, ")")

	local path = vim.fn.getcwd() .. "/CMakeLists.txt"
	vim.fn.writefile(lines, path)
	vim.notify("Generated CMakeLists.txt at " .. path, vim.log.levels.INFO)
end

function M.setup()
	vim.api.nvim_create_user_command("GenCMake", function(opts)
		local name = opts.args ~= "" and opts.args or vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
		local files = find_source_files({ "cpp", "c", "cc" })

		if vim.tbl_isempty(files) then
			vim.notify("No source files found in current directory.", vim.log.levels.WARN)
			return
		end

		write_cmakelists(name, files)
	end, {
		nargs = "?",
		desc = "Generate a basic CMakeLists.txt (optional project name)",
	})
end

return M
