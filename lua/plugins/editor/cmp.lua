return {
	{
		"saghen/blink.cmp",
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = { "rafamadriz/friendly-snippets" },
		--options: build
		-- build = "cargo build --release",
		version = "1.*",
		opts_extend = { "sources.default" },
		config = function()
			-- =================================
			-- Keymap configuration
			-- =================================
			local keymaps = {
				-- Insert mode keymaps
				insert = {
					["<C-space>"] = { "show", "show_documentation", "hide_documentation" },
					["<C-e>"] = { "hide" },
					["<CR>"] = { "accept", "fallback" },
					["<Up>"] = { "select_prev", "fallback" },
					["<Down>"] = { "select_next", "fallback" },
					["<C-b>"] = { "scroll_documentation_up", "fallback" },
					["<C-f>"] = { "scroll_documentation_down", "fallback" },
					["<Tab>"] = { "select_next", "snippet_forward", "fallback" },
					["<S-Tab>"] = { "select_prev", "snippet_backward", "fallback" },
					["<C-k>"] = { "show_signature", "hide_signature", "fallback" },
				},

				-- Cmdline mode keymaps
				cmdline = {
					["<Tab>"] = { "show_and_insert", "select_next" },
					["<S-Tab>"] = { "show_and_insert", "select_prev" },
					["<CR>"] = { "accept_and_enter", "fallback" },
				},
			}

			-- =================================
			-- Completion sources configuration
			-- =================================
			local sources = {
				-- Default completion sources
				default = { "lsp", "path", "snippets" },

				-- Custom completion source providers
				providers = {
					lsp = {
						module = "blink.cmp.sources.lsp",
						fallbacks = { "buffer" },
					},
					buffer = {
						module = "blink.cmp.sources.buffer",
						min_keyword_length = 3,
						max_items = 10,
						score_offset = -1,
					},
					snippets = {
						module = "blink.cmp.sources.snippets",
						min_keyword_length = 2,
						score_offset = -1,
					},
					markdown = {
						name = "RenderMarkdown",
						module = "render-markdown.integ.blink",
						fallbacks = { "lsp" },
					},
				},

				-- Filetype-specific completion sources
				per_filetype = {
					markdown = {
						inherit_defaults = true,
						"markdown",
					},
				},
			}

			-- =================================
			-- Disabled filetypes for completion
			-- =================================
			local disabled_filetypes = {
				"oil",
				"NvimTree",
				"DressingInput",
				"copilot-chat",
			}

			-- =================================
			-- Completion feature configuration
			-- =================================
			local completion_config = {
				-- Documentation configuration
				documentation = {
					auto_show = true,
				},

				-- Keyword matching configuration
				keyword = {
					range = "prefix", -- Changed to "prefix" to match only text before the cursor, potentially reducing irrelevant matches
				},

				-- List selection configuration
				list = {
					selection = {
						preselect = false, -- Changed to false to avoid auto-preselecting items
						auto_insert = false,
					},
				},

				-- Ghost text configuration
				ghost_text = {
					enabled = true,
				},
			}

			-- =================================
			-- Cmdline completion configuration
			-- =================================
			local cmdline_config = {
				completion = {
					list = {
						selection = {
							preselect = false,
							auto_insert = true,
						},
					},
				},
				keymap = keymaps.cmdline,
			}

			-- =================================
			-- Appearance configuration
			-- =================================
			local appearance_config = {
				nerd_font_variant = "mono",
			}

			-- =================================
			-- Enable condition function
			-- =================================
			local function is_enabled()
				return not vim.tbl_contains(disabled_filetypes, vim.bo.filetype)
			end

			-- =================================
			-- Main configuration
			-- =================================
			require("blink.cmp").setup {
				-- Keymap configuration
				keymap = vim.tbl_extend("force", { preset = "none" }, keymaps.insert),

				-- Enable condition
				enabled = is_enabled,

				-- Appearance configuration
				appearance = appearance_config,

				-- Signature configuration
				signature = { enabled = true },

				-- Cmdline configuration
				cmdline = cmdline_config,

				-- Completion feature configuration
				completion = completion_config,

				-- Completion sources configuration
				sources = sources,

				-- Fuzzy matching engine
				fuzzy = {
					implementation = "prefer_rust_with_warning",
				},
			}
		end,
	},
}
