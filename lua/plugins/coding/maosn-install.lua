return {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    cmd = { "MasonToolsInstall", "MasonToolsUpdate" },
    event = "VeryLazy",
    opts = {
        ensure_installed = {
            -- ✅ LSP
            "clangd",
            "lua-language-server",
            "pyright",
            "bash-language-server",
            "marksman",
            -- ✅ Formatters
            "stylua",
            "black",
            "isort",
            "shfmt",
            "clang-format",
            "prettier",
            -- ✅ Linters
            "luacheck",
            "shellcheck",
            "pylint",
            "cpplint",
            "markdownlint",
            -- ✅ DAP Adapters
            "codelldb",
            "debugpy",
            "js-debug-adapter",
            "node-debug2-adapter",
        },
        run_on_start = true,
        auto_update = false,
        start_delay = 3000,
    },
}
