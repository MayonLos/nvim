local M = {}

local function setup_diagnostics()
	local s = vim.diagnostic.severity

	vim.diagnostic.config {
		signs = {
			text = {
				[s.ERROR] = "󰅚",
				[s.WARN] = "",
				[s.INFO] = "",
				[s.HINT] = "󰌶",
			},
			numhl = {
				[s.ERROR] = "DiagnosticSignError",
				[s.WARN] = "DiagnosticSignWarn",
				[s.INFO] = "DiagnosticSignInfo",
				[s.HINT] = "DiagnosticSignHint",
			},
		},
		virtual_text = {
			spacing = 4,
			source = "if_many",
			prefix = function(diag)
				local icons = {
					[s.ERROR] = "󰅚 ",
					[s.WARN] = " ",
					[s.INFO] = " ",
					[s.HINT] = "󰌶 ",
				}
				return icons[diag.severity] or "● "
			end,
		},
		underline = true,
		update_in_insert = false,
		severity_sort = true,
		float = {
			focusable = false,
			header = "",
			prefix = "",
			max_width = 80,
			max_height = 20,
		},
	}

	vim.opt.signcolumn = "yes"
	vim.opt.updatetime = 250

	vim.o.winborder = "rounded"

	vim.lsp.log.set_level(vim.log.levels.WARN)
end

local function setup_keymaps(bufnr)
	local function map(mode, lhs, rhs, desc)
		vim.keymap.set(mode, lhs, rhs, {
			buffer = bufnr,
			silent = true,
			noremap = true,
			desc = "LSP: " .. desc,
		})
	end

	map("n", "K", function()
		vim.lsp.buf.hover { focusable = false, max_width = 80, max_height = 20 }
	end, "Hover")

	map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
	map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
	map("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
	map("n", "gr", vim.lsp.buf.references, "References")

	map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
	map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")

	map("n", "<leader>cf", function()
		vim.lsp.buf.format { async = true, timeout_ms = 1500 }
	end, "Format")

	map("n", "<leader>ld", function()
		local b = vim.api.nvim_get_current_buf()
		local disabled = vim.b[b]._diag_disabled
		vim.b[b]._diag_disabled = not disabled
		vim.diagnostic.enable(not disabled, { bufnr = b })
	end, "Toggle Diagnostics")
end

local function make_on_attach()
	return function(client, bufnr)
		setup_keymaps(bufnr)

		local ok_blink = pcall(require, "blink.cmp")
		if (not ok_blink) and client:supports_method "textDocument/completion" then
			vim.lsp.completion.enable(true, client.id, bufnr, { autotrigger = true })
		end

		if client:supports_method "textDocument/inlayHint" then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			vim.keymap.set("n", "<leader>li", function()
				local enabled = vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }
				vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
			end, { buffer = bufnr, desc = "LSP: Toggle Inlay Hints" })
		end

		if client:supports_method "textDocument/documentHighlight" then
			local group = vim.api.nvim_create_augroup("lsp_document_highlight_" .. bufnr, { clear = true })
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				group = group,
				buffer = bufnr,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd("CursorMoved", {
				group = group,
				buffer = bufnr,
				callback = vim.lsp.buf.clear_references,
			})
		end

		if client.name == "texlab" then
			local function tex_map(lhs, cmd, desc)
				vim.keymap.set("n", lhs, function()
					client:exec_cmd({ command = cmd }, { bufnr = bufnr })
				end, { buffer = bufnr, desc = "LaTeX: " .. desc })
			end
			tex_map("<leader>lb", "texlab.build", "Build")
			tex_map("<leader>lv", "texlab.forwardSearch", "Forward Search")
		end
	end
end

local function get_capabilities()
	local ok, blink = pcall(require, "blink.cmp")
	if ok and blink and blink.get_lsp_capabilities then
		return blink.get_lsp_capabilities()
	end
	return vim.lsp.protocol.make_client_capabilities()
end

local function setup_servers()
	local capabilities = get_capabilities()
	local on_attach = make_on_attach()

	vim.lsp.config("*", {
		capabilities = capabilities,
		on_attach = on_attach,
	})

	local servers = {
		clangd = {
			cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed" },
			filetypes = { "c", "cpp", "objc", "objcpp" },
			root_markers = { { ".clangd", "compile_commands.json", "compile_flags.txt" }, ".git" },
		},

		pyright = {
			cmd = { "pyright-langserver", "--stdio" },
			filetypes = { "python" },
			root_markers = { { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt" }, ".git" },
			settings = {
				python = {
					analysis = {
						typeCheckingMode = "basic",
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
						autoImportCompletions = true,
					},
				},
			},
		},

		lua_ls = {
			cmd = { "lua-language-server" },
			filetypes = { "lua" },
			root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" },
			settings = {
				Lua = {
					runtime = { version = "LuaJIT" },
					diagnostics = {
						globals = { "vim" },
						disable = { "missing-fields" },
					},
					workspace = {
						library = vim.api.nvim_get_runtime_file("", true),
						checkThirdParty = false,
						maxPreload = 100000,
						preloadFileSize = 10000,
					},
					telemetry = { enable = false },
					hint = { enable = true, arrayIndex = "Disable" },
					format = { enable = false },
				},
			},
		},

		marksman = {
			cmd = { "marksman" },
			filetypes = { "markdown" },
			root_markers = { ".git" },
		},

		texlab = {
			cmd = { "texlab" },
			filetypes = { "tex", "bib" },
			root_markers = { ".git" },
			settings = {
				texlab = {
					build = {
						executable = "latexmk",
						args = { "-pdf", "-interaction=nonstopmode", "-synctex=1", "%f" },
						onSave = false,
					},
					forwardSearch = {
						executable = "zathura",
						args = { "--synctex-forward", "%l:1:%f", "%p" },
					},
					chktex = { onOpenAndSave = true, onEdit = false },
				},
			},
		},
	}

	for name, cfg in pairs(servers) do
		vim.lsp.config(name, cfg)
	end

	M._server_names = vim.tbl_keys(servers)

	vim.lsp.enable(M._server_names)
end

local function setup_commands()
	vim.api.nvim_create_user_command("LspRestart", function()
		vim.lsp.stop_client(vim.lsp.get_clients())
		vim.cmd.edit()
	end, { desc = "Restart LSP clients for current buffer" })

	vim.api.nvim_create_user_command("LspLog", function()
		vim.cmd("edit " .. require("vim.lsp.log").get_filename())
	end, { desc = "Open LSP log file" })
end

function M.setup()
	setup_diagnostics()
	setup_servers()
	setup_commands()
end

return M
