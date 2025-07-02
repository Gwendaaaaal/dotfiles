return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope-file-browser.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    "nvim-telescope/telescope-project.nvim",
  },

  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local fb_actions = telescope.extensions.file_browser.actions

    telescope.setup({
      pickers = {
        find_files = {
          find_command = {
            "fd",
            "--type",
            "f",
            "-H",
            "-E",
            "node_modules",
            "-E",
            ".git",
            "-E",
            ".env*",
            "-I",
          },
        },
      },
      extensions = {
        file_browser = {
          hidden = true,
          respect_gitignore = true,
          hijack_netrw = true,
          mappings = {
            ["i"] = {
              ["<A-t>"] = fb_actions.change_cwd,
              ["<C-t>"] = actions.select_tab,
            },
          },
        },
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "ignore_case",
        },
      },
    })

    telescope.load_extension("file_browser")
    telescope.load_extension("fzf")
    telescope.load_extension("project")
    end,
    }
