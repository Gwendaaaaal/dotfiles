return {
  {
    'nvim-tree/nvim-tree.lua',
    version = '*',
    lazy = false,
    dependencies = {
      'nvim-tree/nvim-web-devicons',
    },
    config = function()
      vim.keymap.set('n', '<leader>e', ':NvimTreeToggle<CR>', { desc = '[E]xplore Tree' })
      require('nvim-tree').setup {}
    end,
  },

  {
    '42Paris/42header',
    config = function()
      vim.keymap.set('n', '<leader>H', ':Stdheader<CR>', { desc = '42 [H]eader' })
    end,
  },
  {
    'alex-popov-tech/store.nvim',
    dependencies = {
      'OXY2DEV/markview.nvim', -- optional, for pretty readme preview / help window
    },
    cmd = 'Store',
    keys = {
      { '<leader>os', '<cmd>Store<cr>', desc = '[O]pen Plugin [S]tore' },
    },
    opts = {
      -- optional configuration here
    },
  },
  {
    'rmagatti/goto-preview',
    event = 'BufEnter',
    config = true,
    keys = {
      {
        '<leader>gpd',
        "<cmd>lua require('goto-preview').goto_preview_definition()<CR>",
        noremap = true,
        desc = '[G]oto [P]review [D]efinition',
      },
      {
        '<leader>gpD',
        "<cmd>lua require('goto-preview').goto_preview_declaration()<CR>",
        noremap = true,
        desc = '[G]oto [P]review [D]eclaration',
      },
      {
        '<leader>gpi',
        "<cmd>lua require('goto-preview').goto_preview_implementation()<CR>",
        noremap = true,
        desc = '[G]oto [P]review [I]mplementation',
      },
      {
        '<leader>gpt',
        "<cmd>lua require('goto-preview').goto_preview_type_definition()<CR>",
        noremap = true,
        desc = '[G]oto [P]review [T]ype definition',
      },
      {
        '<leader>gpr',
        "<cmd>lua require('goto-preview').goto_preview_references()<CR>",
        noremap = true,
        desc = '[G]oto [P]review [R]eferences',
      },
      {
        '<leader>gpc',
        "<cmd>lua require('goto-preview').close_all_win()<CR>",
        noremap = true,
        desc = '[G]oto [P]review [C]lose all preview windows',
      },
    },
  },
  {
    'kkrampis/codex.nvim',
    lazy = true,
    cmd = { 'Codex', 'CodexToggle' }, -- Optional: Load only on command execution
    keys = {
      {
        '<leader>cc', -- Change this to your preferred keybinding
        function()
          require('codex').toggle()
        end,
        desc = 'Toggle Codex popup or side-panel',
        mode = { 'n', 't' },
      },
    },
    opts = {
      keymaps = {
        toggle = nil, -- Keybind to toggle Codex window (Disabled by default, watch out for conflicts)
        quit = '<C-q>', -- Keybind to close the Codex window (default: Ctrl + q)
      }, -- Disable internal default keymap (<leader>cc -> :CodexToggle)
      border = 'rounded', -- Options: 'single', 'double', or 'rounded'
      width = 0.8, -- Width of the floating window (0.0 to 1.0)
      height = 0.8, -- Height of the floating window (0.0 to 1.0)
      model = nil, -- Optional: pass a string to use a specific model (e.g., 'o3-mini')
      autoinstall = true, -- Automatically install the Codex CLI if not found
      panel = false, -- Open Codex in a side-panel (vertical split) instead of floating window
      use_buffer = false, -- Capture Codex stdout into a normal buffer instead of a terminal buffer
    },
  },
}
