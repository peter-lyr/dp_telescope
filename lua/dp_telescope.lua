-- Copyright (c) 2024 liudepei. All Rights Reserved.
-- create at 2024/04/07 20:08:55 Sunday

local M = {}

local sta, B = pcall(require, 'dp_base')

if not sta then return print('Dp_base is required!', debug.getinfo(1)['source']) end

if B.check_plugins {
      'git@github.com:peter-lyr/dp_init',
      'folke/which-key.nvim',
      'nvim-notify',
      'git@github.com:peter-lyr/telescope.nvim',
      -- 'nvim-telescope/telescope.nvim',
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'ahmedkhalf/project.nvim',
      'dbakker/vim-projectroot',
      'nvim-telescope/telescope-file-browser.nvim',
    } then
  return
end

local extensions = require 'telescope'.extensions
local builtin = require 'telescope.builtin'

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

function M.setreg()
  vim.g.telescope_entered = true
  B.setreg()
  vim.fn.timer_start(4000, function()
    vim.g.telescope_entered = nil
  end)
end

function M.find_files_in_current_project(...)
  if ... then return B.concant_info(..., 'find_files_in_current_project') end
  M.setreg()
  vim.cmd 'Telescope find_files'
end

function M.find_files_in_current_project_no_ignore(...)
  if ... then return B.concant_info(..., 'find_files_in_current_project_no_ignore') end
  M.setreg()
  vim.cmd 'Telescope find_files find_command=fd,--no-ignore,--hidden'
end

function M.find_files_in_all_dp_plugins(...)
  if ... then return B.concant_info(..., 'find_files_in_all_dp_plugins') end
  M.setreg()
  builtin.find_files { search_dirs = B.get_dp_plugins(), }
end

function M.find_files_in_current_project_git_modified(...)
  if ... then return B.concant_info(..., 'find_files_in_current_project_git_modified') end
  M.setreg()
  vim.cmd 'Telescope git_status'
end

function M.buffers_in_current_project(...)
  if ... then return B.concant_info(..., 'buffers_in_current_project') end
  M.setreg()
  vim.cmd 'Telescope buffers cwd_only=true sort_mru=true sort_lastused=true'
end

function M.buffers_in_all_project(...)
  if ... then return B.concant_info(..., 'buffers_in_all_project') end
  M.setreg()
  vim.cmd 'Telescope buffers'
end

function M.command_history(...)
  if ... then return B.concant_info(..., 'command_history') end
  M.setreg()
  vim.cmd 'Telescope command_history'
end

function M.commands(...)
  if ... then return B.concant_info(..., 'commands') end
  M.setreg()
  vim.cmd 'Telescope commands'
end

function M.live_grep(...)
  if ... then return B.concant_info(..., 'live_grep') end
  M.setreg()
  vim.cmd 'Telescope live_grep'
end

function M.live_grep_no_ignore(...)
  if ... then return B.concant_info(..., 'live_grep_no_ignore') end
  M.setreg()
  vim.cmd 'Telescope live_grep glob_pattern=*'
end

function M.live_grep_in_all_dp_plugins(...)
  if ... then return B.concant_info(..., 'live_grep_in_all_dp_plugins') end
  M.setreg()
  builtin.live_grep { search_dirs = B.get_dp_plugins(), }
end

function M.file_browser_cwd(...)
  if ... then return B.concant_info(..., 'file_browser_cwd') end
  M.setreg()
  extensions.file_browser.file_browser()
end

function M.file_browser_h(...)
  if ... then return B.concant_info(..., 'file_browser_h') end
  M.setreg()
  extensions.file_browser.file_browser {
    path = '%:p:h',
    select_buffer = true,
  }
end

function M.projects_do()
  M.setreg()
  vim.cmd 'Telescope my_projects'
end

function M.all_projects_opened(...)
  if ... then return B.concant_info(..., 'all_projects_opened') end
  M.projects_do()
  vim.cmd [[call feedkeys("\<esc>")]]
  B.lazy_map {
    { '<leader>sk', M.projects_do, mode = { 'n', 'v', }, silent = true, desc = 'telescope: all projects opened', },
  }
  vim.fn.timer_start(20, function()
    vim.cmd [[call feedkeys(":Telescope my_projects\<cr>")]]
  end)
end

function M.search_history(...)
  if ... then return B.concant_info(..., 'search_history') end
  M.setreg()
  vim.cmd 'Telescope search_history'
end

function M.oldfiles(...)
  if ... then return B.concant_info(..., 'oldfiles') end
  M.setreg()
  vim.cmd 'Telescope oldfiles'
end

function M.jumplist(...)
  if ... then return B.concant_info(..., 'jumplist') end
  M.setreg()
  vim.cmd 'Telescope jumplist'
end

function M.help_tags(...)
  if ... then return B.concant_info(..., 'help_tags') end
  M.setreg()
  vim.cmd 'Telescope help_tags'
end

function M.nop()
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

        ['<Tab>'] = { function(prompt_bufnr)
          actions.toggle_selection(prompt_bufnr)
          actions.move_selection_worse(prompt_bufnr)
        end, type = 'action', opts = { nowait = true, silent = true, desc = 'nvim.telescope: toggle select next', }, },
        ['<S-Tab>'] = { function(prompt_bufnr)
          actions.toggle_selection(prompt_bufnr)
          actions.move_selection_better(prompt_bufnr)
        end, type = 'action', opts = { nowait = true, silent = true, desc = 'nvim.telescope: toggle select prev', }, },
        ['<C-Tab>'] = { function(prompt_bufnr)
          actions.send_to_qflist(prompt_bufnr)
          actions.open_qflist(prompt_bufnr)
        end, type = 'action', opts = { nowait = true, silent = true, desc = 'nvim.telescope: send_to_qflist open_qflist', }, },
        ['<M-q>'] = { function(prompt_bufnr)
          actions.send_selected_to_qflist(prompt_bufnr)
          actions.open_qflist(prompt_bufnr)
        end, type = 'action', opts = { nowait = true, silent = true, desc = 'nvim.telescope: send_to_qflist open_qflist', }, },

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

        ['<Tab>'] = { function(prompt_bufnr)
          actions.toggle_selection(prompt_bufnr)
          actions.move_selection_worse(prompt_bufnr)
        end, type = 'action', opts = { nowait = true, silent = true, desc = 'nvim.telescope: toggle select next', }, },
        ['<S-Tab>'] = { function(prompt_bufnr)
          actions.toggle_selection(prompt_bufnr)
          actions.move_selection_better(prompt_bufnr)
        end, type = 'action', opts = { nowait = true, silent = true, desc = 'nvim.telescope: toggle select prev', }, },
        ['<C-Tab>'] = { function(prompt_bufnr)
          actions.send_to_qflist(prompt_bufnr)
          actions.open_qflist(prompt_bufnr)
        end, type = 'action', opts = { nowait = true, silent = true, desc = 'nvim.telescope: send_to_qflist open_qflist', }, },
        ['<M-q>'] = { function(prompt_bufnr)
          actions.send_selected_to_qflist(prompt_bufnr)
          actions.open_qflist(prompt_bufnr)
        end, type = 'action', opts = { nowait = true, silent = true, desc = 'nvim.telescope: send_to_qflist open_qflist', }, },

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
  extensions = {
    file_browser = {
      theme = 'ivy',
      hijack_netrw = true,
      mappings = {
        ['i'] = {
        },
        ['n'] = {
        },
      },
    },
  },
}

-- ui-select
telescope.load_extension 'ui-select'

-- projects
telescope.load_extension 'my_projects'

require 'project_nvim'.setup {
  manual_mode = false,
  detection_methods = { 'pattern', 'lsp', },
  patterns = { '.git', },
  datapath = DataSub,
}

-- file_browser
require 'telescope'.load_extension 'file_browser'

require 'which-key'.register {
  ['<leader>'] = {
    ['<leader>'] = { function() M.find_files_in_current_project() end, M.find_files_in_current_project 'telescope', mode = { 'n', 'v', }, },
    b = { function() M.buffers_in_current_project() end, M.buffers_in_current_project 'telescope', mode = { 'n', 'v', }, },
    q = { function() M.find_files_in_current_project_git_modified() end, M.find_files_in_current_project_git_modified 'telescope', mode = { 'n', 'v', }, },
    h = { function() M.command_history() end, M.command_history 'telescope', mode = { 'n', 'v', }, },
    ['<c-h>'] = { function() M.commands() end, M.commands 'telescope', mode = { 'n', 'v', }, },
    l = { function() M.live_grep() end, M.live_grep 'telescope', mode = { 'n', 'v', }, },
    i = { function() M.file_browser_h() end, M.file_browser_h 'telescope', mode = { 'n', 'v', }, },
    o = { function() M.file_browser_cwd() end, M.file_browser_cwd 'telescope', mode = { 'n', 'v', }, },
    s = {
      name = 'telescope',
      b = { function() M.buffers_in_all_project() end, M.buffers_in_all_project 'telescope', mode = { 'n', 'v', }, },
      ['<leader>'] = { function() M.find_files_in_current_project_no_ignore() end, M.find_files_in_current_project_no_ignore 'telescope', mode = { 'n', 'v', }, },
      l = { function() M.live_grep_no_ignore() end, M.live_grep_no_ignore 'telescope', mode = { 'n', 'v', }, },
      k = { function() M.all_projects_opened() end, M.all_projects_opened 'telescope', mode = { 'n', 'v', }, },
      h = { function() M.search_history() end, M.search_history 'telescope', mode = { 'n', 'v', }, },
      o = { function() M.oldfiles() end, M.oldfiles 'telescope', mode = { 'n', 'v', }, silent = true, },
      j = { function() M.jumplist() end, M.jumplist 'telescope', mode = { 'n', 'v', }, silent = true, },
      v = {
        name = 'telescope.more',
        ['<leader>'] = { function() M.find_files_in_all_dp_plugins() end, M.find_files_in_all_dp_plugins 'telescope', mode = { 'n', 'v', }, },
        l = { function() M.live_grep_in_all_dp_plugins() end, M.live_grep_in_all_dp_plugins 'telescope', mode = { 'n', 'v', }, },
        h = { function() M.help_tags() end, M.help_tags 'telescope', mode = { 'n', 'v', }, },
      },
    },
  },
  ['<c-s-f12>'] = {
    ['<f1>'] = { function() M.jumplist() end, M.jumplist 'telescope', mode = { 'n', 'v', }, silent = true, },
    ['<f2>'] = { function() M.command_history() end, M.command_history 'telescope', mode = { 'n', 'v', }, silent = true, },
    ['<f3>'] = { function() M.oldfiles() end, M.oldfiles 'telescope', mode = { 'n', 'v', }, silent = true, },
    ['<f4>'] = { function() M.buffers_in_current_project() end, M.buffers_in_current_project 'telescope', mode = { 'n', 'v', }, silent = true, },
  },
  ['<c-s-f12><f1>'] = { function() M.nop() end, 'telescope: nop', mode = { 'i', }, silent = true, },
  ['<c-s-f12><f2>'] = { function() M.nop() end, 'telescope: nop', mode = { 'i', }, silent = true, },
  ['<c-s-f12><f3>'] = { function() M.nop() end, 'telescope: nop', mode = { 'i', }, silent = true, },
  ['<c-s-f12><f4>'] = { function() M.nop() end, 'telescope: nop', mode = { 'i', }, silent = true, },
}

return M
