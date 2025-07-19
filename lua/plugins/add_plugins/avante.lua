return {
    "yetone/avante.nvim",
    -- 如果您想从源代码构建，请执行 `make BUILD_FROM_SOURCE=true`
    build = "make", -- ⚠️ 一定要加上这一行配置！！！！！
    -- build = "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false" -- 对于 Windows
    event = "VeryLazy",
    version = false, -- 永远不要将此值设置为 "*"！永远不要！
    ---@module 'avante'
    ---@type avante.Config
    opts = {
        -- 在此处添加任何选项
        -- 例如
        provider = "copilot",
        providers = {
            copilot = {},
        },
        input = {
            provider = "snacks", -- Explicitly set snacks as the input provider
        },
    },
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        --- 以下依赖项是可选的，
        "nvim-telescope/telescope.nvim", -- 用于文件选择器提供者 telescope
        "nvim-tree/nvim-web-devicons", -- 或 echasnovski/mini.icons
        "zbirenbaum/copilot.lua",  -- 用于 providers='copilot'
        {
            -- 如果您有 lazy=true，请确保正确设置
            "MeanderingProgrammer/render-markdown.nvim",
            opts = {
                file_types = { "markdown", "Avante" },
            },
            ft = { "markdown", "Avante" },
        },
    },
}
