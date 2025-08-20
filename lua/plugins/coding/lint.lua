return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require "lint"

		lint.linters_by_ft = {
			c = { "cpplint" },
			cpp = { "cpplint" },
			python = { "ruff" },
			lua = { "luacheck" },
			markdown = { "markdownlint" },
		}

		if lint.linters.luacheck then
			lint.linters.luacheck.args = vim.list_extend(lint.linters.luacheck.args or {}, {
				"--globals",
				"vim",
				"--max-line-length",
				"120",
			})
		end

		if lint.linters.ruff then
			lint.linters.ruff.args = vim.list_extend(lint.linters.ruff.args or {}, {
				"--select",
				"E,W,F,I,N,UP,YTT,ASYNC,S,BLE,FBT,B,A,COM,C4,DTZ,T10,DJ,EM,EXE,FA,ISC,ICN,G,INP,PIE,T20,PYI,PT,Q,RSE,RET,SLF,SLOT,SIM,TID,TCH,INT,ARG,PTH,TD,FIX,ERA,PD,PGH,PL,TRY,FLY,NPY,AIR,PERF,FURB,LOG,RUF",
				"--line-length",
				"100",
				"--ignore",
				"E501,W503,E203",
			})
		end

		local function file_too_big(buf)
			local name = vim.api.nvim_buf_get_name(buf)
			local ok, st = pcall(vim.loop.fs_stat, name)
			return ok and st and st.size and st.size > 1024 * 1024
		end

		local function try_lint()
			if vim.g.lint_enabled == false then
				return
			end
			if file_too_big(0) then
				return
			end
			lint.try_lint()
		end

		local aug = vim.api.nvim_create_augroup("NvimLintCfg", { clear = true })
		vim.api.nvim_create_autocmd({ "BufWritePost", "BufEnter", "InsertLeave" }, {
			group = aug,
			callback = try_lint,
			desc = "Run linters on key lifecycle events",
		})

		vim.keymap.set("n", "<leader>ll", function()
			lint.try_lint()
		end, { desc = "Lint current buffer", silent = true })

		vim.keymap.set("n", "<leader>lt", function()
			local enabled = vim.g.lint_enabled ~= false
			vim.g.lint_enabled = not enabled
			if enabled then
				vim.diagnostic.reset(require("lint").get_namespace())
				vim.notify("🚫 Linting disabled", vim.log.levels.INFO, { title = "nvim-lint" })
			else
				try_lint()
				vim.notify("✅ Linting enabled", vim.log.levels.INFO, { title = "nvim-lint" })
			end
		end, { desc = "Toggle linting", silent = true })

		vim.api.nvim_create_user_command("LintStatus", function()
			local ft = vim.bo.filetype
			local list = lint.linters_by_ft[ft] or {}
			vim.notify(
				("Linting: %s\nFiletype: %s\nLinters: %s"):format(
					vim.g.lint_enabled == false and "Disabled" or "Enabled",
					ft,
					(#list > 0 and table.concat(list, ", ") or "None")
				),
				vim.log.levels.INFO,
				{ title = "nvim-lint" }
			)
		end, {})
	end,
}
