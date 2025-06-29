
return {
  {
    "echasnovski/mini.starter",
    version = false,
    lazy = false,
    config = function()
      local starter = require("mini.starter")

      starter.setup({
        evaluate_single = true,

        -- 标题美化：NerdIcons + 居中 box
        header = table.concat({
          "╭──────────────────────────────────╮",
          "│     欢迎回来，启程吧！          │",
          "╰──────────────────────────────────╯",
        }, "\n"),

        -- 项目菜单内容
        items = {
          -- 内建操作（新建文件、退出等）
          starter.sections.builtin_actions(),

          -- 最近文件（带图标）
          starter.sections.recent_files(5, true),

          -- 会话恢复（带图标）
          starter.sections.sessions(3, true),
        },

        -- 美化：图标 + 居中
        content_hooks = {
          starter.gen_hook.adding_bullet(" ", false),  -- 替换 ➤ 为 NerdIcon
          starter.gen_hook.aligning("center", "center"),
        },

        -- 默认页脚提示
        footer = " 正在加载启动信息...",
      })

      -- Lazy 统计信息显示在页脚
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyVimStarted",
        callback = function(ev)
          local stats = require("lazy").stats()
          local ms = (math.floor(stats.startuptime * 100 + 0.5) / 100)
          starter.config.footer = string.format("⚡ 启动加载了 %d/%d 个插件，耗时 %.2fms",
            stats.loaded, stats.count, ms)
          if vim.bo[ev.buf].filetype == "ministarter" then
            pcall(starter.refresh)
          end
        end,
      })
    end,
  },
}

