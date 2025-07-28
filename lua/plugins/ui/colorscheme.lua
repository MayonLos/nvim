return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		lazy = false, -- Load immediately to ensure availability
		config = function()
			require("catppuccin").setup {
				flavour = "frappe", -- Default flavor: latte, frappe, macchiato, mocha
				background = {
					light = "latte",
					dark = "frappe",
				},
				transparent_background = true,
				show_end_of_buffer = false,
				term_colors = true,
				dim_inactive = {
					enabled = false,
					shade = "dark",
					percentage = 0.15,
				},
				no_italic = false,
				no_bold = false,
				no_underline = false,
				styles = {
					comments = { "italic" },
					conditionals = { "italic" },
					loops = {},
					functions = {},
					keywords = {},
					strings = {},
					variables = {},
					numbers = {},
					booleans = {},
					properties = {},
					types = {},
					operators = {},
				},
				color_overrides = {},
				custom_highlights = {},

				-- Plugin integrations
				integrations = {
					cmp = true,
					gitsigns = true,
					nvimtree = true,
					treesitter = true,
					notify = false,

					-- LSP and diagnostics
					native_lsp = {
						enabled = true,
						virtual_text = {
							errors = { "italic" },
							hints = { "italic" },
							warnings = { "italic" },
							information = { "italic" },
							ok = { "italic" },
						},
						underlines = {
							errors = { "underline" },
							hints = { "underline" },
							warnings = { "underline" },
							information = { "underline" },
							ok = { "underline" },
						},
						inlay_hints = {
							background = true,
						},
					},

					-- UI enhancements
					telescope = { enabled = true, style = "nvchad_outlined" },
					which_key = true,

					-- Development tools
					mason = true,
					dap = true,
					dap_ui = true,

					-- Git integration
					diffview = true,
					neogit = true,

					-- Other integrations (only enable if you use these plugins)
					barbecue = {
						dim_dirname = true,
						bold_basename = true,
						dim_context = false,
						alt_background = false,
					},
					lsp_trouble = true,
					noice = true,
					ufo = true,
					rainbow_delimiters = true,
					render_markdown = true,
					overseer = true,
				},
			}

			-- Theme persistence logic - unified with Telescope config
			local theme_file = vim.fn.stdpath "data" .. "/nvim_colorscheme"

			-- Function to load saved colorscheme
			local function load_saved_colorscheme()
				local file = io.open(theme_file, "r")
				if file then
					local theme = file:read("*all"):gsub("%s+", "") -- Remove whitespace
					file:close()

					if theme and theme ~= "" then
						-- Validate that the theme exists
						local available_schemes = vim.fn.getcompletion("", "color")
						for _, scheme in ipairs(available_schemes) do
							if scheme == theme then
								vim.schedule(function()
									local success = pcall(vim.cmd.colorscheme, theme)
									if success then
										vim.g.colors_name = theme
									end
								end)
								return
							end
						end
					end
				end

				-- Fallback to default catppuccin theme
				vim.schedule(function()
					pcall(vim.cmd.colorscheme, "catppuccin-frappe")
					vim.g.colors_name = "catppuccin-frappe"
				end)
			end

			-- Load the saved theme or default
			load_saved_colorscheme()
		end,
	},
}
