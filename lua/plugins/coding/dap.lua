return {
	{
		"mfussenegger/nvim-dap",
		event = "VeryLazy",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"theHamsta/nvim-dap-virtual-text",
		},
		keys = function()
			return require("core.keymaps").plugin("dap")
		end,

		config = function()
			local dap = require "dap"
			local dapui = require "dapui"

			vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DiagnosticError" })
			vim.fn.sign_define("DapBreakpointCondition", { text = "", texthl = "DiagnosticWarn" })
			vim.fn.sign_define("DapBreakpointRejected", { text = "", texthl = "DiagnosticError" })
			vim.fn.sign_define("DapStopped", { text = "", texthl = "DiagnosticInfo", linehl = "Visual" })
			vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DiagnosticInfo" })

			require("nvim-dap-virtual-text").setup { commented = true, virt_text_pos = "eol" }
			dapui.setup {
				layouts = {
					{ elements = { "scopes", "breakpoints", "stacks", "watches" }, size = 0.32, position = "right" },
					{ elements = { "repl", "console" }, size = 0.28, position = "bottom" },
				},
				controls = { enabled = true, element = "repl" },
				floating = { border = "rounded" },
				render = { max_type_length = 80 },
			}
			dap.listeners.after.event_initialized["dapui_auto"] = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated["dapui_auto"] = function()
				dapui.close()
			end
			dap.listeners.before.event_exited["dapui_auto"] = function()
				dapui.close()
			end

			local ok_mason, mr = pcall(require, "mason-registry")
			local function ensure_adapters()
				if not ok_mason then
					return
				end
				local needed = { "debugpy", "codelldb" }
				local function install_missing()
					for _, name in ipairs(needed) do
						local ok, pkg = pcall(mr.get_package, name)
						if ok and not pkg:is_installed() then
							pkg:install()
						end
					end
				end
				if mr.refresh then
					mr.refresh(install_missing)
				else
					install_missing()
				end
			end
			ensure_adapters()

			local function detect_python()
				local function exe(p)
					return (vim.fn.executable(p) == 1) and p or nil
				end
				local venv = os.getenv "VIRTUAL_ENV" or os.getenv "CONDA_PREFIX"
				if venv and #venv > 0 then
					local py = (vim.fn.has "win32" == 1) and (venv .. "\\Scripts\\python.exe")
						or (venv .. "/bin/python")
					if exe(py) then
						return py
					end
				end
				local cwd = vim.fn.getcwd()
				for _, p in ipairs {
					"/.venv/bin/python",
					"/venv/bin/python",
					"/.venv/Scripts/python.exe",
					"/venv/Scripts/python.exe",
				} do
					if exe(cwd .. p) then
						return (cwd .. p)
					end
				end
				return exe "python3" or "python"
			end

			local py = detect_python()
			dap.adapters.python = {
				type = "server",
				host = "127.0.0.1",
				port = function()
					return require("dap.utils").pick_random_port()
				end,
				executable = { command = py, args = { "-m", "debugpy.adapter" } },
			}
			dap.configurations.python = {
				{
					type = "python",
					request = "launch",
					name = "Launch file",
					program = "${file}",
					console = "integratedTerminal",
					justMyCode = true,
					pythonPath = py,
				},
				{
					type = "python",
					request = "attach",
					name = "Attach (localhost:5678)",
					connect = { host = "127.0.0.1", port = 5678 },
					justMyCode = false,
				},
			}

			local codelldb_bin = vim.fn.exepath "codelldb"
			if codelldb_bin == "" then
				codelldb_bin = "codelldb"
			end

			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				executable = { command = codelldb_bin, args = { "--port", "${port}" } },
			}
			local codelldb_cfg = {
				{
					name = "Launch (codelldb)",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					args = {},
					runInTerminal = true,
				},
				{
					name = "Attach to process",
					type = "codelldb",
					request = "attach",
					pid = require("dap.utils").pick_process,
					cwd = "${workspaceFolder}",
				},
			}
			dap.configurations.c = codelldb_cfg
			dap.configurations.cpp = codelldb_cfg

			-- Restart mapping handled via core.keymaps
		end,
	},

	{
		"rcarriga/nvim-dap-ui",
		lazy = true,
		dependencies = { "mfussenegger/nvim-dap", "nvim-neotest/nvim-nio" },
		opts = {
			layouts = {
				{ elements = { "scopes", "breakpoints", "stacks", "watches" }, size = 0.32, position = "right" },
				{ elements = { "repl", "console" }, size = 0.28, position = "bottom" },
			},
			controls = { enabled = true, element = "repl" },
			floating = { border = "rounded" },
			render = { max_type_length = 80 },
		},
	},
	{
		"theHamsta/nvim-dap-virtual-text",
		lazy = true,
		opts = { commented = true, virt_text_pos = "eol" },
	},
}
