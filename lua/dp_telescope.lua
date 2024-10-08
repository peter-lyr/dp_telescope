-- Copyright (c) 2024 liudepei. All Rights Reserved.
-- create at 2024/04/07 20:08:55 Sunday

local M = {}

local sta, B = pcall(require, 'dp_base')

if not sta then return print('Dp_base is required!', debug.getinfo(1)['source']) end

M.source = B.getsource(debug.getinfo(1)['source'])
M.lua = B.getlua(M.source)

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

function M.open_telescope_lua()
  B.jump_or_edit(M.source)
  vim.cmd 'norm gg'
  vim.fn.search('file_ignore_patterns' .. ' = {')
end

require 'which-key'.register {
  ['<leader>s<f1>'] = { function() M.open_telescope_lua() end, B.b(M, 'open_telescope_lua'), mode = { 'n', 'v', }, silent = true, },
}

local extensions = require 'telescope'.extensions
local builtin = require 'telescope.builtin'

local telescope = require 'telescope'
local actions = require 'telescope.actions'
local actions_layout = require 'telescope.actions.layout'

M.cur_root = B.get_telescope_cur_root()
M.cur_roots = B.get_telescope_cur_roots()

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

function M.find_files_in_current_project()
  M.setreg()
  local root_dir = B.get_proj_root()
  if B.is(vim.tbl_contains(vim.tbl_keys(M.cur_root), root_dir)) then
    local cmd = B.format('Telescope find_files cwd=%s', M.cur_root[root_dir])
    B.cmd(cmd)
    B.notify_info(cmd)
  else
    vim.cmd 'Telescope find_files'
  end
end

B.aucmd({ 'BufLeave', 'BufWinLeave', }, 'telescope.bufleave', {
  callback = function(ev)
    if vim.bo[ev.buf].filetype == 'TelescopePrompt' then
      vim.g.rootmarkers = RootMarkers
      -- B.set_timeout(10, function() vim.g.rootmarkers = RootMarkers end)
    end
  end,
})

function M.find_files_in_current_git_project()
  M.setreg()
  local root_dir = B.get_proj_root()
  if B.is(vim.tbl_contains(vim.tbl_keys(M.cur_root), root_dir)) then
    local cmd = B.format('Telescope find_files cwd=%s', M.cur_root[root_dir])
    B.cmd(cmd)
    B.notify_info(cmd)
  else
    vim.g.rootmarkers = { '.git', }
    vim.cmd 'e!'
    vim.cmd 'Telescope find_files'
  end
end

function M.find_files_in_current_project_no_ignore()
  M.setreg()
  vim.cmd 'Telescope find_files find_command=fd,--no-ignore,--hidden'
end

function M.find_files_in_all_dp_plugins()
  M.setreg()
  builtin.find_files { search_dirs = B.get_dp_plugins(), }
end

function M.find_files_in_all_dp_plugins_no_ignore()
  M.setreg()
  builtin.find_files { search_dirs = B.get_dp_plugins(), no_ignore = true, hidden = true, }
end

function M.find_files_in_current_project_git_modified()
  M.setreg()
  vim.g.rootmarkers = { '.git', }
  vim.cmd 'e!'
  vim.cmd 'Telescope git_status'
end

function M.buffers_in_current_project()
  M.setreg()
  vim.cmd 'Telescope buffers cwd_only=true sort_mru=true sort_lastused=true'
end

function M.buffers_in_all_project()
  M.setreg()
  vim.cmd 'Telescope buffers'
end

function M.command_history()
  M.setreg()
  vim.cmd 'Telescope command_history'
end

function M.commands()
  M.setreg()
  vim.cmd 'Telescope commands'
end

function M.live_grep()
  M.setreg()
  local root_dir = B.get_proj_root()
  if B.is(vim.tbl_contains(vim.tbl_keys(M.cur_root), root_dir)) then
    local cmd = B.format('Telescope live_grep cwd=%s', M.cur_root[root_dir])
    B.cmd(cmd)
    B.notify_info(cmd)
  else
    vim.cmd 'Telescope live_grep'
  end
end

function M.live_grep_git()
  M.setreg()
  local root_dir = B.get_proj_root()
  if B.is(vim.tbl_contains(vim.tbl_keys(M.cur_root), root_dir)) then
    local cmd = B.format('Telescope live_grep cwd=%s', M.cur_root[root_dir])
    B.cmd(cmd)
    B.notify_info(cmd)
  else
    vim.g.rootmarkers = { '.git', }
    vim.cmd 'e!'
    vim.cmd 'Telescope live_grep'
  end
end

function M.live_grep_no_ignore()
  M.setreg()
  local root_dir = B.get_proj_root()
  if B.is(vim.tbl_contains(vim.tbl_keys(M.cur_root), root_dir)) then
    local cmd = B.format('Telescope live_grep glob_pattern=* cwd=%s', M.cur_root[root_dir])
    B.cmd(cmd)
    B.notify_info(cmd)
  else
    vim.cmd 'Telescope live_grep glob_pattern=*'
  end
end

function M.live_grep_in_all_dp_plugins()
  M.setreg()
  builtin.live_grep { search_dirs = B.get_dp_plugins(), }
end

function M.grep_string()
  M.setreg()
  local root_dir = B.get_proj_root()
  if B.is(vim.tbl_contains(vim.tbl_keys(M.cur_root), root_dir)) then
    local cmd = B.format('Telescope grep_string cwd=%s', M.cur_root[root_dir])
    B.cmd(cmd)
    B.notify_info(cmd)
  else
    vim.cmd 'Telescope grep_string'
  end
end

function M.grep_string_git()
  M.setreg()
  local root_dir = B.get_proj_root()
  if B.is(vim.tbl_contains(vim.tbl_keys(M.cur_root), root_dir)) then
    local cmd = B.format('Telescope grep_string cwd=%s', M.cur_root[root_dir])
    B.cmd(cmd)
    B.notify_info(cmd)
  else
    vim.g.rootmarkers = { '.git', }
    vim.cmd 'e!'
    vim.cmd 'Telescope grep_string'
  end
end

function M.grep_string_cWORD()
  M.setreg()
  local root_dir = B.get_proj_root()
  local cWORD = vim.fn.expand '<cWORD>'
  if B.is(vim.tbl_contains(vim.tbl_keys(M.cur_root), root_dir)) then
    local cmd = B.format('Telescope grep_string cwd=%s search=%s', M.cur_root[root_dir], cWORD)
    require 'telescope.builtin'.grep_string { cwd = M.cur_root[root_dir], search = cWORD, }
    B.notify_info(cmd)
  else
    require 'telescope.builtin'.grep_string { search = cWORD, }
  end
end

function M.grep_string_cWORD_git()
  M.setreg()
  local root_dir = B.get_proj_root()
  local cWORD = vim.fn.expand '<cWORD>'
  if B.is(vim.tbl_contains(vim.tbl_keys(M.cur_root), root_dir)) then
    local cmd = B.format('Telescope grep_string cwd=%s search=%s', M.cur_root[root_dir], cWORD)
    require 'telescope.builtin'.grep_string { cwd = M.cur_root[root_dir], search = cWORD, }
    B.notify_info(cmd)
  else
    vim.g.rootmarkers = { '.git', }
    vim.cmd 'e!'
    require 'telescope.builtin'.grep_string { search = cWORD, }
  end
end

function M.file_browser_cwd()
  M.setreg()
  extensions.file_browser.file_browser()
end

function M.file_browser_h()
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

function M.all_projects_opened()
  M.projects_do()
  vim.cmd [[call feedkeys("\<esc>")]]
  B.lazy_map {
    { '<leader>sk', M.projects_do, mode = { 'n', 'v', }, silent = true, desc = 'telescope: all projects opened', },
  }
  vim.fn.timer_start(20, function()
    vim.cmd [[call feedkeys(":Telescope my_projects\<cr>")]]
  end)
end

function M.search_history()
  M.setreg()
  vim.cmd 'Telescope search_history'
end

function M.oldfiles()
  M.setreg()
  vim.cmd 'Telescope oldfiles'
end

function M.jumplist()
  M.setreg()
  vim.cmd 'Telescope jumplist'
end

function M.help_tags()
  M.setreg()
  vim.cmd 'Telescope help_tags'
end

function M.nop()
end

B.aucmd({ 'VimLeave', }, 'nvim.telescope.VimLeave', {
  callback = function()
    B.write_table_to_file(TelecopeCurRootTxt, M.cur_root)
    B.write_table_to_file(TelecopeCurRootsTxt, M.cur_roots)
  end,
})

function M._cur_root_sel_do(dir)
  local cwd = B.get_proj_root(dir)
  dir = B.rep(dir)
  require 'dp_nvimtree'._append_dirs(dir)
  M.cur_root[B.rep(cwd)] = dir
  if not M.cur_roots[B.rep(cwd)] then
    M.cur_roots[B.rep(cwd)] = {}
  end
  B.stack_item_uniq(M.cur_roots[B.rep(cwd)], cwd)
  B.stack_item_uniq(M.cur_roots[B.rep(cwd)], dir)
  B.notify_info_append(dir)
end

function M.root_sel_switch()
  local cwd = B.get_proj_root(B.buf_get_name())
  local dirs = M.cur_roots[cwd]
  if dirs and #dirs == 1 then
    M._cur_root_sel_do(dirs[1])
  else
    B.ui_sel(dirs, 'sel as telescope root', function(dir)
      if dir then
        M._cur_root_sel_do(dir)
      end
    end)
  end
end

function M.root_sel_parennt_dirs()
  local dirs = B.get_file_dirs()
  if dirs and #dirs == 1 then
    M._cur_root_sel_do(dirs[1])
  else
    B.ui_sel(dirs, 'sel as telescope root', function(dir)
      if dir then
        M._cur_root_sel_do(dir)
      end
    end)
  end
end

function M.git_branches()
  M.setreg()
  vim.cmd 'Telescope git_branches'
end

function M.git_commits()
  M.setreg()
  vim.cmd 'Telescope git_commits'
end

function M.git_bcommits()
  M.setreg()
  vim.cmd 'Telescope git_bcommits'
end

function M.git_stash()
  M.setreg()
  vim.cmd 'Telescope git_stash'
end

function M.git_files()
  M.setreg()
  vim.cmd 'Telescope git_files'
end

function M.lsp_document_symbols()
  M.setreg()
  vim.cmd 'Telescope lsp_document_symbols previewer=true'
end

function M.lsp_references()
  M.setreg()
  vim.cmd 'Telescope lsp_references previewer=true'
end

function M.current_buffer_fuzzy_find()
  M.setreg()
  B.cmd 'Telescope current_buffer_fuzzy_find'
end

function M.root_sel_till_git()
  local dirs = B.get_file_dirs_till_git()
  if dirs and #dirs == 1 then
    M._cur_root_sel_do(dirs[1])
  else
    B.ui_sel(dirs, 'sel as telescope root', function(dir)
      if dir then
        M._cur_root_sel_do(dir)
      end
    end)
  end
end

function M.root_sel_scan_dirs()
  local dirs = B.scan_dirs()
  if dirs and #dirs == 1 then
    M._cur_root_sel_do(dirs[1])
  else
    B.ui_sel(dirs, 'sel as telescope root', function(dir)
      if dir then
        M._cur_root_sel_do(dir)
      end
    end)
  end
end

function M.get_telescopes()
  local telescopes = {}
  for _, t in ipairs(vim.fn.getcompletion('Telescope ', 'cmdline')) do
    telescopes[#telescopes + 1] = t
  end
  print('vim.inspect(telescopes):', vim.inspect(telescopes))
  return telescopes
end

function M.telescope()
  local telescopes = M.get_telescopes()
  B.ui_sel(telescopes, 'sel as telescope root', function(t)
    if t then
      B.cmd([[call feedkeys(":\<c-u>Telescope %s")]], t)
    end
  end)
end

-- require("telescope").setup {
--   extensions = {
--     file_browser = {
--       path = vim.loop.cwd(),
--       cwd = vim.loop.cwd(),
--       cwd_to_path = false,
--       grouped = false,
--       files = true,
--       add_dirs = true,
--       depth = 1,
--       auto_depth = false,
--       select_buffer = false,
--       hidden = { file_browser = false, folder_browser = false },
--       respect_gitignore = vim.fn.executable "fd" == 1,
--       no_ignore = false,
--       follow_symlinks = false,
--       browse_files = require("telescope._extensions.file_browser.finders").browse_files,
--       browse_folders = require("telescope._extensions.file_browser.finders").browse_folders,
--       hide_parent_dir = false,
--       collapse_dirs = false,
--       prompt_path = false,
--       quiet = false,
--       dir_icon = "",
--       dir_icon_hl = "Default",
--       display_stat = { date = true, size = true, mode = true },
--       hijack_netrw = false,
--       use_fd = true,
--       git_status = true,
--       mappings = {
--         ["i"] = {
--           ["<A-c>"] = fb_actions.create,
--           ["<S-CR>"] = fb_actions.create_from_prompt,
--           ["<A-r>"] = fb_actions.rename,
--           ["<A-m>"] = fb_actions.move,
--           ["<A-y>"] = fb_actions.copy,
--           ["<A-d>"] = fb_actions.remove,
--           ["<C-o>"] = fb_actions.open,
--           ["<C-g>"] = fb_actions.goto_parent_dir,
--           ["<C-e>"] = fb_actions.goto_home_dir,
--           ["<C-w>"] = fb_actions.goto_cwd,
--           ["<C-t>"] = fb_actions.change_cwd,
--           ["<C-f>"] = fb_actions.toggle_browser,
--           ["<C-h>"] = fb_actions.toggle_hidden,
--           ["<C-s>"] = fb_actions.toggle_all,
--           ["<bs>"] = fb_actions.backspace,
--         },
--         ["n"] = {
--           ["c"] = fb_actions.create,
--           ["r"] = fb_actions.rename,
--           ["m"] = fb_actions.move,
--           ["y"] = fb_actions.copy,
--           ["d"] = fb_actions.remove,
--           ["o"] = fb_actions.open,
--           ["g"] = fb_actions.goto_parent_dir,
--           ["e"] = fb_actions.goto_home_dir,
--           ["w"] = fb_actions.goto_cwd,
--           ["t"] = fb_actions.change_cwd,
--           ["f"] = fb_actions.toggle_browser,
--           ["h"] = fb_actions.toggle_hidden,
--           ["s"] = fb_actions.toggle_all,
--         },
--       },
--     },
--   },
-- }

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

        ['g'] = { function(prompt_bufnr) actions_layout.toggle_preview(prompt_bufnr) end, type = 'action', opts = { nowait = true, silent = true, desc = 'nvim.telescope: toggle_preview', }, },

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
      'Backup',
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
      no_ignore = true,
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
  patterns = { '.git', '.svn', },
  datapath = DataSub,
}

-- file_browser
telescope.load_extension 'file_browser'

-- git_file_history
telescope.load_extension 'git_file_history'

require 'which-key'.register {
  ['<leader>s'] = { name = 'telescope', },
  ['<leader>sd'] = { name = 'telescope.more', },
  ['<leader>sdd'] = { name = 'telescope.more', },
  ['<leader>s<leader>'] = { function() M.telescope() end, 'Telescope', mode = { 'n', 'v', }, },
}

require 'which-key'.register {
  ['<leader>sf'] = { function() M.find_files_in_current_project_no_ignore() end, B.b(M, 'find_files_in_current_project_no_ignore'), mode = { 'n', 'v', }, },
  ['<leader>sk'] = { function() M.all_projects_opened() end, B.b(M, 'all_projects_opened'), mode = { 'n', 'v', }, },
  ['<leader>sl'] = { function() M.live_grep_no_ignore() end, B.b(M, 'live_grep_no_ignore'), mode = { 'n', 'v', }, },
}

require 'which-key'.register {
  -- ['<leader><tab>'] = { function() M.find_files_in_current_project_git_modified() end, B.b(M, 'find_files_in_current_project_git_modified'), mode = { 'n', 'v', }, },
  -- ['<leader><leader>'] = { function() M.find_files_in_current_project() end, B.b(M, 'find_files_in_current_project'), mode = { 'n', 'v', }, },
  -- ['<leader><bs>'] = { function() M.buffers_in_current_project() end, B.b(M, 'buffers_in_current_project'), mode = { 'n', 'v', }, },
  -- ['<leader><c-bs>'] = { function() M.buffers_in_all_project() end, B.b(M, 'buffers_in_all_project'), mode = { 'n', 'v', }, },
  -- ['<leader><cr>'] = { function() M.grep_string() end, B.b(M, 'grep_string'), mode = { 'n', 'v', }, },
  -- ['<leader>l'] = { function() M.live_grep() end, B.b(M, 'live_grep'), mode = { 'n', 'v', }, },
  -- ['<leader>/'] = { function() M.current_buffer_fuzzy_find() end, B.b(M, 'current_buffer_fuzzy_find'), mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>sd<leader>'] = { function() M.find_files_in_all_dp_plugins() end, B.b(M, 'find_files_in_all_dp_plugins'), mode = { 'n', 'v', }, },
  ['<leader>sdd<leader>'] = { function() M.find_files_in_all_dp_plugins_no_ignore() end, B.b(M, 'find_files_in_all_dp_plugins_no_ignore'), mode = { 'n', 'v', }, },
  ['<leader>sddl'] = { function() M.live_grep_in_all_dp_plugins() end, B.b(M, 'live_grep_in_all_dp_plugins'), mode = { 'n', 'v', }, },
}

require 'which-key'.register {
  ['<leader>sw'] = { function() M.file_browser_h() end, B.b(M, 'file_browser_h'), mode = { 'n', 'v', }, },
  ['<leader>sdw'] = { function() M.file_browser_cwd() end, B.b(M, 'file_browser_cwd'), mode = { 'n', 'v', }, },
}

require 'which-key'.register {
  ['<leader>sc'] = { function() M.command_history() end, B.b(M, 'command_history'), mode = { 'n', 'v', }, },
  ['<leader>sdc'] = { function() M.commands() end, B.b(M, 'commands'), mode = { 'n', 'v', }, },
  ['<leader>sh'] = { function() M.search_history() end, B.b(M, 'search_history'), mode = { 'n', 'v', }, },
  ['<leader>so'] = { function() M.oldfiles() end, B.b(M, 'oldfiles'), mode = { 'n', 'v', }, silent = true, },
  ['<leader>sj'] = { function() M.jumplist() end, B.b(M, 'jumplist'), mode = { 'n', 'v', }, silent = true, },
  ['<leader>sdh'] = { function() M.help_tags() end, B.b(M, 'help_tags'), mode = { 'n', 'v', }, },
}

require 'which-key'.register {
  ['<leader>sr'] = { name = 'telescope.cur_root', },
  ['<leader>sr<leader>'] = { function() M.root_sel_switch() end, B.b(M, 'root_sel_switch'), mode = { 'n', 'v', }, silent = true, },
  ['<leader>srs'] = { function() M.root_sel_scan_dirs() end, B.b(M, 'root_sel_scan_dirs'), mode = { 'n', 'v', }, silent = true, },
  ['<leader>srp'] = { function() M.root_sel_parennt_dirs() end, B.b(M, 'root_sel_parennt_dirs'), mode = { 'n', 'v', }, silent = true, },
  ['<leader>srg'] = { function() M.root_sel_till_git() end, B.b(M, 'root_sel_till_git'), mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>fl'] = { function() M.lsp_document_symbols() end, 'lsp.telescope: document_symbols', mode = { 'n', 'v', }, silent = true, },
  ['<leader>fr'] = { function() M.lsp_references() end, 'lsp.telescope: references', mode = { 'n', 'v', }, silent = true, },
}

require 'which-key'.register {
  ['<leader>gt'] = { name = 'git.telescope', },
  ['<leader>gf'] = { function() M.git_files() end, B.b(M, 'git_files'), mode = { 'n', 'v', }, silent = true, },
  ['<leader>gh'] = { function() M.git_branches() end, B.b(M, 'git_branches'), mode = { 'n', 'v', }, silent = true, },
  ['<leader>gtc'] = { function() M.git_commits() end, B.b(M, 'git_commits'), mode = { 'n', 'v', }, silent = true, },
  ['<leader>gtb'] = { function() M.git_bcommits() end, B.b(M, 'git_bcommits'), mode = { 'n', 'v', }, silent = true, },
  ['<leader>gts'] = { function() M.git_stash() end, B.b(M, 'git_stash'), mode = { 'n', 'v', }, silent = true, },
}

return M
