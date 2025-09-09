return {
	"Civitasv/cmake-tools.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"akinsho/toggleterm.nvim",
	},
	opts = {
		cmake_command = "cmake",
		ctest_command = "ctest",

		cmake_use_preset = true,
		cmake_regenerate_on_save = false,

		cmake_generate_options = { "-DCMAKE_EXPORT_COMPILE_COMMANDS=1" },
		cmake_build_options = {},

		cmake_build_directory = "build",

		cmake_compile_commands_options = {
			action = "soft_link",
			target = vim.loop.cwd(),
		},

		cmake_executor = {
			name = "toggleterm",
			default_opts = {
				toggleterm = {
					direction = "horizontal",
					close_on_exit = false,
					auto_scroll = true,
				},
			},
		},

		cmake_runner = {
			name = "toggleterm",
			default_opts = {
				toggleterm = {
					direction = "float",
					close_on_exit = false,
					auto_scroll = true,
				},
			},
		},

		cmake_notifications = {
			runner = { enabled = true },
			executor = { enabled = true },
		},
	},

	config = function(_, opts)
		require("cmake-tools").setup(opts)

		vim.keymap.set("n", "<leader>cb", "<cmd>CMakeBuild<cr>", { desc = "CMake Build" })
		vim.keymap.set("n", "<leader>cr", "<cmd>CMakeRun<cr>", { desc = "CMake Run" })
	end,
}
