local M = {}

local function setup_diagnostics()
	local s = vim.diagnostic.severity
	vim.diagnostic.config {
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
		signs = true,
		underline = true,
		update_in_insert = false,
		severity_sort = true,
		float = {
			focusable = false,
			style = "minimal",
			border = "rounded",
			source = "always",
			header = "",
			prefix = "",
			max_width = 80,
			max_height = 20,
		},
	}

	vim.opt.signcolumn = "yes"
	vim.opt.updatetime = 250
	vim.lsp.set_log_level "WARN"

	local float_config = { border = "rounded", max_width = 80, max_height = 20 }
	vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, float_config)
	vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, float_config)
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

	map("n", "K", vim.lsp.buf.hover, "Hover")
	map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
	map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
	map("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")
	map("n", "gr", vim.lsp.buf.references, "References")

	map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code Action")
	map("n", "<leader>cr", vim.lsp.buf.rename, "Rename")
	map("n", "<leader>cf", function()
		vim.lsp.buf.format { async = true }
	end, "Format")

	map("n", "<leader>ld", function()
		local current_buf = vim.api.nvim_get_current_buf()
		if vim.b[current_buf]._diag_disabled then
			vim.b[current_buf]._diag_disabled = false
			vim.diagnostic.enable(true, { bufnr = current_buf })
		else
			vim.b[current_buf]._diag_disabled = true
			vim.diagnostic.enable(false, { bufnr = current_buf })
		end
	end, "Toggle Diagnostics")
end

local function make_on_attach()
	return function(client, bufnr)
		setup_keymaps(bufnr)

		-- Inlay hints
		if client.server_capabilities.inlayHintProvider then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			vim.keymap.set("n", "<leader>li", function()
				local enabled = vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }
				vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
			end, { buffer = bufnr, desc = "LSP: Toggle Inlay Hints" })
		end

		-- 文档高亮
		if client.server_capabilities.documentHighlightProvider then
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
					vim.lsp.buf.execute_command { command = cmd }
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

	for name, config in pairs(servers) do
		vim.lsp.config(name, config)
	end

	vim.lsp.enable(vim.tbl_keys(servers))
end

local function setup_commands()
	vim.api.nvim_create_user_command("LspRestart", function()
		vim.cmd "LspStop"
		vim.defer_fn(function()
			vim.cmd "LspStart"
		end, 300)
	end, { desc = "Restart LSP servers" })

	vim.api.nvim_create_user_command("LspLog", function()
		vim.cmd("edit " .. vim.lsp.get_log_path())
	end, { desc = "Open LSP log file" })
end

function M.setup()
	setup_diagnostics()
	setup_servers()
	setup_commands()
end

return M
