return {
	{
		"mfussenegger/nvim-dap",
		keys = {
			{
				"<F5>",
				function()
					require("dap").continue()
				end,
				desc = "DAP: Continue",
			},
			{
				"<F9>",
				function()
					require("dap").toggle_breakpoint()
				end,
				desc = "DAP: Toggle Breakpoint",
			},
			{
				"<F10>",
				function()
					require("dap").step_over()
				end,
				desc = "DAP: Step Over",
			},
			{
				"<F11>",
				function()
					require("dap").step_into()
				end,
				desc = "DAP: Step Into",
			},
			{
				"<F12>",
				function()
					require("dap").step_out()
				end,
				desc = "DAP: Step Out",
			},
			{
				"<S-F5>",
				function()
					require("dap").terminate()
				end,
				desc = "DAP: Terminate",
			},
		},
		dependencies = {
			{
				"jay-babu/mason-nvim-dap.nvim",
				dependencies = "williamboman/mason.nvim",
				opts = {
					automatic_setup = true,
					ensure_installed = { "codelldb", "debugpy" },
					handlers = {},
				},
			},
			{
				"rcarriga/nvim-dap-ui",
				dependencies = { "nvim-neotest/nvim-nio" },
				opts = {
					floating = { border = "rounded" },
					layouts = {
						{
							elements = {
								{ id = "stacks", size = 0.25 },
								{ id = "breakpoints", size = 0.25 },
								{ id = "scopes", size = 0.25 },
								{ id = "watches", size = 0.25 },
							},
							position = "left",
							size = 40,
						},
						{
							elements = { { id = "repl", size = 0.5 }, { id = "console", size = 0.5 } },
							position = "bottom",
							size = 10,
						},
					},
				},
				config = function(_, opts)
					local dap, dapui = require("dap"), require("dapui")
					dapui.setup(opts)
					dap.listeners.after.event_initialized["dapui_config"] = dapui.open
					dap.listeners.before.event_terminated["dapui_config"] = dapui.close
					dap.listeners.before.event_exited["dapui_config"] = dapui.close
				end,
			},
			{ "theHamsta/nvim-dap-virtual-text", opts = { commented = true } },
		},
		config = function()
			local dap = require("dap")

			-- Define highlight group for the current execution line
			vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = "#3f3f00" })

			-- Set NerdIcons for breakpoints and current execution point
			vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint", linehl = "", numhl = "" })
			vim.fn.sign_define(
				"DapBreakpointCondition",
				{ text = "", texthl = "DapStopped", linehl = "", numhl = "" }
			)
			vim.fn.sign_define(
				"DapStopped",
				{ text = "", texthl = "DapStopped", linehl = "DapStoppedLine", numhl = "" }
			)

			-- C/C++ with codelldb
			dap.adapters.codelldb = {
				type = "server",
				port = "${port}",
				host = "127.0.0.1",
				executable = {
					command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
					args = { "--port", "${port}" },
				},
			}

			dap.configurations.cpp = {
				{
					name = "Launch (codelldb)",
					type = "codelldb",
					request = "launch",
					program = function()
						return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
					end,
					cwd = "${workspaceFolder}",
					stopOnEntry = false,
					terminateOnExit = true,
					terminal = "integrated",
				},
			}
			dap.configurations.c = dap.configurations.cpp

			-- Python with debugpy
			dap.adapters.python = {
				type = "executable",
				command = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python",
				args = { "-m", "debugpy.adapter" },
			}

			dap.configurations.python = {
				{
					name = "Launch Python File",
					type = "python",
					request = "launch",
					program = "${file}",
					pythonPath = function()
						return "python3"
					end,
				},
			}
		end,
	},
}
