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
      require('nvim-tree').setup {
        actions = {
          open_file = {
            window_picker = {
              enable = false,
            },
          },
        },
      }
    end,
  },

  {
    '42Paris/42header',
    config = function()
      vim.keymap.set('n', '<leader>h', ':Stdheader<CR>', { desc = '42 [H]eader' })
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

    cmd = {
      'Codex',
      'CodexToggle',
    },

    keys = {
      {
        '<leader>cc',
        function()
          local codex = require 'codex'
          local state = require 'codex.state'

          if state.win and vim.api.nvim_win_is_valid(state.win) then
            local config = vim.api.nvim_win_get_config(state.win)
            local is_popup = config.relative ~= ''

            codex.close()

            if is_popup then
              return
            end
          end

          codex.open()

          vim.schedule(function()
            if state.win and vim.api.nvim_win_is_valid(state.win) then
              vim.api.nvim_set_current_win(state.win)
              vim.cmd 'startinsert'
            end
          end)
        end,

        desc = 'Codex popup',
        mode = { 'n', 't' },
      },

      {
        '<leader>cw',
        function()
          local codex = require 'codex'
          local state = require 'codex.state'

          local target_win = vim.api.nvim_get_current_win()
          local current_buf = vim.api.nvim_win_get_buf(target_win)

          if state.buf and vim.api.nvim_buf_is_valid(state.buf) and current_buf == state.buf then
            vim.cmd 'stopinsert'

            local previous_buf = vim.w[target_win].codex_previous_buf

            if previous_buf and vim.api.nvim_buf_is_valid(previous_buf) then
              vim.api.nvim_win_set_buf(target_win, previous_buf)
            else
              vim.cmd 'enew'
            end

            vim.w[target_win].codex_previous_buf = nil
            state.win = nil
            return
          end

          if state.win and vim.api.nvim_win_is_valid(state.win) then
            codex.close()
          end

          if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
            codex.open()

            if state.win and vim.api.nvim_win_is_valid(state.win) then
              codex.close()
            end

            if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
              vim.notify('Impossible de créer le buffer Codex', vim.log.levels.ERROR)
              return
            end
          end

          vim.w[target_win].codex_previous_buf = current_buf
          vim.api.nvim_win_set_buf(target_win, state.buf)

          state.win = target_win

          vim.api.nvim_set_current_win(target_win)
          vim.cmd 'startinsert'
        end,

        desc = 'Codex in current window',
        mode = { 'n', 't' },
      },
    },

    opts = {
      keymaps = {
        toggle = nil,
        quit = '<C-q>',
      },
      border = 'rounded',
      width = 0.8,
      height = 0.8,
      model = nil,
      autoinstall = true,
      panel = false,
      use_buffer = false,
    },
  },
  { 'mg979/vim-visual-multi' },
}
