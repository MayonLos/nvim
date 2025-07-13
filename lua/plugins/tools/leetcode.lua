return {
	"kawre/leetcode.nvim",
	cmd = { "Leet" }, -- 避免 build 阶段报错，支持手动打开
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-telescope/telescope.nvim", -- 你用的是 telescope 作为 picker
	},
	opts = {
		lang = "cpp", -- 默认使用 C++
		picker = { provider = "telescope" },
		cn = {
			enabled = true, -- 启用 leetcode.cn
			translator = true,
			translate_problems = true,
		},
		plugins = {
			non_standalone = true, -- 支持在已有会话中打开
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
