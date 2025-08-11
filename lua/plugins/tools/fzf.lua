return {
	"ibhagwan/fzf-lua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	event = "VimEnter",
	config = function()
		local fzf_lua = require "fzf-lua"
		local actions = fzf_lua.actions

		-- Common preview options
		local preview_opts = {
			border = "rounded",
			wrap = false,
			hidden = "no",
			vertical = "down:45%",
			horizontal = "right:60%",
			layout = "vertical",
			flip_columns = 120,
			title = true,
			title_pos = "center",
			scrollbar = "border",
			delay = 50,
			winopts = {
				number = true,
				relativenumber = false,
				cursorline = true,
				cursorlineopt = "both",
				signcolumn = "no",
				list = false,
				foldenable = false,
			},
		}

		-- Common file settings
		local file_opts = {
			multiprocess = true,
			git_icons = true,
			file_icons = true,
			color_icons = true,
		}

		-- Common grep settings
		local grep_opts = {
			multiprocess = true,
			git_icons = true,
			file_icons = true,
			color_icons = true,
			rg_opts = "--column --line-number --no-heading --color=always --smart-case --hidden --follow -g '!.git' -g '!node_modules' -g '!.DS_Store'",
		}

		-- Common exclude patterns
		local excludes = "-g '!.git' -g '!node_modules' -g '!.DS_Store'"

		fzf_lua.setup {
			"fzf-native",
			file_icon_padding = " ",
			winopts = {
				height = 0.85,
				width = 0.80,
				row = 0.35,
				col = 0.50,
				border = "rounded",
				backdrop = 60,
				fullscreen = false,
				preview = preview_opts,
				treesitter = {
					enabled = true,
					fzf_colors = { ["hl"] = "-1:reverse", ["hl+"] = "-1:reverse" },
				},
			},
			keymap = {
				builtin = {
					["<M-Esc>"] = "hide",
					["<F1>"] = "toggle-help",
					["<F2>"] = "toggle-fullscreen",
					["<F3>"] = "toggle-preview-wrap",
					["<F4>"] = "toggle-preview",
					["<C-u>"] = "preview-page-up",
					["<C-d>"] = "preview-page-down",
				},
				fzf = {
					["ctrl-z"] = "abort",
					["ctrl-u"] = "unix-line-discard",
					["ctrl-f"] = "half-page-down",
					["ctrl-b"] = "half-page-up",
					["ctrl-a"] = "beginning-of-line",
					["ctrl-e"] = "end-of-line",
					["alt-a"] = "toggle-all",
					["ctrl-q"] = "select-all+accept",
				},
			},
			fzf_opts = {
				["--ansi"] = true,
				["--info"] = "inline-right",
				["--height"] = "100%",
				["--layout"] = "reverse",
				["--border"] = "none",
				["--highlight-line"] = true,
				["--no-scrollbar"] = true,
				["--bind"] = "change:reload:sleep 0.01",
			},
			fzf_colors = true,

			-- File finders
			files = vim.tbl_extend("force", {
				prompt = "Files❯ ",
				cmd = "fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude .DS_Store",
				find_opts = [[-type f -not -path '*/\.git/*' -not -name '*.pyc' -not -name '*.o']],
				rg_opts = "--color=never --files --hidden --follow " .. excludes,
				fd_opts = "--color=never --type f --hidden --follow --exclude .git --exclude node_modules --exclude .DS_Store",
				cwd_prompt = true,
				cwd_prompt_shorten_len = 32,
				actions = {
					["enter"] = actions.file_edit_or_qf,
					["ctrl-s"] = actions.file_split,
					["ctrl-v"] = actions.file_vsplit,
					["ctrl-t"] = actions.file_tabedit,
					["alt-q"] = actions.file_sel_to_qf,
					["alt-l"] = actions.file_sel_to_ll,
				},
			}, file_opts),

			-- Grep commands
			grep = vim.tbl_extend("force", {
				prompt = "Rg❯ ",
				input_prompt = "Grep For❯ ",
				rg_glob = true,
				glob_flag = "--iglob",
				glob_separator = "%s%-%-",
				actions = {
					["ctrl-g"] = { actions.grep_lgrep },
				},
			}, grep_opts),

			live_grep = vim.tbl_extend("force", {
				prompt = "LiveGrep❯ ",
				multiline = 2,
			}, grep_opts),

			-- Buffer management
			buffers = {
				prompt = "Buffers❯ ",
				file_icons = true,
				color_icons = true,
				sort_lastused = true,
				show_unloaded = true,
				cwd_only = false,
				actions = {
					["ctrl-x"] = { fn = actions.buf_del, reload = true },
				},
			},

			-- LSP commands
			lsp = {
				prompt_postfix = "❯ ",
				cwd_only = false,
				async_or_timeout = 5000,
				file_icons = true,
				git_icons = false,
				jump1 = true,
				includeDeclaration = true,
				symbols = {
					async_or_timeout = true,
					symbol_style = 1,
					symbol_fmt = function(s, _)
						return "[" .. s .. "]"
					end,
				},
				code_actions = {
					prompt = "Code Actions❯ ",
					async_or_timeout = 5000,
					previewer = "codeaction",
				},
			},

			diagnostics = {
				prompt = "Diagnostics❯ ",
				cwd_only = false,
				file_icons = true,
				git_icons = false,
				diag_icons = true,
				diag_source = true,
				icon_padding = " ",
				multiline = 2,
			},

			-- Git commands
			git = {
				files = vim.tbl_extend("force", {
					prompt = "GitFiles❯ ",
					cmd = "git ls-files --exclude-standard",
				}, file_opts),

				status = {
					prompt = "GitStatus❯ ",
					multiprocess = true,
					file_icons = true,
					color_icons = true,
					previewer = "git_diff",
					actions = {
						["right"] = { fn = actions.git_unstage, reload = true },
						["left"] = { fn = actions.git_stage, reload = true },
						["ctrl-x"] = { fn = actions.git_reset, reload = true },
					},
				},

				commits = {
					prompt = "Commits❯ ",
					preview = "git show --color {1}",
					actions = {
						["enter"] = actions.git_checkout,
						["ctrl-y"] = { fn = actions.git_yank_commit, exec_silent = true },
					},
				},

				branches = {
					prompt = "Branches❯ ",
					cmd = "git branch --all --color",
					preview = "git log --graph --pretty=oneline --abbrev-commit --color {1}",
					actions = {
						["enter"] = actions.git_switch,
						["ctrl-x"] = { fn = actions.git_branch_del, reload = true },
					},
				},
			},

			-- History and navigation
			oldfiles = {
				prompt = "History❯ ",
				cwd_only = false,
				stat_file = true,
				include_current_session = false,
			},

			lines = {
				prompt = "Lines❯ ",
				show_unlisted = false,
				no_term_buffers = true,
				fzf_opts = {
					["--delimiter"] = "[\t]",
					["--nth"] = "4..",
					["--tabstop"] = "4",
					["--tiebreak"] = "index",
				},
			},

			-- Help and configuration
			helptags = {
				prompt = "Help❯ ",
			},

			colorschemes = {
				prompt = "Colorschemes❯ ",
				live_preview = true,
				actions = { ["enter"] = actions.colorscheme },
				winopts = { height = 0.55, width = 0.30 },
			},

			keymaps = {
				prompt = "Keymaps❯ ",
				winopts = { preview = { layout = "vertical" } },
				fzf_opts = { ["--tiebreak"] = "index" },
			},

			-- Miscellaneous
			quickfix = {
				prompt = "Quickfix❯ ",
				file_icons = true,
			},

			marks = {
				prompt = "Marks❯ ",
			},

			jumps = {
				prompt = "Jumps❯ ",
			},

			global = {
				prompt = "Global❯ ",
			},

			previewers = {
				builtin = {
					syntax = true,
					syntax_limit_l = 0,
					syntax_limit_b = 1024 * 1024,
					limit_b = 1024 * 1024 * 10,
					treesitter = {
						enabled = true,
						context = { max_lines = 3, trim_scope = "inner" },
					},
					extensions = {
						["png"] = { "chafa", "{file}" },
						["jpg"] = { "chafa", "{file}" },
						["jpeg"] = { "chafa", "{file}" },
						["gif"] = { "chafa", "{file}" },
						["svg"] = { "chafa", "{file}" },
					},
				},
			},
		}

		-- Register UI select
		fzf_lua.register_ui_select()

		-- Define keymap function with defaults
		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { silent = true, noremap = true, desc = desc })
		end

		-- File navigation
		map("n", "<leader>ff", "<cmd>FzfLua files<cr>", "Find Files")
		map("n", "<leader>fr", "<cmd>FzfLua oldfiles<cr>", "Recent Files")
		map("n", "<leader>fb", "<cmd>FzfLua buffers<cr>", "Find Buffers")
		map("n", "<leader>fg", "<cmd>FzfLua git_files<cr>", "Git Files")

		-- Searching
		map("n", "<leader>fw", "<cmd>FzfLua live_grep<cr>", "Live Grep")
		map("n", "<leader>fW", "<cmd>FzfLua grep_cWORD<cr>", "Grep Current WORD")
		map("n", "<leader>fc", "<cmd>FzfLua grep_curbuf<cr>", "Grep Current Buffer")
		map("v", "<leader>fv", "<cmd>FzfLua grep_visual<cr>", "Grep Visual Selection")

		-- LSP features
		map("n", "<leader>fd", "<cmd>FzfLua lsp_definitions<cr>", "LSP Definitions")
		map("n", "<leader>fD", "<cmd>FzfLua lsp_declarations<cr>", "LSP Declarations")
		map("n", "<leader>fR", "<cmd>FzfLua lsp_references<cr>", "LSP References")
		map("n", "<leader>fi", "<cmd>FzfLua lsp_implementations<cr>", "LSP Implementations")
		map("n", "<leader>ft", "<cmd>FzfLua lsp_typedefs<cr>", "LSP Type Definitions")
		map("n", "<leader>fS", "<cmd>FzfLua lsp_document_symbols<cr>", "Document Symbols")
		map("n", "<leader>fs", "<cmd>FzfLua lsp_workspace_symbols<cr>", "Workspace Symbols")
		map("n", "<leader>fa", "<cmd>FzfLua lsp_code_actions<cr>", "Code Actions")
		map("n", "<leader>fe", "<cmd>FzfLua diagnostics_document<cr>", "Document Diagnostics")
		map("n", "<leader>fE", "<cmd>FzfLua diagnostics_workspace<cr>", "Workspace Diagnostics")
		map("n", "<leader>fF", "<cmd>FzfLua lsp_finder<cr>", "LSP Finder")

		-- Git commands
		map("n", "<leader>fgs", "<cmd>FzfLua git_status<cr>", "Git Status")
		map("n", "<leader>fgc", "<cmd>FzfLua git_commits<cr>", "Git Commits")
		map("n", "<leader>fgb", "<cmd>FzfLua git_bcommits<cr>", "Git Buffer Commits")
		map("n", "<leader>fgl", "<cmd>FzfLua git_blame<cr>", "Git Blame")
		map("n", "<leader>fgr", "<cmd>FzfLua git_branches<cr>", "Git Branches")
		map("n", "<leader>fgt", "<cmd>FzfLua git_tags<cr>", "Git Tags")
		map("n", "<leader>fgh", "<cmd>FzfLua git_stash<cr>", "Git Stash")

		-- Helpers and utilities
		map("n", "<leader>fh", "<cmd>FzfLua helptags<cr>", "Help Tags")
		map("n", "<leader>fm", "<cmd>FzfLua manpages<cr>", "Man Pages")
		map("n", "<leader>fk", "<cmd>FzfLua keymaps<cr>", "Keymaps")
		map("n", "<leader>fC", "<cmd>FzfLua colorschemes<cr>", "Colorschemes")
		map("n", "<leader>fj", "<cmd>FzfLua jumps<cr>", "Jump List")
		map("n", "<leader>fM", "<cmd>FzfLua marks<cr>", "Marks")
		map("n", "<leader>fq", "<cmd>FzfLua quickfix<cr>", "Quickfix List")
		map("n", "<leader>fl", "<cmd>FzfLua loclist<cr>", "Location List")
		map("n", "<leader>fo", "<cmd>FzfLua resume<cr>", "Resume Last")
		map("n", "<leader>fB", "<cmd>FzfLua builtin<cr>", "Builtin Commands")
		map("n", "<leader>fp", "<cmd>FzfLua global<cr>", "Global Picker")
		map("n", "<leader>fP", "<cmd>FzfLua profiles<cr>", "Profiles")
		map("n", "<leader>f:", "<cmd>FzfLua commands<cr>", "Commands")
		map("n", "<leader>f/", "<cmd>FzfLua search_history<cr>", "Search History")
		map("n", "<leader>f;", "<cmd>FzfLua command_history<cr>", "Command History")
		map("n", "<leader>fz", "<cmd>FzfLua spell_suggest<cr>", "Spell Suggestions")
		map("n", "<leader>fL", "<cmd>FzfLua lines<cr>", "Lines (All Buffers)")
		map("n", "<leader>f.", "<cmd>FzfLua blines<cr>", "Lines (Current Buffer)")
		map("n", "<leader>fT", "<cmd>FzfLua tabs<cr>", "Tabs")
		map("n", "<leader>fts", "<cmd>FzfLua treesitter<cr>", "Treesitter Symbols")
	end,
}
