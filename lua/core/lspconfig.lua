local M = {}

local function setup_diagnostics()
	local s = vim.diagnostic.severity
	vim.diagnostic.config {
		virtual_text = {
			spacing = 4,
			source = "if_many",
			prefix = function(diag)
				local map = {
					[s.ERROR] = "󰅚 ",
					[s.WARN] = " ",
					[s.INFO] = " ",
					[s.HINT] = "󰌶 ",
				}
				return map[diag.severity] or "● "
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

	vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
		border = "rounded",
		max_width = 80,
		max_height = 20,
	})
	vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
		border = "rounded",
		max_width = 80,
		max_height = 20,
	})
end

local function make_on_attach()
	return function(client, bufnr)
		local function map(m, lhs, rhs, desc)
			vim.keymap.set(m, lhs, rhs, { buffer = bufnr, silent = true, noremap = true, desc = desc })
		end
		map("n", "K", vim.lsp.buf.hover, "LSP: Hover")
		map("n", "gd", vim.lsp.buf.definition, "LSP: Goto Definition")
		map("n", "gD", vim.lsp.buf.declaration, "LSP: Goto Declaration")
		map("n", "gi", vim.lsp.buf.implementation, "LSP: Goto Implementation")
		map("n", "gr", vim.lsp.buf.references, "LSP: References")
		map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "LSP: Code Action")
		map("n", "<leader>cr", vim.lsp.buf.rename, "LSP: Rename")
		map("n", "<leader>cf", function()
			vim.lsp.buf.format { async = true }
		end, "LSP: Format")

		if client.server_capabilities.inlayHintProvider then
			vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
			map("n", "<leader>li", function()
				local enabled = vim.lsp.inlay_hint.is_enabled { bufnr = bufnr }
				vim.lsp.inlay_hint.enable(not enabled, { bufnr = bufnr })
			end, "LSP: Toggle Inlay Hints")
		end

		map("n", "<leader>ld", function()
			if vim.b._diag_disabled then
				vim.b._diag_disabled = false
				vim.diagnostic.enable(bufnr)
			else
				vim.b._diag_disabled = true
				vim.diagnostic.disable(bufnr)
			end
		end, "LSP: Toggle Diagnostics")

		if client.server_capabilities.documentHighlightProvider then
			local aug = vim.api.nvim_create_augroup("lsp_document_highlight_" .. bufnr, { clear = true })
			vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
				group = aug,
				buffer = bufnr,
				callback = vim.lsp.buf.document_highlight,
			})
			vim.api.nvim_create_autocmd("CursorMoved", {
				group = aug,
				buffer = bufnr,
				callback = vim.lsp.buf.clear_references,
			})
		end

		if client.name == "texlab" then
			map("n", "<leader>lb", function()
				vim.lsp.buf.execute_command { command = "texlab.build" }
			end, "LaTeX: Build")
			map("n", "<leader>lv", function()
				vim.lsp.buf.execute_command { command = "texlab.forwardSearch" }
			end, "LaTeX: Forward Search")
		end
	end
end

local function get_caps()
	local ok, blink = pcall(require, "blink.cmp")
	if ok and blink and blink.get_lsp_capabilities then
		return blink.get_lsp_capabilities()
	end
	return vim.lsp.protocol.make_client_capabilities()
end

local function setup_servers()
	local caps = get_caps()
	local on_attach = make_on_attach()

	vim.lsp.config("*", {
		capabilities = caps,
		on_attach = on_attach,
	})

	-- clangd
	vim.lsp.config("clangd", {
		cmd = { "clangd", "--background-index", "--clang-tidy", "--completion-style=detailed" },
		filetypes = { "c", "cpp", "objc", "objcpp" },
		root_markers = { { ".clangd", "compile_commands.json", "compile_flags.txt" }, ".git" },
		-- single_file_support = false,
	})

	-- pyright
	vim.lsp.config("pyright", {
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
	})

	-- lua_ls
	vim.lsp.config("lua_ls", {
		cmd = { "lua-language-server" },
		filetypes = { "lua" },
		root_markers = { { ".luarc.json", ".luarc.jsonc" }, ".git" },
		settings = {
			Lua = {
				runtime = { version = "LuaJIT" },
				diagnostics = { globals = { "vim" }, disable = { "missing-fields" } },
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
	})

	-- marksman
	vim.lsp.config("marksman", {
		cmd = { "marksman" },
		filetypes = { "markdown" },
		root_markers = { ".git" },
	})

	-- texlab
	vim.lsp.config("texlab", {
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
	})

	vim.lsp.enable { "clangd", "pyright", "lua_ls", "marksman", "texlab" }

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
end

return M
