local M = {}

local state = {
  buf = nil,
  win = nil,
  job = nil,
  cwd = nil,
  last_normal_win = nil,
}

local function buf_valid()
  return state.buf and vim.api.nvim_buf_is_valid(state.buf)
end

local function win_valid(win)
  win = win or state.win
  return win and vim.api.nvim_win_is_valid(win)
end

local function is_float(win)
  if not win_valid(win) then
    return false
  end

  return vim.api.nvim_win_get_config(win).relative ~= ''
end

local function remember_normal_window(win)
  if win_valid(win) and not is_float(win) then
    state.last_normal_win = win
  end
end

local function get_normal_target()
  local current = vim.api.nvim_get_current_win()

  -- Already in a normal editor window
  if not is_float(current) then
    return current
  end

  -- Coming from the OMP float: go back to the editor window
  -- from which the float was opened.
  if win_valid(state.last_normal_win) and not is_float(state.last_normal_win) then
    return state.last_normal_win
  end

  -- Fallback: find any normal window in the current tab.
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if not is_float(win) then
      return win
    end
  end

  return nil
end

local function popup_config()
  local ui = vim.api.nvim_list_uis()[1]

  local width = math.floor(ui.width * 0.8)
  local height = math.floor(ui.height * 0.8)

  return {
    relative = 'editor',
    style = 'minimal',
    border = 'rounded',

    title = ' OMP ',
    title_pos = 'center',

    width = width,
    height = height,

    col = math.floor((ui.width - width) / 2),
    row = math.floor((ui.height - height) / 2),
  }
end

local function restore_window(win)
  if not win_valid(win) then
    return
  end

  if not buf_valid() then
    return
  end

  if vim.api.nvim_win_get_buf(win) ~= state.buf then
    return
  end

  local previous_buf = vim.w[win].omp_previous_buf

  if previous_buf and vim.api.nvim_buf_is_valid(previous_buf) then
    vim.api.nvim_win_set_buf(win, previous_buf)
  else
    local replacement = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_win_set_buf(win, replacement)
  end

  vim.w[win].omp_previous_buf = nil
end

function M.hide()
  if not win_valid() then
    state.win = nil
    return
  end

  local win = state.win

  if vim.api.nvim_get_current_win() == win then
    pcall(vim.cmd, 'stopinsert')
  end

  if is_float(win) then
    vim.api.nvim_win_hide(win)
  else
    -- Don't destroy the split.
    -- Put back whatever buffer was there before OMP.
    restore_window(win)
  end

  state.win = nil
end

local function ensure_buffer()
  if buf_valid() then
    return
  end

  state.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[state.buf].bufhidden = 'hide'
end

local function start_omp()
  state.cwd = vim.fn.getcwd()

  state.job = vim.fn.jobstart({ 'omp' }, {
    term = true,
    cwd = state.cwd,

    on_exit = function(_, exit_code)
      vim.schedule(function()
        state.job = nil

        M.hide()

        if buf_valid() then
          pcall(vim.api.nvim_buf_delete, state.buf, {
            force = true,
          })
        end

        state.buf = nil
        state.cwd = nil

        if exit_code ~= 0 then
          vim.notify('OMP exited with code ' .. exit_code, vim.log.levels.WARN)
        end
      end)
    end,
  })

  if state.job <= 0 then
    state.job = nil
    vim.notify('Failed to start OMP', vim.log.levels.ERROR)
    return false
  end

  vim.keymap.set({ 'n', 't' }, '<C-q>', M.hide, {
    buffer = state.buf,
    desc = 'Hide OMP',
  })

  return true
end

function M.open_float()
  local current = vim.api.nvim_get_current_win()

  -- Remember where we came from so <leader>ow from inside
  -- the float knows where to put OMP.
  remember_normal_window(current)

  -- Already displayed as a float -> just focus it.
  if win_valid() and is_float(state.win) then
    vim.api.nvim_set_current_win(state.win)
    vim.cmd 'startinsert'
    return
  end

  -- OMP is currently inside a normal split.
  -- Restore that split before moving OMP into the float.
  if win_valid() then
    M.hide()
  end

  ensure_buffer()

  state.win = vim.api.nvim_open_win(state.buf, true, popup_config())

  vim.wo[state.win].number = false
  vim.wo[state.win].relativenumber = false
  vim.wo[state.win].signcolumn = 'no'

  if not state.job then
    if not start_omp() then
      M.hide()
      return
    end
  end

  vim.cmd 'startinsert'
end

function M.open_current_window()
  local target = get_normal_target()

  if not target then
    vim.notify('No normal window available for OMP', vim.log.levels.ERROR)
    return
  end

  -- OMP is already displayed in this exact window:
  -- restore the previous buffer.
  if win_valid() and state.win == target and buf_valid() and vim.api.nvim_win_get_buf(target) == state.buf then
    M.hide()
    return
  end

  -- OMP may currently be displayed as a float or in another split.
  if win_valid() then
    M.hide()
  end

  ensure_buffer()

  local previous_buf = vim.api.nvim_win_get_buf(target)

  vim.w[target].omp_previous_buf = previous_buf

  vim.api.nvim_win_set_buf(target, state.buf)

  state.win = target
  state.last_normal_win = target

  vim.api.nvim_set_current_win(target)

  if not state.job then
    if not start_omp() then
      M.hide()
      return
    end
  end

  vim.cmd 'startinsert'
end

function M.toggle_float()
  if win_valid() and is_float(state.win) then
    M.hide()
    return
  end

  M.open_float()
end

function M.setup()
  vim.keymap.set({ 'n', 't', 'x' }, '<leader>oc', M.toggle_float, {
    desc = '[O]MP [C]hat popup',
  })

  vim.keymap.set({ 'n', 't', 'x' }, '<leader>ow', M.open_current_window, {
    desc = '[O]MP current [W]indow',
  })
end

return M
