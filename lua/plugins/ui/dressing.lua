return {
	{
		"stevearc/dressing.nvim",
		event = "VeryLazy",
		opts = {
			input = {
				enabled = true,
				default_prompt = "➤ ",
				win_options = {
					winblend = 10,
					wrap = false,
					winhighlight = {
						Normal = "NormalFloat",
						FloatBorder = "FloatBorder",
						Title = "FloatTitle",
					},
				},
				get_config = function(opts)
					local prompt = opts.prompt or ""
					if prompt:find("Mason") then
						opts.default_prompt = " Mason ➤ "
					elseif prompt:find("DAP") then
						opts.default_prompt = " DAP ➤ "
					elseif prompt:find("Overseer") then
						opts.default_prompt = " Overseer ➤ "
					end
					return opts
				end,
			},
			select = {
				enabled = true,
				backend = { "telescope", "builtin" },
				trim_prompt = true,
				telescope = {
					theme = "dropdown",
					layout_config = {
						width = function(_, max_columns, _)
							return math.min(max_columns - 4, 80)
						end,
						height = function(_, _, max_lines)
							return math.min(max_lines - 4, 15)
						end,
					},
				},
				builtin = {
					win_options = {
						winblend = 10,
						winhighlight = {
							Normal = "NormalFloat",
							FloatBorder = "FloatBorder",
							Title = "FloatTitle",
							CursorLine = "Visual",
							Cursor = "Cursor",
						},
					},
					border = "rounded",
					animate = {
						open = { "slide", { distance = 5 } },
					},
				},
				get_config = function(opts)
					if opts.kind == "mason.nvim" then
						opts.title = " Mason Packages"
					elseif opts.kind == "dap" then
						opts.title = " DAP Configurations"
					elseif opts.kind == "overseer" then
						opts.title = " Overseer Tasks"
					elseif opts.kind == "code_action" then
						opts.title = " Code Actions"
					end
					return opts
				end,
			},
		},
		config = function(_, opts)
			require("dressing").setup(opts)
			local ok, _ = pcall(vim.api.nvim_get_hl_by_name, "CatppuccinMauve", false)
			if ok then
				vim.api.nvim_set_hl(0, "FloatBorder", { link = "CatppuccinMauve" })
				vim.api.nvim_set_hl(0, "FloatTitle", {
					bg = "NONE",
					fg = vim.api.nvim_get_hl_by_name("CatppuccinBlue", true).foreground,
					bold = true,
				})
				vim.api.nvim_set_hl(0, "LspSagaNormal", { link = "NormalFloat" })
				vim.api.nvim_set_hl(0, "LspSagaBorder", { link = "FloatBorder" })
			end
		end,
	},
}
