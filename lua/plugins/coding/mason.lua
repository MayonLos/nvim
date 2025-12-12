return {
	"mason-org/mason.nvim",
	build = ":MasonUpdate",
	event = "VeryLazy",
	opts = {
		ui = { border = "rounded" },
	},
	config = function(_, opts)
		local mason = require("mason")
		mason.setup(opts)

		vim.env.PATH = vim.fn.stdpath("data") .. "/mason/bin:" .. vim.env.PATH

		local ENSURE = {
			-- LSP servers
			"lua-language-server",
			"clangd",
			"pyright",
			"marksman",

			-- Formatters
			"stylua",
			"black",
			"clang-format",
			"prettier",
			"prettierd",
			"shfmt",
		}

		local mr = require("mason-registry")

		local function ensure_installed()
			for _, name in ipairs(ENSURE) do
				local ok, pkg = pcall(mr.get_package, name)
				if ok then
					if not pkg:is_installed() then
						vim.notify("mason: installing " .. name, vim.log.levels.INFO)
						pkg:install()
					end
				else
					vim.notify("mason: package not found -> " .. name, vim.log.levels.WARN)
				end
			end
		end

		if mr.refresh then
			mr.refresh(ensure_installed)
		else
			ensure_installed()
		end

		vim.api.nvim_create_user_command(
			"MasonEnsure",
			ensure_installed,
			{ desc = "Ensure install ENSURE list" }
		)
		vim.api.nvim_create_user_command("MasonMissing", function()
			local missing = {}
			for _, name in ipairs(ENSURE) do
				local ok, pkg = pcall(mr.get_package, name)
				if ok and not pkg:is_installed() then
					table.insert(missing, name)
				end
			end
			if #missing == 0 then
				vim.notify("All ensured packages are installed ✓", vim.log.levels.INFO)
			else
				vim.notify("Missing: " .. table.concat(missing, ", "), vim.log.levels.WARN)
			end
		end, { desc = "List missing packages from ENSURE list" })
	end,
}
