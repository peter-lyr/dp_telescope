-- Copyright (c) 2024 liudepei. All Rights Reserved.
-- create at 2024/04/07 20:11:14 Sunday

local M = {}

local B = require 'dp_base'

M.source = B.getsource(debug.getinfo(1)['source'])
M.lua = B.getlua(M.source)

function M.setreg()
  vim.g.telescope_entered = true
  local bak = vim.fn.getreg '"'
  local save_cursor = vim.fn.getpos '.'
  local line = vim.fn.trim(vim.fn.getline '.')
  vim.g.curline = line
  if string.match(line, [[%']]) then
    vim.cmd "silent norm yi'"
    vim.g.single_quote = vim.fn.getreg '"' ~= bak and vim.fn.getreg '"' or ''
    pcall(vim.fn.setpos, '.', save_cursor)
  end
  if string.match(line, [[%"]]) then
    vim.cmd 'keepjumps silent norm yi"'
    vim.g.double_quote = vim.fn.getreg '"' ~= bak and vim.fn.getreg '"' or ''
    pcall(vim.fn.setpos, '.', save_cursor)
  end
  if string.match(line, [[%`]]) then
    vim.cmd 'keepjumps silent norm yi`'
    vim.g.back_quote = vim.fn.getreg '"' ~= bak and vim.fn.getreg '"' or ''
    pcall(vim.fn.setpos, '.', save_cursor)
  end
  if string.match(line, [[%)]]) then
    vim.cmd 'keepjumps silent norm yi)'
    vim.g.parentheses = vim.fn.getreg '"' ~= bak and vim.fn.getreg '"' or ''
    pcall(vim.fn.setpos, '.', save_cursor)
  end
  if string.match(line, '%]') then
    vim.cmd 'keepjumps silent norm yi]'
    vim.g.bracket = vim.fn.getreg '"' ~= bak and vim.fn.getreg '"' or ''
    pcall(vim.fn.setpos, '.', save_cursor)
  end
  if string.match(line, [[%}]]) then
    vim.cmd 'keepjumps silent norm yi}'
    vim.g.brace = vim.fn.getreg '"' ~= bak and vim.fn.getreg '"' or ''
    pcall(vim.fn.setpos, '.', save_cursor)
  end
  if string.match(line, [[%>]]) then
    vim.cmd 'keepjumps silent norm yi>'
    vim.g.angle_bracket = vim.fn.getreg '"' ~= bak and vim.fn.getreg '"' or ''
    pcall(vim.fn.setpos, '.', save_cursor)
  end
  vim.fn.setreg('"', bak)
  vim.fn.timer_start(4000, function()
    vim.g.telescope_entered = nil
  end)
end

function M.find_files_in_current_project(...)
  if ... then return B.concant_info(..., debug.getinfo(1)['name']) end
  M.setreg()
  vim.cmd 'Telescope find_files'
end

function M.buffers_in_current_project(...)
  if ... then return B.concant_info(..., debug.getinfo(1)['name']) end
  M.setreg()
  vim.cmd 'Telescope buffers cwd_only=true sort_mru=true ignore_current_buffer=true'
end

function M.find_files_in_current_project_git_modified(...)
  if ... then return B.concant_info(..., debug.getinfo(1)['name']) end
  M.setreg()
  vim.cmd 'Telescope git_status'
end

function M.command_history(...)
  if ... then return B.concant_info(..., debug.getinfo(1)['name']) end
  M.setreg()
  vim.cmd 'Telescope command_history'
end

function M.commands(...)
  if ... then return B.concant_info(..., debug.getinfo(1)['name']) end
  M.setreg()
  vim.cmd 'Telescope commands'
end

function M.live_grep(...)
  if ... then return B.concant_info(..., debug.getinfo(1)['name']) end
  M.setreg()
  vim.cmd 'Telescope live_grep'
end

function M.projects_do()
  M.setreg()
  vim.cmd 'Telescope my_projects'
end

function M.all_projects_opened(...)
  if ... then return B.concant_info(..., debug.getinfo(1)['name']) end
  M.projects_do()
  vim.cmd [[call feedkeys("\<esc>")]]
  B.lazy_map {
    { '<leader>sk', M.projects_do, mode = { 'n', 'v', }, silent = true, desc = 'telescope: all projects opened', },
  }
  vim.fn.timer_start(20, function()
    vim.cmd [[call feedkeys(":Telescope my_projects\<cr>")]]
  end)
end

return M
