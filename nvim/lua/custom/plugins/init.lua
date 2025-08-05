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
}
