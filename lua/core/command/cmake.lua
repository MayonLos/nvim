---@class CMakeManager
local M = {}

-- ========================
-- Config (Linux-only)
-- ========================
M.config = {
	build_dir = "build",
	build_type = "Debug", -- Debug / Release / RelWithDebInfo / MinSizeRel
	cxx_standard = 17,
	generator = "auto", -- "auto" | "Ninja" | "Unix Makefiles"
	use_ccache = true, -- Automatically enable if ccache is available
	extra_cmake_args = {}, -- Extra -D flags, e.g., { "-DCMAKE_TOOLCHAIN_FILE=..." }
	jobs = nil, -- nil: auto-detect with nproc
	cmake_program = "cmake", -- Can be changed to "cmake3"
	shell = "bash", -- Use bash -lc to avoid zsh compatibility issues
	env = {}, -- Temporary environment variables: { CC="clang", CXX="clang++" }
}

-- ========================
-- Utilities
-- ========================
local function file_exists(path)
	return vim.fn.filereadable(path) == 1
end

local function dir_exists(path)
	return vim.fn.isdirectory(path) == 1
end

local function shesc(s)
	return vim.fn.shellescape(s or "")
end

local function have_exe(bin)
	return vim.fn.executable(bin) == 1
end

local function get_project_name()
	local name = vim.fn.fnamemodify(vim.fn.getcwd(), ":t")
	name = name:gsub("[^%w_%-]", "_")
	return name ~= "" and name or "Project"
end

local function detect_generator()
	if M.config.generator ~= "auto" then
		return M.config.generator
	end
	return have_exe("ninja") and "Ninja" or "Unix Makefiles"
end

local function detect_jobs()
	if M.config.jobs then
		return M.config.jobs
	end
	local handle = io.popen("nproc 2>/dev/null || echo 4")
	local out = handle:read("*a") or "4"
	handle:close()
	local j = tonumber(out) or 4
	M.config.jobs = j
	return j
end

local function open_terminal(cmd_string, title, opts)
	-- Inject env into command prefix instead of termopen opts.env (for older nvim compatibility)
	local env_exports = {}
	local env_tbl = (opts and opts.env) or M.config.env
	for k, v in pairs(env_tbl) do
		table.insert(env_exports, ("export %s=%s"):format(k, shesc(tostring(v))))
	end
	local prefix = #env_exports > 0 and (table.concat(env_exports, "; ") .. "; ") or ""
	local full_cmd = prefix .. cmd_string

	local buf = vim.api.nvim_create_buf(false, true)
	vim.bo[buf].bufhidden = "wipe"

	local width = math.floor(vim.o.columns * 0.85)
	local height = math.floor(vim.o.lines * 0.85)
	vim.api.nvim_open_win(buf, true, {
		relative = "editor",
		style = "minimal",
		border = "rounded",
		width = width,
		height = height,
		col = math.floor((vim.o.columns - width) / 2),
		row = math.floor((vim.o.lines - height) / 2),
		title = title or "Terminal",
		title_pos = "center",
	})

	local shell = M.config.shell or os.getenv("SHELL") or "bash"
	local args = { shell, "-lc", full_cmd }
	-- Pass only cwd, not env, to avoid E475
	vim.fn.termopen(args, {
		cwd = (opts and opts.cwd) or vim.fn.getcwd(),
	})

	vim.keymap.set("t", "<Esc>", [[<C-\><C-n>:close<CR>]], { buffer = buf, silent = true })
	vim.keymap.set("n", "q", ":close<CR>", { buffer = buf, silent = true })
	vim.cmd("startinsert")
end

local function collect_sources()
	local sources = {}
	local patterns = { "**/*.c", "**/*.cc", "**/*.cpp", "**/*.cxx" }
	local exclude_patterns = {
		"/." .. M.config.build_dir .. "/",
		"/build/",
		"/cmake%-build",
		"/test/",
		"/tests/",
		"/example/",
		"/examples/",
		"/third_party/",
		"/third%-party/",
		"/.git/",
	}

	for _, root in ipairs({ ".", "src" }) do
		if root == "." or dir_exists(root) then
			for _, pat in ipairs(patterns) do
				local files = vim.fn.globpath(root, pat, false, true)
				for _, file in ipairs(files) do
					local skip = false
					for _, ex in ipairs(exclude_patterns) do
						if file:find(ex) then
							skip = true
							break
						end
					end
					if not skip then
						table.insert(sources, vim.fn.fnamemodify(file, ":."))
					end
				end
			end
		end
	end

	table.sort(sources)
	return sources
end

local function link_compile_commands(build_dir)
	local src = build_dir .. "/compile_commands.json"
	if file_exists(src) then
		os.execute(
			("ln -sfn %s %s 2>/dev/null || true"):format(shesc(src), shesc("compile_commands.json"))
		)
	end
end

-- ========================
-- Generate CMakeLists
-- ========================
function M.generate_cmake()
	if file_exists("CMakeLists.txt") then
		vim.notify("CMakeLists.txt already exists", vim.log.levels.WARN)
		return
	end

	local project = get_project_name()
	local sources = collect_sources()
	if #sources == 0 then
		vim.notify("No source files found; wrote a template CMakeLists.txt", vim.log.levels.WARN)
	end

	local lines = {
		"cmake_minimum_required(VERSION 3.10)",
		"project(" .. project .. " LANGUAGES C CXX)",
		"set(CMAKE_CXX_STANDARD " .. tostring(M.config.cxx_standard) .. ")",
		"set(CMAKE_CXX_STANDARD_REQUIRED ON)",
		"set(CMAKE_EXPORT_COMPILE_COMMANDS ON)",
		"",
		'if(CMAKE_CXX_COMPILER_ID MATCHES "GNU|Clang")',
		"  add_compile_options(-Wall -Wextra -Wpedantic)",
		'  if(CMAKE_BUILD_TYPE STREQUAL "Debug")',
		"    add_compile_options(-O0 -g -fno-omit-frame-pointer)",
		"  else()",
		"    add_compile_options(-O3)",
		"  endif()",
		"endif()",
		"",
	}

	if dir_exists("include") then
		table.insert(lines, "include_directories(include)")
	end

	if #sources > 0 then
		table.insert(lines, "add_executable(${PROJECT_NAME}")
		for _, s in ipairs(sources) do
			table.insert(lines, "  " .. s)
		end
		table.insert(lines, ")")
	else
		table.insert(lines, "# add_executable(${PROJECT_NAME} src/main.cpp)")
	end

	local ok, err = pcall(vim.fn.writefile, lines, "CMakeLists.txt")
	if ok then
		vim.notify("Generated CMakeLists.txt for project " .. project, vim.log.levels.INFO)
	else
		vim.notify(
			"Error writing CMakeLists.txt: " .. (err or "unknown error"),
			vim.log.levels.ERROR
		)
	end
end

-- ========================
-- Build
-- ========================
function M.build_project()
	local build_dir = M.config.build_dir
	local build_type = M.config.build_type
	if not dir_exists(build_dir) then
		vim.fn.mkdir(build_dir, "p")
	end

	local gen = detect_generator()
	local jobs = detect_jobs()

	local args = {
		shesc(M.config.cmake_program),
		"-S .",
		"-B " .. shesc(build_dir),
		"-G " .. shesc(gen),
		"-DCMAKE_BUILD_TYPE=" .. build_type,
		"-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
	}

	if M.config.use_ccache and have_exe("ccache") then
		table.insert(args, "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache")
	end

	for _, a in ipairs(M.config.extra_cmake_args or {}) do
		table.insert(args, a)
	end

	local configure = table.concat(args, " ")
	local build = ("%s --build %s --parallel %s"):format(
		shesc(M.config.cmake_program),
		shesc(build_dir),
		tostring(jobs)
	)
	local post = ("ln -sfn %s %s || true"):format(
		shesc(build_dir .. "/compile_commands.json"),
		shesc("compile_commands.json")
	)

	local cmd = ("set -e && %s && %s && %s"):format(configure, build, post)
	open_terminal(cmd, "CMake Build")
end

-- ========================
-- Run
-- ========================
function M.run_project(args)
	local exe = M.config.build_dir .. "/" .. get_project_name()
	if not file_exists(exe) then
		vim.notify(
			"Executable not found. Build first (CMakeBuild/CMakeQuick).",
			vim.log.levels.ERROR
		)
		return
	end

	local cmd = shesc("./" .. exe) .. (args and args ~= "" and " " .. args or "")
	open_terminal(cmd, "Run")
end

-- ========================
-- Quick: Gen(if needed) + Build + Run
-- ========================
function M.quick_run(args)
	if not file_exists("CMakeLists.txt") then
		M.generate_cmake()
	end

	local build_dir = M.config.build_dir
	if not dir_exists(build_dir) then
		vim.fn.mkdir(build_dir, "p")
	end

	local gen = detect_generator()
	local jobs = detect_jobs()

	local base_cfg = {
		shesc(M.config.cmake_program),
		"-S .",
		"-B " .. shesc(build_dir),
		"-G " .. shesc(gen),
		"-DCMAKE_BUILD_TYPE=" .. M.config.build_type,
		"-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
	}

	if M.config.use_ccache and have_exe("ccache") then
		table.insert(base_cfg, "-DCMAKE_CXX_COMPILER_LAUNCHER=ccache")
	end

	for _, a in ipairs(M.config.extra_cmake_args or {}) do
		table.insert(base_cfg, a)
	end

	local configure = table.concat(base_cfg, " ")
	local build = ("%s --build %s --parallel %s"):format(
		shesc(M.config.cmake_program),
		shesc(build_dir),
		tostring(jobs)
	)
	local run = shesc("./" .. build_dir .. "/" .. get_project_name())
		.. (args and args ~= "" and " " .. args or "")
	local post = ("ln -sfn %s %s || true"):format(
		shesc(build_dir .. "/compile_commands.json"),
		shesc("compile_commands.json")
	)

	local cmd = ("set -e && %s && %s && %s && %s"):format(configure, build, post, run)
	open_terminal(cmd, "Build & Run")
end

-- ========================
-- Clean
-- ========================
function M.clean_project()
	local dir = M.config.build_dir
	if dir_exists(dir) then
		vim.fn.delete(dir, "rf")
		vim.notify("Build directory removed.", vim.log.levels.INFO)
	else
		vim.notify("Nothing to clean.", vim.log.levels.INFO)
	end
end

-- ========================
-- Build Type helpers
-- ========================
local VALID_TYPES = { Debug = true, Release = true, RelWithDebInfo = true, MinSizeRel = true }

function M.set_build_type(bt)
	if not VALID_TYPES[bt] then
		vim.notify("Invalid build type: " .. tostring(bt), vim.log.levels.ERROR)
		return
	end
	M.config.build_type = bt
	vim.notify("Build type set to " .. bt, vim.log.levels.INFO)
end

local function toggle_build_type()
	local now = M.config.build_type
	local next_ = (now == "Debug") and "Release" or "Debug"
	M.set_build_type(next_)
end

-- ========================
-- Setup Commands
-- ========================
function M.setup(user_config)
	if user_config then
		for k, v in pairs(user_config) do
			M.config[k] = v
		end
	end

	vim.api.nvim_create_user_command(
		"CMakeGen",
		M.generate_cmake,
		{ desc = "Generate CMakeLists.txt" }
	)
	vim.api.nvim_create_user_command(
		"CMakeBuild",
		M.build_project,
		{ desc = "Configure and build project" }
	)
	vim.api.nvim_create_user_command("CMakeRun", function(opts)
		M.run_project(opts.args)
	end, { desc = "Run project executable", nargs = "*" })
	vim.api.nvim_create_user_command("CMakeQuick", function(opts)
		M.quick_run(opts.args)
	end, { desc = "Build and run (quick)", nargs = "*" })
	vim.api.nvim_create_user_command(
		"CMakeClean",
		M.clean_project,
		{ desc = "Clean build directory" }
	)
	vim.api.nvim_create_user_command("CMakeType", function(opts)
		if not opts.args or opts.args == "" then
			toggle_build_type()
		else
			M.set_build_type(opts.args)
		end
	end, {
		desc = "Set or toggle CMAKE_BUILD_TYPE (Debug/Release/RelWithDebInfo/MinSizeRel; empty to toggle)",
		nargs = "?",
		complete = function()
			return { "Debug", "Release", "RelWithDebInfo", "MinSizeRel" }
		end,
	})
end

return M
