
return {
  -- ──────────────── 1. DAP 核心 ────────────────
  {
    "mfussenegger/nvim-dap",
    -- ▶ VS-Code 经典键位
    keys = {
      { "<F5>",  function() require("dap").continue()           end, desc = "DAP • Continue / Start" },
      { "<F9>",  function() require("dap").toggle_breakpoint()  end, desc = "DAP • Toggle Breakpoint" },
      { "<F10>", function() require("dap").step_over()          end, desc = "DAP • Step Over" },
      { "<F11>", function() require("dap").step_into()          end, desc = "DAP • Step Into" },
      { "<F12>", function() require("dap").step_out()           end, desc = "DAP • Step Out"  },
      { "<S-F5>", function() require("dap").terminate()         end, desc = "DAP • Terminate" },
    },

    -- ──────────────── 2. 依赖/扩展 ────────────────
    dependencies = {
      -- Mason-DAP：自动下载调试器
      {
        "jay-babu/mason-nvim-dap.nvim",
        dependencies = "williamboman/mason.nvim",
        opts = {
          automatic_setup = true,
          ensure_installed = { "codelldb", "cpptools", "debugpy" }, -- C/C++ & Python
        },
      },

      -- ▲ UI 面板（变量 / 调用栈）
      {
        "rcarriga/nvim-dap-ui",
        dependencies = { "nvim-neotest/nvim-nio" },  -- ← 必须！否则报 nvim-nio 缺失
        config = function()
          local dap, dapui = require("dap"), require("dapui")
          dapui.setup({ floating = { border = "rounded" } })
          dap.listeners.after.event_initialized["dapui_config"] = function() dapui.open()  end
          dap.listeners.before.event_terminated["dapui_config"] = function() dapui.close() end
          dap.listeners.before.event_exited["dapui_config"]     = function() dapui.close() end
        end,
      },

      -- ▲ 行尾变量值
      { "theHamsta/nvim-dap-virtual-text", opts = { commented = true } },
    },

    -- ──────────────── 3. 适配器与语言配置 ────────────────
    config = function()
      local dap = require("dap")

      -- ▶ C / C++ — codelldb
      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
          args = { "--port", "${port}" },
        },
      }

      dap.configurations.cpp = {
        {
          name            = "Launch file (codelldb)",
          type            = "codelldb",
          request         = "launch",
          program         = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd             = "${workspaceFolder}",
          stopOnEntry     = false,
          runInTerminal   = true,
        },
      }
      dap.configurations.c = dap.configurations.cpp -- 复用同一套

      -- ▶ Python — debugpy
      dap.adapters.python = {
        type = "executable",
        command = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python",
        args = { "-m", "debugpy.adapter" },
      }

      dap.configurations.python = {
        {
          type       = "python",
          request    = "launch",
          name       = "Launch current file",
          program    = "${file}",
          pythonPath = function() return "python3" end,
        },
      }
    end,
  },
}

