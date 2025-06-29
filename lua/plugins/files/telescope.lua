return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    cmd = "Telescope",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      { "ryanmsnyder/toggleterm-manager.nvim", dependencies = "akinsho/toggleterm.nvim" },
    },
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files"   },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Live Grep"    },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Buffers"      },
      { "<leader>fo", "<cmd>Telescope oldfiles<cr>",   desc = "Old Files"    },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",  desc = "Help Tags"    },
      { "<leader>ft", "<cmd>ThemePicker<cr>",          desc = "Theme Picker" },
      { "<leader>tm", "<cmd>Telescope toggleterm_manager<cr>", desc = "Term Manager" },
    },
    opts = function()
      local dd = require("telescope.themes").get_dropdown
      return {
        defaults = {
          layout_strategy  = "horizontal",
          layout_config    = { prompt_position = "top" },
          sorting_strategy = "ascending",
          winblend         = 0,
          mappings         = { i = { ["<C-j>"] = "move_selection_next", ["<C-k>"] = "move_selection_previous" } },
        },
        extensions = { ["ui-select"] = dd({ previewer = false, prompt_title = false }) },
      }
    end,
    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      telescope.load_extension("ui-select")
      telescope.load_extension("toggleterm_manager")

      -- persistent colourscheme picker
      local theme_file = vim.fn.stdpath("config") .. "/lua/user/last_theme.lua"
      vim.fn.mkdir(vim.fn.fnamemodify(theme_file, ":h"), "p")
      local ok, saved = pcall(dofile, theme_file)
      if ok and type(saved) == "string" and #saved > 0 then
        pcall(vim.cmd.colorscheme, saved)
      end

      local function theme_picker()
        require("telescope.builtin").colorscheme({
          enable_preview = true,
          attach_mappings = function(pb, map)
            local actions = require("telescope.actions")
            local state   = require("telescope.actions.state")
            local function set_and_save()
              local name = state.get_selected_entry().value
              vim.fn.writefile({ "return " .. string.format("%q", name) }, theme_file)
              pcall(vim.cmd.colorscheme, name)
              actions.close(pb)
            end
            map("i", "<CR>", set_and_save)
            map("n", "<CR>", set_and_save)
            return true
          end,
        })
      end
      vim.api.nvim_create_user_command("ThemePicker", theme_picker, {})
    end,
  },
}

