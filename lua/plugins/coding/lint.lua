return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require "lint"

		-- Configure linters only for languages you use
		lint.linters_by_ft = {
			c = { "cpplint" },
			cpp = { "cpplint" },
			python = { "ruff" }, -- Use ruff for both linting and formatting
			lua = { "luacheck" },
			markdown = { "markdownlint" },
		}

		-- Configure specific linters
		lint.linters.luacheck.args = vim.list_extend(lint.linters.luacheck.args, {
			"--globals",
			"vim", -- Recognize vim as global
			"--max-line-length",
			"120", -- Match your formatting settings
		})

		-- Configure ruff linter for Python
		if lint.linters.ruff then
			lint.linters.ruff.args = vim.list_extend(lint.linters.ruff.args or {}, {
				"--select",
				"E,W,F,I,N,UP,YTT,ASYNC,S,BLE,FBT,B,A,COM,C4,DTZ,T10,DJ,EM,EXE,FA,ISC,ICN,G,INP,PIE,T20,PYI,PT,Q,RSE,RET,SLF,SLOT,SIM,TID,TCH,INT,ARG,PTH,TD,FIX,ERA,PD,PGH,PL,TRY,FLY,NPY,AIR,PERF,FURB,LOG,RUF",
				"--line-length",
				"100",
				"--ignore",
				"E501,W503,E203", -- Ignore some formatting conflicts
			})
		end

		-- Debounced lint function for better performance
		local lint_timer = nil
		local function lint_debounced()
			if lint_timer then
				vim.fn.timer_stop(lint_timer)
			end
			lint_timer = vim.fn.timer_start(300, function() -- Slightly longer delay
				lint.try_lint()
				lint_timer = nil
			end)
		end

		-- Immediate lint function
		local function lint_now()
			lint.try_lint()
		end

		-- Create autocommand group
		local group = vim.api.nvim_create_augroup("LintConfig", { clear = true })

		-- Lint on save (immediate)
		vim.api.nvim_create_autocmd("BufWritePost", {
			group = group,
			callback = lint_now,
			desc = "Lint on save",
		})

		-- Lint when leaving insert mode (immediate)
		vim.api.nvim_create_autocmd("InsertLeave", {
			group = group,
			callback = lint_now,
			desc = "Lint on insert leave",
		})

		-- Lint on text changes (debounced to avoid performance issues)
		vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
			group = group,
			callback = lint_debounced,
			desc = "Lint on text changes (debounced)",
		})

		-- Lint when entering buffer
		vim.api.nvim_create_autocmd("BufEnter", {
			group = group,
			callback = function()
				-- Only lint if buffer has been modified or is new
				if vim.bo.modified or vim.fn.line "$" == 1 and vim.fn.getline(1) == "" then
					lint_now()
				end
			end,
			desc = "Lint when entering buffer",
		})

		-- Enhanced keymaps with better descriptions
		vim.keymap.set("n", "<leader>ll", lint_now, {
			desc = "Lint current buffer now",
			silent = true,
		})

		-- Toggle linting with better status reporting
		vim.keymap.set("n", "<leader>lt", function()
			local enabled = vim.g.lint_enabled ~= false
			vim.g.lint_enabled = not enabled

			if enabled then
				-- Clear existing lint diagnostics
				vim.diagnostic.reset(vim.api.nvim_create_namespace "nvim-lint")
				vim.notify("🚫 Linting disabled", vim.log.levels.INFO, { title = "nvim-lint" })
			else
				lint_now()
				vim.notify("✅ Linting enabled", vim.log.levels.INFO, { title = "nvim-lint" })
			end
		end, {
			desc = "Toggle linting on/off",
			silent = true,
		})

		-- Status command
		vim.api.nvim_create_user_command("LintStatus", function()
			local enabled = vim.g.lint_enabled ~= false
			local ft = vim.bo.filetype
			local linters = lint.linters_by_ft[ft] or {}

			local status = enabled and "✅ Enabled" or "🚫 Disabled"
			local available = #linters > 0 and table.concat(linters, ", ") or "None"

			vim.notify(
				string.format("Linting Status: %s\nFiletype: %s\nAvailable linters: %s", status, ft, available),
				vim.log.levels.INFO,
				{ title = "nvim-lint" }
			)
		end, { desc = "Show linting status" })

		-- Override try_lint to respect global toggle
		local original_try_lint = lint.try_lint
		lint.try_lint = function(...)
			if vim.g.lint_enabled == false then
				return
			end
			return original_try_lint(...)
		end
	end,
}
