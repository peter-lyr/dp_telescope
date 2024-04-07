-- Copyright (c) 2024 liudepei. All Rights Reserved.
-- create at 2024/04/07 20:08:55 Sunday

local M = {}

local B = require 'dp_base'

local funcs = require 'dp_telescope_funcs'

local telescope = require 'telescope'
local actions = require 'telescope.actions'
local actions_layout = require 'telescope.actions.layout'

function M.toggle_result_wrap()
  for winnr = 1, vim.fn.winnr '$' do
    local bufnr = vim.fn.winbufnr(winnr)
    local temp = vim.api.nvim_win_get_option(vim.fn.win_getid(winnr), 'wrap')
    local wrap = true
    if temp == true then
      wrap = false
    end
    if vim.api.nvim_buf_get_option(bufnr, 'filetype') == 'TelescopeResults' then
      vim.api.nvim_win_set_option(vim.fn.win_getid(winnr), 'wrap', wrap)
    end
  end
end

vim.api.nvim_create_autocmd({ 'User', }, {
  pattern = 'TelescopePreviewerLoaded',
  callback = function()
    vim.opt.number         = true
    vim.opt.relativenumber = true
    vim.opt.wrap           = true
    B.lazy_map {
      { '<bs>',   M.toggle_result_wrap, mode = { 'n', }, silent = true, desc = 'telescope: toggle result wrap', },
      { '<c-bs>', M.toggle_result_wrap, mode = { 'i', }, silent = true, desc = 'telescope: toggle result wrap', },
    }
  end,
})

function M.paste(command, desc)
  return { command, type = 'command', opts = { nowait = true, silent = true, desc = desc, }, }
end

B.aucmd({ 'BufLeave', }, 'telescope.BufLeave', {
  callback = function(ev)
    local file = vim.api.nvim_buf_get_name(ev.buf)
    if B.is_file(file) then
      vim.g.last_buf = ev.buf
      vim.g.last_fname = vim.fn.fnamemodify(file, ':t')
      if string.match(vim.g.last_fname, '(%d%d%d%d%d%d%-)') then
        vim.g.last_fname = string.match(vim.g.last_fname, '%d%d%d%d%d%d%-(.+)')
      end
    end
  end,
})

function M.five_down()
  return {
    function(prompt_bufnr)
      for _ = 1, 5 do
        actions.move_selection_next(prompt_bufnr)
      end
    end,
    type = 'action',
    opts = { nowait = true, silent = true, desc = 'nvim.telescope: 5j', },
  }
end

function M.five_up()
  return {
    function(prompt_bufnr)
      for _ = 1, 5 do
        actions.move_selection_previous(prompt_bufnr)
      end
    end,
    type = 'action',
    opts = { nowait = true, silent = true, desc = 'nvim.telescope: 5k', },
  }
end

function M.exit_insert_do(commands)
  for _, command in ipairs(commands) do
    command = string.gsub(command, '<', '\\<')
    B.cmd([[call feedkeys("%s")]], command)
  end
end

function M.exit_insert(commands, desc)
  return {
    function()
      M.exit_insert_do(commands)
    end,
    type = 'action',
    opts = { nowait = true, silent = true, desc = desc, },
  }
end

telescope.setup {
  defaults = {
    dynamic_preview_title = true,
    winblend = 10,
    layout_strategy = 'horizontal',
    layout_config = {
      horizontal = {
        preview_cutoff = 0,
        width = 0.92,
        height = 0.92,
      },
    },
    preview = {
      hide_on_startup = false,
      check_mime_type = true,
    },
    mappings = {
      i = {
        ['<C-c>'] = actions.close,
        ['<C-q>'] = actions.close,

        ['<leader><leader>'] = actions.select_default,
        ['<c-space>'] = actions.select_default,
        ['<CR>'] = actions.select_default,
        ['<C-x>'] = actions.select_horizontal,
        ['<C-v>'] = actions.select_vertical,
        ['<C-t>'] = actions.select_tab,

        ['<C-u>'] = actions.preview_scrolling_up,
        ['<C-d>'] = actions.preview_scrolling_down,

        ['<c-a>'] = actions.select_all,
        ['<c-y>'] = actions.toggle_all,
        ['<Tab>'] = actions.toggle_selection + actions.move_selection_worse,
        ['<S-Tab>'] = actions.toggle_selection + actions.move_selection_better,
        ['<C-Tab>'] = actions.send_to_qflist + actions.open_qflist,
        ['<M-q>'] = actions.send_selected_to_qflist + actions.open_qflist,

        ['<C-/>'] = actions.which_key,

        ['<C-w>'] = { '<c-s-w>', type = 'command', },

        ['<c-g>'] = { function(prompt_bufnr) actions_layout.toggle_preview(prompt_bufnr) end, type = 'action', opts = { nowait = true, silent = true, desc = 'nvim.telescope: toggle_preview', }, },

        ['<C-s>'] = M.paste('<c-r>"', 'nvim.telescope.paste: "'),
        ['<C-=>'] = M.paste([[<c-r>=trim(getreg("+"))<cr>]], 'nvim.telescope.paste: +'),

        ['<C-b>'] = M.paste('<c-r>=bufname(g:last_buf)<cr>', 'nvim.telescope.paste: bufname'),
        ['<C-h>'] = M.paste('<c-r>=fnamemodify(bufname(g:last_buf), ":h")<cr>', 'nvim.telescope.paste: bufname head'),
        ['<C-n>'] = M.paste('<c-r>=g:last_fname<cr>', 'nvim.telescope.paste: bufname tail'),

        ['<C-l>'] = M.paste('<c-r>=g:curline<cr>', 'nvim.telescope.paste: cur line'),

        ['<C-\'>'] = M.paste('<c-r>=g:single_quote<cr>', "nvim.telescope.paste: in ''"),
        ['<C-">'] = M.paste('<c-r>=g:double_quote<cr>', 'nvim.telescope.paste: in ""'),
        ['<C-0>'] = M.paste('<c-r>=g:parentheses<cr>', 'nvim.telescope.paste: in ()'),
        ['<C-]>'] = M.paste('<c-r>=g:bracket<cr>', 'nvim.telescope.paste: in []'),
        ['<C-S-]>'] = M.paste('<c-r>=g:brace<cr>', 'nvim.telescope.paste: in {}'),
        ['<C-`>'] = M.paste('<c-r>=g:back_quote<cr>', 'nvim.telescope.paste: in ``'),
        ['<C-S-.>'] = M.paste('<c-r>=g:angle_bracket<cr>', 'nvim.telescope.paste: in <>'),

        ['<Down>'] = actions.move_selection_next,
        ['<Up>'] = actions.move_selection_previous,
        ['<A-j>'] = actions.move_selection_next,
        ['<A-k>'] = actions.move_selection_previous,
        ['<ScrollWheelDown>'] = actions.move_selection_next,
        ['<ScrollWheelUp>'] = actions.move_selection_previous,

        ['<A-s-j>'] = M.five_down(),
        ['<A-s-k>'] = M.five_up(),
        ['<C-j>'] = M.five_down(),
        ['<C-k>'] = M.five_up(),
        ['<PageDown>'] = M.five_down(),
        ['<PageUp>'] = M.five_up(),

        ['kk'] = M.exit_insert({ '<esc>', 'k', }, 'move selection prev'),
        ['jj'] = M.exit_insert({ '<esc>', 'j', }, 'move selection next'),
        ['<leader>k'] = M.exit_insert({ '<esc>', 'k', }, 'move selection prev'),
        ['<leader>j'] = M.exit_insert({ '<esc>', 'j', }, 'move selection next'),
        ['<leader>w'] = M.exit_insert({ '<esc>', 'k', }, 'move selection prev'),
        ['<leader>s'] = M.exit_insert({ '<esc>', 'j', }, 'move selection next'),

        ['<LeftMouse>'] = actions.select_default,
        ['<RightMouse>'] = actions_layout.toggle_preview,
        ['<MiddleMouse>'] = actions.close,
      },
      n = {
        ['q'] = actions.close,
        ['<C-c>'] = actions.close,
        ['<esc>'] = actions.close,

        ['<c-space>'] = actions.select_default,
        ['<CR>'] = actions.select_default,
        ['<C-x>'] = actions.select_horizontal,
        ['<C-v>'] = actions.select_vertical,
        ['<C-t>'] = actions.select_tab,
        ['dj'] = actions.select_horizontal,
        ['dl'] = actions.select_vertical,
        ['dk'] = actions.select_tab,

        ['<Tab>'] = actions.toggle_selection + actions.move_selection_worse,
        ['<S-Tab>'] = actions.toggle_selection + actions.move_selection_better,
        ['<C-Tab>'] = actions.send_to_qflist + actions.open_qflist,
        ['<M-q>'] = actions.send_selected_to_qflist + actions.open_qflist,

        ['j'] = actions.move_selection_next,
        ['k'] = actions.move_selection_previous,
        ['H'] = actions.move_to_top,
        ['M'] = actions.move_to_middle,
        ['L'] = actions.move_to_bottom,

        ['<Down>'] = actions.move_selection_next,
        ['<Up>'] = actions.move_selection_previous,
        ['gg'] = actions.move_to_top,
        ['G'] = actions.move_to_bottom,

        ['<C-u>'] = actions.preview_scrolling_up,
        ['<C-d>'] = actions.preview_scrolling_down,

        ['?'] = actions.which_key,

        ['<leader>'] = { function(prompt_bufnr) actions.select_default(prompt_bufnr) end, type = 'action', opts = { nowait = true, silent = true, desc = 'nvim.telescope: select_default', }, },

        ['<c-g>'] = { function(prompt_bufnr) actions_layout.toggle_preview(prompt_bufnr) end, type = 'action', opts = { nowait = true, silent = true, desc = 'nvim.telescope: toggle_preview', }, },

        ['<c-j>'] = M.five_down(),
        ['<c-k>'] = M.five_up(),
        ['<PageDown>'] = M.five_down(),
        ['<PageUp>'] = M.five_up(),

        ['<ScrollWheelDown>'] = actions.move_selection_next,
        ['<ScrollWheelUp>'] = actions.move_selection_previous,
        ['<LeftMouse>'] = actions.select_default,
        ['<RightMouse>'] = actions_layout.toggle_preview,
        ['<MiddleMouse>'] = actions.close,
      },
    },
    file_ignore_patterns = {
      '%.svn',
      '%.bak',
      'obj',
    },
    vimgrep_arguments = {
      'rg',
      '--color=never',
      '--no-heading',
      '--no-ignore',
      '--with-filename',
      '--line-number',
      '--column',
      '--smart-case',
      '--fixed-strings',
    },
    wrap_results = false,
    initial_mode = 'insert',
  },
}

M.defaults = {
  ['<leader>'] = {
    ['<leader>'] = { function() funcs.find_files_in_current_project() end, funcs.find_files_in_current_project 'telescope', mode = { 'n', 'v', }, },
    b = { function() funcs.buffers_in_current_project() end, funcs.buffers_in_current_project 'telescope', mode = { 'n', 'v', }, },
    q = { function() funcs.find_files_in_current_project_git_modified() end, funcs.find_files_in_current_project_git_modified 'telescope', mode = { 'n', 'v', }, },
    -- s = {
    --   name = 'telescope',
    -- },
  },
}

function M.setup(options)
  local sta, whichkey = pcall(require, 'which-key')
  if not sta then
    vim.notify 'no which-key found, setup for dp_telescope failed!'
    return
  end
  whichkey.register(vim.tbl_deep_extend('force', {}, M.defaults, options or {}))
end

return M
