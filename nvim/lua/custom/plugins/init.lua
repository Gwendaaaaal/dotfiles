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
}
