return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	config = function()
		local npairs = require "nvim-autopairs"
		local Rule = require "nvim-autopairs.rule"
		local cond = require "nvim-autopairs.conds"

		npairs.setup {
			check_ts = true,
			enable_check_bracket_line = false,
			disable_filetype = {
				"TelescopePrompt",
				"neo-tree",
				"oil",
				"lazy",
				"mason",
				"noice",
				"dap-repl",
			},
		}

		npairs.add_rules {
			Rule("`", "`", "markdown"):with_pair(function()
				return false
			end),

			Rule("```", "```", "markdown"):with_move(function(opts)
				return opts.char == "`"
			end),
		}

		npairs.add_rules {
			Rule("$", "$", { "tex", "latex" }),
		}
	end,
}
