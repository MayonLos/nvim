return {
	{
		"AckslD/nvim-neoclip.lua",
		dependencies = {
			{ "nvim-telescope/telescope.nvim" }, -- Telescope 集成
			{ "kkharji/sqlite.lua", module = "sqlite" }, -- 持久化历史依赖
		},
		event = { "TextYankPost" }, -- 延迟加载，触发剪贴时加载
		config = function()
			local function is_whitespace(line)
				return vim.fn.match(line, [[^\s*$]]) ~= -1
			end

			local function all(tbl, check)
				for _, entry in ipairs(tbl) do
					if not check(entry) then
						return false
					end
				end
				return true
			end

			require("neoclip").setup({
				history = 1000, -- 存储最多 1000 条剪贴记录
				enable_persistent_history = true, -- 启用持久化历史
				db_path = vim.fn.stdpath("data") .. "/databases/neoclip.sqlite3", -- 默认数据库路径
				filter = function(data)
					return not all(data.event.regcontents, is_whitespace) -- 过滤纯空白内容
				end,
				preview = true, -- 启用预览，显示剪贴内容和语法高亮
				default_register = { '"', "+", "*" }, -- 默认寄存器：无名、系统剪贴板
				enable_macro_history = false, -- 禁用宏历史
				continuous_sync = false, -- 禁用连续同步以提高性能
				keys = {
					telescope = {
						i = {
							select = "<CR>", -- 选择条目
							paste = "<C-p>", -- 粘贴
							paste_behind = "<C-k>", -- 在光标后粘贴
							delete = "<C-d>", -- 删除条目
							edit = "<C-e>", -- 编辑条目
						},
						n = {
							select = "<CR>",
							paste = "p",
							paste_behind = "P",
							delete = "d",
							edit = "e",
						},
					},
				},
			})

			-- 加载 Telescope 扩展
			require("telescope").load_extension("neoclip")
		end,
		keys = {
			{ "<leader>fy", "<cmd>Telescope neoclip<cr>", desc = "Yank History" }, -- 浏览剪贴历史
		},
	},
}
