return {
	"romgrk/barbar.nvim",
	version = "^1.0.0",
	event = { "BufReadPost", "BufNewFile" },
	dependencies = {
		"nvim-tree/nvim-web-devicons",
		"lewis6991/gitsigns.nvim",
	},
	init = function()
		vim.g.barbar_auto_setup = false -- 禁用自动设置，使用 opts
	end,
	---@type bufferline.UserConfig
	opts = {
		animation = true, -- 关闭/打开 tab 时是否有动画
		tabpages = true, -- 显示 tabpages
		focus_on_close = "left", -- 关闭 buffer 后光标跳转方向
		insert_at_end = false, -- 新 buffer 插入位置（false = 当前后）
		maximum_length = 30, -- 单个 buffer 最大宽度
		minimum_padding = 1, -- buffer 左右最小 padding
		maximum_padding = 1, -- buffer 左右最大 padding

		icons = {
			preset = "default",
			buffer_index = false,
			buffer_number = false,
			button = "",
			modified = { button = "●" },
			pinned = { button = "", filename = true },
			separator = { left = "▎", right = "" },
			filetype = { enabled = true, custom_colors = false },
			gitsigns = {
				added = { enabled = true, icon = "+" },
				changed = { enabled = true, icon = "~" },
				deleted = { enabled = true, icon = "-" },
			},
		},

		-- 侧边栏文件类型占用 buffer 栏空间显示名称
		sidebar_filetypes = {
			NvimTree = true,
			undotree = { text = "undotree", align = "center" },
			Outline = { text = "symbols-outline", align = "right" },
		},

		sort = {
			ignore_case = true,
		},
	},
}
