return {
  {
    "echasnovski/mini.sessions",
    version = false,
    lazy = false,
    config = function()
      local sessions = require("mini.sessions")

      sessions.setup({
        autoread = false,
        autowrite = false,
        directory = vim.fn.stdpath("data") .. "/sessions/",
        file = "session.vim",
      })

      local function save_session()
        local name = vim.fn.input("Session name to save: ")
        if name ~= "" then
          sessions.write(name)
          vim.notify("Session [" .. name .. "] saved", vim.log.levels.INFO)
        else
          vim.notify("Save cancelled: empty name", vim.log.levels.WARN)
        end
      end

      local function load_session()
        local name = vim.fn.input("Session name to load: ")
        if name ~= "" then
          sessions.read(name)
          vim.notify("Session [" .. name .. "] loaded", vim.log.levels.INFO)
        else
          vim.notify("Load cancelled: empty name", vim.log.levels.WARN)
        end
      end

      vim.keymap.set("n", "<leader>ss", save_session, { desc = "Save Session" })
      vim.keymap.set("n", "<leader>sl", load_session, { desc = "Load Session" })
      vim.keymap.set("n", "<leader>sd", sessions.select, { desc = "Select Session" })
    end,
  }
}

