local M = {}

-- ============================================================================
-- Diagnostics
-- ============================================================================
local function setup_diagnostics()
	local s = vim.diagnostic.severity

	vim.diagnostic.config({
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
	})

	vim.opt.signcolumn = "yes"
	vim.opt.updatetime = 250
	vim.o.winborder = "rounded"
	vim.lsp.log.set_level(vim.log.levels.WARN)
end

-- ============================================================================
-- Capabilities / on_attach
-- ============================================================================
local function get_capabilities()
	local ok, blink = pcall(require, "blink.cmp")
	if ok and blink and blink.get_lsp_capabilities then
		local caps = blink.get_lsp_capabilities()
		caps.textDocument = caps.textDocument or {}
		caps.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
		return caps
	end

	local caps = vim.lsp.protocol.make_client_capabilities()
	caps.textDocument = caps.textDocument or {}
	caps.textDocument.foldingRange = { dynamicRegistration = false, lineFoldingOnly = true }
	return caps
end

local function enable_builtin_completion(client, bufnr)
	local ok_blink = pcall(require, "blink.cmp")
	if ok_blink or not client:supports_method("textDocument/completion") then
		return
	end
	pcall(vim.lsp.completion.enable, true, client.id, bufnr, { autotrigger = true })
end

local function setup_document_highlight(client, bufnr)
	if not client:supports_method("textDocument/documentHighlight") then
		return
	end

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

local function setup_inlay_hints(client, bufnr)
	if vim.lsp.inlay_hint and client:supports_method("textDocument/inlayHint") then
		vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
		return true
	end
	return false
end

local function make_on_attach()
	return function(client, bufnr)
		enable_builtin_completion(client, bufnr)
		local has_inlay_hints = setup_inlay_hints(client, bufnr)
		setup_document_highlight(client, bufnr)

		local ok_keys, keys = pcall(require, "core.keymaps")
		if ok_keys and keys.lsp then
			keys.lsp(bufnr, {
				supports_inlay_hints = has_inlay_hints,
				client_name = client.name,
				client_id = client.id,
			})
		end
	end
end

-- ============================================================================
-- Servers
-- ============================================================================
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
			root_markers = {
				{ "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt" },
				".git",
			},
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

-- ============================================================================
-- Extras
-- ============================================================================
local function setup_ufo()
	local ok, ufo = pcall(require, "ufo")
	if not ok then
		return
	end

	vim.o.foldcolumn = "1"
	vim.o.foldlevel = 99
	vim.o.foldlevelstart = 99
	vim.o.foldenable = true

	ufo.setup({
		provider_selector = function(_, _ft, _bt)
			return { "lsp", "treesitter", "indent" }
		end,
		open_fold_hl_timeout = 150,
		preview = {
			win_config = { border = "rounded", winblend = 12, maxheight = 20 },
		},
		fold_virt_text_handler = function(virtText, lnum, endLnum, width, truncate)
			local newVirtText, curWidth = {}, 0
			local suffix = (" 󰁂 %d "):format(endLnum - lnum)
			local sufWidth = vim.fn.strdisplaywidth(suffix)
			local targetWidth = width - sufWidth
			for _, chunk in ipairs(virtText) do
				local text, hl = chunk[1], chunk[2]
				local w = vim.fn.strdisplaywidth(text)
				if targetWidth > curWidth + w then
					table.insert(newVirtText, { text, hl })
				else
					text = truncate(text, targetWidth - curWidth)
					table.insert(newVirtText, { text, hl })
					w = vim.fn.strdisplaywidth(text)
					if curWidth + w < targetWidth then
						suffix = suffix .. string.rep(" ", targetWidth - curWidth - w)
					end
					break
				end
				curWidth = curWidth + w
			end
			table.insert(newVirtText, { suffix, "MoreMsg" })
			return newVirtText
		end,
	})

	vim.keymap.set("n", "zR", ufo.openAllFolds, { desc = "UFO: Open all folds" })
	vim.keymap.set("n", "zM", ufo.closeAllFolds, { desc = "UFO: Close all folds" })
	vim.keymap.set(
		"n",
		"zp",
		ufo.peekFoldedLinesUnderCursor,
		{ desc = "UFO: Preview folded lines" }
	)
	vim.keymap.set("n", "zr", function()
		ufo.openFoldsExceptKinds({ "comment", "imports" })
	end, { desc = "UFO: Open folds except comments/imports" })
	vim.keymap.set("n", "zm", function()
		ufo.closeFoldsWith(1)
	end, { desc = "UFO: Close one fold level" })
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

-- ============================================================================
-- Public API
-- ============================================================================
function M.setup()
	setup_diagnostics()
	setup_servers()
	setup_ufo()
	setup_commands()
end

return M
