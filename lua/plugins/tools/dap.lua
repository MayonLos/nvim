return {
	{
		"mfussenegger/nvim-dap",
		event = "VeryLazy",
		dependencies = {
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			"theHamsta/nvim-dap-virtual-text",
		},
		keys = {
			{
				"<F5>",
				function()
					require("dap").continue()
				end,
				desc = "DAP Continue",
			},
			{
				"<S-F5>",
				function()
					require("dap").terminate()
				end,
				desc = "DAP Terminate",
			},
			{
				"<F10>",
				function()
					require("dap").step_over()
				end,
				desc = "DAP Step Over",
			},
			{
				"<F11>",
				function()
					require("dap").step_into()
				end,
				desc = "DAP Step Into",
			},
			{
				"<S-F11>",
				function()
					require("dap").step_out()
				end,
				desc = "DAP Step Out",
			},

			{
				"<leader>db",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "DAP Toggle Breakpoint",
			},
			{
				"<leader>dB",
				function()
					require("dap").set_breakpoint(vim.fn.input "Condition: ")
				end,
				desc = "DAP Conditional Breakpoint",
			},
			{
				"<leader>dl",
				function()
					require("dap").set_breakpoint(nil, nil, vim.fn.input "Log: ")
				end,
				desc = "DAP Log Point",
			},

			{
				"<leader>du",
				function()
					require("dapui").toggle {}
				end,
				desc = "DAP UI Toggle",
			},
			{
				"<leader>dr",
				function()
					require("dap").repl.open()
				end,
				desc = "DAP REPL",
			},
			{
				"<leader>de",
				function()
					require("dap.ui.widgets").hover()
				end,
				desc = "DAP Eval (Hover)",
			},
			{
				"<leader>dE",
				function()
					local w = require "dap.ui.widgets"
					w.centered_float(w.scopes)
				end,
				desc = "DAP Scopes Float",
			},
		},

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

			if not dap.restart then
				vim.keymap.set("n", "<leader>dR", function()
					dap.terminate()
					vim.defer_fn(function()
						dap.run_last()
					end, 200)
				end, { desc = "DAP Restart" })
			end
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
