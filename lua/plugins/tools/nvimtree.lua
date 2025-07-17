return {
	"nvim-tree/nvim-tree.lua",
	version = "*",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VeryLazy",
	config = function()
		local api = require("nvim-tree.api")
		local tree = api.tree

		-- ===============================
		-- 排序功能模块
		-- ===============================
		local sort_module = {
			methods = {
				"name",
				"case_sensitive",
				"modification_time",
				"extension",
				"natural",
			},
			current = 1,
		}

		-- 自然排序比较函数
		local function natural_compare(left, right)
			local left_name = left.name:lower()
			local right_name = right.name:lower()

			-- 提取数字和文本片段
			local function extract_chunks(str)
				local chunks = {}
				for chunk in str:gmatch("[0-9]+|[^0-9]+") do
					local num = tonumber(chunk)
					table.insert(chunks, num or chunk)
				end
				return chunks
			end

			local left_chunks = extract_chunks(left_name)
			local right_chunks = extract_chunks(right_name)

			for i = 1, math.max(#left_chunks, #right_chunks) do
				local l_chunk = left_chunks[i] or ""
				local r_chunk = right_chunks[i] or ""

				-- 数字比较
				if type(l_chunk) == "number" and type(r_chunk) == "number" then
					if l_chunk ~= r_chunk then
						return l_chunk < r_chunk
					end
				-- 字符串比较
				elseif l_chunk ~= r_chunk then
					return tostring(l_chunk) < tostring(r_chunk)
				end
			end

			return false
		end

		-- 排序函数
		local function sort_nodes(nodes)
			local method = sort_module.methods[sort_module.current]

			if method == "natural" then
				table.sort(nodes, natural_compare)
			else
				table.sort(nodes, function(a, b)
					if method == "name" then
						return a.name:lower() < b.name:lower()
					elseif method == "case_sensitive" then
						return a.name < b.name
					elseif method == "modification_time" then
						return (a.modified or 0) > (b.modified or 0)
					elseif method == "extension" then
						local a_ext = a.name:match("^.+(%..+)$") or ""
						local b_ext = b.name:match("^.+(%..+)$") or ""
						return a_ext ~= b_ext and a_ext < b_ext or a.name < b.name
					else
						return a.name < b.name
					end
				end)
			end

			return nodes
		end

		-- 循环切换排序方法
		local function cycle_sort()
			sort_module.current = sort_module.current >= #sort_module.methods and 1
				or sort_module.current + 1

			tree.reload()
			vim.notify("Sort method: " .. sort_module.methods[sort_module.current], vim.log.levels.INFO)
		end

		-- ===============================
		-- 自定义操作函数
		-- ===============================
		local custom_actions = {}

		-- ARIA 导航 - 左箭头行为
		function custom_actions.aria_left()
			local node = tree.get_node_under_cursor()
			if node.nodes and node.open then
				api.node.open.edit() -- 关闭打开的目录
			else
				api.node.navigate.parent() -- 移动到父目录
			end
		end

		-- ARIA 导航 - 右箭头行为
		function custom_actions.aria_right()
			local node = tree.get_node_under_cursor()
			if node.nodes and not node.open then
				api.node.open.edit() -- 打开关闭的目录
			end
		end

		-- 编辑或打开文件并关闭树
		function custom_actions.edit_or_open()
			local node = tree.get_node_under_cursor()

			if node.nodes then
				api.node.open.edit() -- 展开/折叠目录
			else
				api.node.open.edit() -- 打开文件
				tree.close() -- 关闭树
			end
		end

		-- 垂直分割预览，保持焦点在树上
		function custom_actions.vsplit_preview()
			local node = tree.get_node_under_cursor()

			if node.nodes then
				api.node.open.edit() -- 展开/折叠目录
			else
				api.node.open.vertical() -- 垂直分割打开文件
			end

			tree.focus() -- 重新聚焦树
		end

		-- 静默打开新标签页
		function custom_actions.open_tab_silent(node)
			api.node.open.tab(node)
			vim.cmd.tabprev() -- 回到之前的标签页
		end

		-- Git 暂存/取消暂存
		function custom_actions.git_add()
			local node = tree.get_node_under_cursor()
			local git_status = node.git_status.file

			-- 如果是目录，获取子项状态
			if not git_status then
				git_status = (node.git_status.dir.direct and node.git_status.dir.direct[1])
					or (node.git_status.dir.indirect and node.git_status.dir.indirect[1])
			end

			if git_status then
				-- 暂存未跟踪/未暂存的文件
				if git_status:match("^[%?%s]") or git_status:match("M$") then
					vim.cmd("silent !git add " .. vim.fn.shellescape(node.absolute_path))
				-- 取消暂存已暂存的文件
				elseif git_status:match("^[MA]") then
					vim.cmd("silent !git restore --staged " .. vim.fn.shellescape(node.absolute_path))
				end
			end

			tree.reload()
		end

		-- ===============================
		-- 标记操作功能
		-- ===============================
		local mark_operations = {}

		-- 标记并移动
		function mark_operations.mark_move_j()
			api.marks.toggle()
			vim.cmd("normal! j")
		end

		function mark_operations.mark_move_k()
			api.marks.toggle()
			vim.cmd("normal! k")
		end

		-- 获取标记的文件或当前文件
		local function get_marked_or_current()
			local marks = api.marks.list()
			if #marks == 0 then
				marks = { tree.get_node_under_cursor() }
			end
			return marks
		end

		-- 删除到垃圾箱
		function mark_operations.trash_files()
			local marks = get_marked_or_current()
			vim.ui.input({ prompt = string.format("Trash %d file(s)? [y/N]: ", #marks) }, function(input)
				if input and input:lower() == "y" then
					for _, node in ipairs(marks) do
						api.fs.trash(node)
					end
					api.marks.clear()
					tree.reload()
				end
			end)
		end

		-- 永久删除
		function mark_operations.remove_files()
			local marks = get_marked_or_current()
			vim.ui.input(
				{ prompt = string.format("Permanently delete %d file(s)? [y/N]: ", #marks) },
				function(input)
					if input and input:lower() == "y" then
						for _, node in ipairs(marks) do
							api.fs.remove(node)
						end
						api.marks.clear()
						tree.reload()
					end
				end
			)
		end

		-- 复制文件
		function mark_operations.copy_files()
			local marks = get_marked_or_current()
			for _, node in ipairs(marks) do
				api.fs.copy.node(node)
			end
			api.marks.clear()
			tree.reload()
		end

		-- 剪切文件
		function mark_operations.cut_files()
			local marks = get_marked_or_current()
			for _, node in ipairs(marks) do
				api.fs.cut(node)
			end
			api.marks.clear()
			tree.reload()
		end

		-- ===============================
		-- 按键映射配置
		-- ===============================
		local function setup_keymaps(bufnr)
			local function opts(desc)
				return {
					desc = "nvim-tree: " .. desc,
					buffer = bufnr,
					noremap = true,
					silent = true,
					nowait = true,
				}
			end

			-- 加载默认映射
			api.config.mappings.default_on_attach(bufnr)

			-- 核心操作映射
			local core_mappings = {
				-- 导航
				["<Left>"] = { custom_actions.aria_left, "ARIA: Left Arrow / Close Node / Parent" },
				["<Right>"] = { custom_actions.aria_right, "ARIA: Right Arrow / Open Node" },
				["h"] = { tree.close, "Close Current Tree" },
				["H"] = { tree.collapse_all, "Collapse All Trees" },
				["l"] = { custom_actions.edit_or_open, "Edit Or Open / Close Tree" },
				["L"] = { custom_actions.vsplit_preview, "Vsplit Preview / Keep Focus on Tree" },

				-- 文件操作
				["T"] = { custom_actions.open_tab_silent, "Open Tab Silent" },
				["ga"] = { custom_actions.git_add, "Git Add/Restore" },

				-- 标记操作
				["J"] = { mark_operations.mark_move_j, "Toggle Bookmark Down" },
				["K"] = { mark_operations.mark_move_k, "Toggle Bookmark Up" },

				-- 文件操作
				["dd"] = { mark_operations.cut_files, "Cut File(s)" },
				["df"] = { mark_operations.trash_files, "Trash File(s)" },
				["dF"] = { mark_operations.remove_files, "Remove File(s)" },
				["yy"] = { mark_operations.copy_files, "Copy File(s)" },

				-- 排序
				["<leader>t"] = { cycle_sort, "Cycle Sort" },
			}

			-- 应用映射
			for key, mapping in pairs(core_mappings) do
				vim.keymap.set("n", key, mapping[1], opts(mapping[2]))
			end
		end

		-- ===============================
		-- nvim-tree 配置
		-- ===============================
		require("nvim-tree").setup({
			view = {
				width = 30,
				side = "left",
			},
			git = {
				enable = true,
			},
			sort_by = sort_nodes,
			live_filter = {
				prefix = "[FILTER]: ",
				always_show_folders = false,
			},
			ui = {
				confirm = {
					remove = true,
					trash = false,
				},
			},
			on_attach = setup_keymaps,
		})

		-- ===============================
		-- 窗口和状态栏配置
		-- ===============================

		-- 设置空状态栏
		api.events.subscribe(api.events.Event.TreeOpen, function()
			local tree_winid = tree.winid()
			if tree_winid then
				vim.api.nvim_set_option_value("statusline", " ", { win = tree_winid })
			end
		end)

		-- 智能退出行为
		local function setup_smart_quit()
			vim.api.nvim_create_autocmd({ "BufEnter", "QuitPre" }, {
				nested = false,
				callback = function(event)
					if not tree.is_visible() then
						return
					end

					local focusable_wins = vim.tbl_filter(function(winid)
						return vim.api.nvim_win_get_config(winid).focusable
					end, vim.api.nvim_list_wins())

					local win_count = #focusable_wins

					if event.event == "QuitPre" and win_count == 2 then
						vim.api.nvim_cmd({ cmd = "qall" }, {})
					elseif event.event == "BufEnter" and win_count == 1 then
						vim.defer_fn(function()
							tree.toggle({ find_file = true, focus = true })
							tree.toggle({ find_file = true, focus = false })
						end, 10)
					end
				end,
			})
		end

		setup_smart_quit()

		-- ===============================
		-- 全局快捷键
		-- ===============================
		vim.keymap.set(
			"n",
			"<leader>e",
			":NvimTreeToggle<CR>",
			{ silent = true, noremap = true, desc = "Toggle NvimTree" }
		)
	end,
}
