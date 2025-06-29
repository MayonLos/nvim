
return {
  "akinsho/toggleterm.nvim",
  version = "*",
  event = "VeryLazy",
  opts = {
    size = 15,
    direction = "horizontal",
    hide_numbers = true,
    shade_terminals = false,
    start_in_insert = true,
    auto_scroll = true,
    float_opts = { border = "rounded" },
  },
  config = function(_, opts)
    require("toggleterm").setup(opts)
    local Terminal = require("toggleterm.terminal").Terminal

    -- 动态实例池
    local term_pool = {}

    -- 判断当前 buffer 是否真实文件（避免 term://）
    local function get_real_cwd()
      local bufname = vim.api.nvim_buf_get_name(0)
      if bufname == "" then
        return vim.loop.cwd()
      end
      if bufname:match("^term://") then
        return nil
      end
      local dir = vim.fn.fnamemodify(bufname, ":p:h")
      if vim.fn.isdirectory(dir) == 1 then
        return dir
      end
      return nil
    end

    -- 支持记忆 cwd，只有 cwd 变化时才重新 cd
    local function get_or_create_terminal(key, params)
      if not term_pool[key] then
        term_pool[key] = {
          instance = nil,
          last_cwd = nil,
        }
      end

      local pool = term_pool[key]

      if not pool.instance then
        pool.instance = Terminal:new(vim.tbl_extend("force", params, {
          on_open = function(term)
            -- 默认插入模式
            vim.cmd("startinsert!")
            -- cd 逻辑
            local cwd = params.cwd or get_real_cwd()
            if cwd and cwd ~= pool.last_cwd then
              pool.last_cwd = cwd
              vim.defer_fn(function()
                term:send("cd " .. vim.fn.fnameescape(cwd) .. "\n", false)
              end, 20)
            end
          end,
        }))
      else
        -- 打开时检查 cwd 是否需要变更
        local cwd = params.cwd or get_real_cwd()
        if cwd and cwd ~= pool.last_cwd then
          pool.last_cwd = cwd
          -- 这里用 term:send，重新 cd，但不 new 实例
          vim.defer_fn(function()
            pool.instance:send("cd " .. vim.fn.fnameescape(cwd) .. "\n", false)
          end, 20)
        end
      end

      return pool.instance
    end

    local kopt = { noremap = true, silent = true }
    local function toggle_term(key, params)
      return function()
        local term = get_or_create_terminal(key, params or {})
        term:toggle()
      end
    end

    local map = vim.keymap.set
    map({ "n", "t" }, "<leader>tf", toggle_term("float",   { direction = "float" }),        vim.tbl_extend("force", kopt, { desc = "Terminal Float"     }))
    map({ "n", "t" }, "<leader>tv", toggle_term("vertical",{ direction = "vertical",   size = 40 }), vim.tbl_extend("force", kopt, { desc = "Terminal Vertical"  }))
    map({ "n", "t" }, "<leader>tt", toggle_term("split",   { direction = "horizontal", size = 15 }), vim.tbl_extend("force", kopt, { desc = "Terminal Split"     }))
    map({ "n", "t" }, "<leader>tg", toggle_term("lazygit", { direction = "float", cmd = "lazygit" }),vim.tbl_extend("force", kopt, { desc = "Terminal Lazygit"   }))

    -- term 模式按键，ESC/JK 退出，自动插入模式
    vim.api.nvim_create_autocmd("TermOpen", {
      pattern = "term://*",
      callback = function()
        local o = { buffer = 0 }
        vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], o)
        vim.keymap.set("t", "jk", [[<C-\><C-n>]], o)
        vim.cmd("startinsert!")
      end
    })
  end,
}

