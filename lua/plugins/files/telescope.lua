return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.8",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
    },

    cmd  = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>",  desc = "Live Grep"   },
      { "<leader>fb", "<cmd>Telescope buffers<cr>",    desc = "Buffers"     },
      { "<leader>fo", "<cmd>Telescope oldfiles<cr>",   desc = "Old Files"   },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>",  desc = "Help Tags"   },
      { "<leader>ft", "<cmd>ThemePicker<cr>",           desc = "Pick Theme" },
    },

    opts = function()
      local dropdown = require("telescope.themes").get_dropdown
      return {
        defaults = {
          layout_strategy = "horizontal",
          layout_config   = { prompt_position = "top" },
          sorting_strategy = "ascending",
          winblend = 0,
          mappings = {
            i = {
              ["<C-j>"] = "move_selection_next",
              ["<C-k>"] = "move_selection_previous",
            },
          },
        },
        extensions = {
          ["ui-select"] = dropdown({
            previewer   = false,
            prompt_title = false,
          }),
        },
      }
    end,

    config = function(_, opts)
      local telescope = require("telescope")
      telescope.setup(opts)
      telescope.load_extension("ui-select")

      --------------------------------------------------------------------
      -- Persistent colourscheme picker
      --------------------------------------------------------------------
      local theme_file = vim.fn.stdpath("config") .. "/lua/user/last_theme.lua"
      vim.fn.mkdir(vim.fn.fnamemodify(theme_file, ":h"), "p") -- ensure dir

      -- apply saved theme (if any)
      local ok, saved = pcall(dofile, theme_file)
      if ok and type(saved) == "string" and #saved > 0 then
        pcall(vim.cmd.colorscheme, saved)
      end

      -- picker with save-on-<CR>
      local function theme_picker()
        require("telescope.builtin").colorscheme({
          enable_preview = true,
          attach_mappings = function(prompt_bufnr, map)
            local actions = require("telescope.actions")
            local state   = require("telescope.actions.state")

            local function set_and_save()
              local entry = state.get_selected_entry()
              local name  = entry.value
              vim.fn.writefile({ "return " .. string.format("%q", name) }, theme_file)
              pcall(vim.cmd.colorscheme, name)
              vim.notify("Colourscheme set to " .. name .. " (saved)", vim.log.levels.INFO)
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

