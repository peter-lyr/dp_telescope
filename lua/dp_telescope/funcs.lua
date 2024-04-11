-- Copyright (c) 2024 liudepei. All Rights Reserved.
-- create at 2024/04/07 20:11:14 Sunday

local M = {}

local sta, B = pcall(require, 'dp_base')

if not sta then return print('Dp_base is required!', debug.getinfo(1)['source']) end

local extensions = require 'telescope'.extensions
local builtin = require 'telescope.builtin'

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

return M
