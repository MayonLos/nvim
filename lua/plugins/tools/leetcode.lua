return {
    "kawre/leetcode.nvim",
    cmd = { "Leet" }, -- Avoid build errors, support manual opening
    dependencies = {
        "nvim-lua/plenary.nvim",
        "MunifTanjim/nui.nvim",
        "nvim-telescope/telescope.nvim", -- Use telescope as picker
    },
    opts = {
        lang = "cpp", -- Default language is C++
        picker = { provider = "telescope" },
        cn = {
            enabled = true, -- Enable leetcode.cn
            translator = true,
            translate_problems = true,
        },
        plugins = {
            non_standalone = true, -- Support opening in existing session
        },
        editor = {
            reset_previous_code = true,
            fold_imports = true,
        },
        console = {
            open_on_runcode = true,
            dir = "row",
            size = {
                width = "90%",
                height = "75%",
            },
            result = { size = "60%" },
            testcase = {
                virt_text = true,
                size = "40%",
            },
        },
        description = {
            position = "left",
            width = "40%",
            show_stats = true,
        },
    },
}
