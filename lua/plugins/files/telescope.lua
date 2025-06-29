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
      { "<leader>ff", "<cmd>Telescope find_files<cr>",   desc = "Find Files"   },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",    desc = "Live Grep"    },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",      desc = "Buffers"      },
      { "<leader>fo", "<cmd>Telescope oldfiles<cr>",     desc = "Old Files"    },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",    desc = "Help Tags"    },
      { "<leader>ft", "<cmd>ThemePicker<cr>",            desc = "Theme Picker" },
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

      local theme_file = vim.fn.stdpath("config") .. "/lua/user/last_theme.lua"
      vim.fn.mkdir(vim.fn.fnamemodify(theme_file, ":h"), "p")

      local function ensure_colorscheme_loaded(name)
        -- 针对你的主题名，可以扩展 gruvbox、tokyonight 等
        if name:find("^catppuccin") then
          require("lazy").load({ plugins = { "catppuccin" } })
        end
      end

      local function theme_picker()
        require("telescope.builtin").colorscheme({
          enable_preview = true,
          attach_mappings = function(prompt_bufnr, map)
            local actions = require("telescope.actions")
            local state   = require("telescope.actions.state")
            local function set_and_save()
              local entry = state.get_selected_entry()
              local name = entry and entry.value or nil
              if name then
                vim.fn.writefile({ "return " .. string.format("%q", name) }, theme_file)
                ensure_colorscheme_loaded(name)
                vim.schedule(function()
                  pcall(vim.cmd.colorscheme, name)
                end)
              end
              actions.close(prompt_bufnr)
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

