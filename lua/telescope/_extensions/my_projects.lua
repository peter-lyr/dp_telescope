-- Copyright (c) 2024 liudepei. All Rights Reserved.
-- create at 2024/04/04 00:06:24 星期四

local sta, B = pcall(require, 'dp_base')

if not sta then return print('Dp_base is required!', debug.getinfo(1)['source']) end

-- Inspiration from:
-- https://github.com/nvim-telescope/telescope-project.nvim
local has_telescope, telescope = pcall(require, 'telescope')

if not has_telescope then
  return
end

local finders = require 'telescope.finders'
local pickers = require 'telescope.pickers'
local telescope_config = require 'telescope.config'.values
local actions = require 'telescope.actions'
local state = require 'telescope.actions.state'
local builtin = require 'telescope.builtin'
local entry_display = require 'telescope.pickers.entry_display'

local history = require 'project_nvim.utils.history'
local project = require 'project_nvim.project'

----------
-- Actions
----------

local function create_finder()
  local results = history.get_recent_projects()

  local maxwidth = 0
  local width
  local temp = ''
  -- Reverse results
  for i = 1, math.floor(#results / 2) do
    results[i], results[#results - i + 1] = results[#results - i + 1], results[i]
    temp = string.gsub(results[i], '/', '\\')
    width = vim.fn.strdisplaywidth(string.match(temp, '.+\\(.+)'))
    if maxwidth < width then
      maxwidth = width
    end
    temp = string.gsub(results[#results - i + 1], '/', '\\')
    width = vim.fn.strdisplaywidth(string.match(temp, '.+\\(.+)'))
    if maxwidth < width then
      maxwidth = width
    end
  end
  local temp_ = {}
  local results_new = {}
  for _, result in ipairs(results) do
    local file = B.rep(result)
    if not B.is_in_tbl(file, temp_) then
      results_new[#results_new + 1] = result
      temp_[#temp_ + 1] = file
    end
  end
  results = results_new
  local displayer = entry_display.create {
    separator = ' ',
    items = {
      {
        width = maxwidth,
      },
      {
        remaining = true,
      },
    },
  }

  local function make_display(entry)
    return displayer { entry.name, { entry.value, 'Comment', }, }
  end

  return finders.new_table {
    results = results,
    entry_maker = function(entry)
      local name = vim.fn.fnamemodify(entry, ':t')
      return {
        display = make_display,
        name = name,
        value = entry,
        ordinal = name .. ' ' .. entry,
      }
    end,
  }
end

local function change_working_directory(prompt_bufnr, prompt)
  local selected_entry = state.get_selected_entry(prompt_bufnr)
  if selected_entry == nil then
    actions.close(prompt_bufnr)
    return
  end
  local project_path = selected_entry.value
  if prompt == true then
    actions._close(prompt_bufnr, true)
  else
    actions.close(prompt_bufnr)
  end
  local cd_successful = project.set_pwd(project_path, 'telescope')
  return project_path, cd_successful
end

local function find_files_cur(prompt_bufnr)
  local project_path, cd_successful = change_working_directory(prompt_bufnr, true)
  -- local m = require 'config.nvim.telescope'
  -- local root_dir = B.rep(project_path)
  -- if B.is(vim.tbl_contains(vim.tbl_keys(m.cur_root), root_dir)) then
  --   project_path = m.cur_root[root_dir]
  -- end
  local opt = {
    cwd = project_path,
  }
  if cd_successful then
    builtin.find_files(opt)
  end
  B.notify_info('telescope root: ' .. project_path)
end

local function find_files_all(prompt_bufnr)
  local project_path, cd_successful = change_working_directory(prompt_bufnr, true)
  local opt = {
    cwd = project_path,
  }
  if cd_successful then
    builtin.find_files(opt)
  end
end

local function live_grep_cur(prompt_bufnr)
  local project_path, cd_successful = change_working_directory(prompt_bufnr, true)
  -- local m = require 'config.nvim.telescope'
  -- local root_dir = B.rep(project_path)
  -- if B.is(vim.tbl_contains(vim.tbl_keys(m.cur_root), root_dir)) then
  --   project_path = m.cur_root[root_dir]
  -- end
  local opt = {
    cwd = project_path,
  }
  if cd_successful then
    builtin.live_grep(opt)
  end
  B.notify_info('telescope root: ' .. project_path)
end

local function live_grep_root(prompt_bufnr)
  local project_path, cd_successful = change_working_directory(prompt_bufnr, true)
  local opt = {
    cwd = project_path,
  }
  if cd_successful then
    builtin.live_grep(opt)
  end
end

local function git_status(prompt_bufnr)
  local project_path, cd_successful = change_working_directory(prompt_bufnr, true)
  -- local m = require 'config.nvim.telescope'
  -- local root_dir = B.rep(project_path)
  -- if B.is(vim.tbl_contains(vim.tbl_keys(m.cur_root), root_dir)) then
  --   project_path = m.cur_root[root_dir]
  -- end
  local opt = {
    cwd = project_path,
  }
  if cd_successful then
    builtin.git_status(opt)
  end
  B.notify_info('telescope root: ' .. project_path)
end

local function git_status_all(prompt_bufnr)
  local project_path, cd_successful = change_working_directory(prompt_bufnr, true)
  local opt = {
    cwd = project_path,
  }
  if cd_successful then
    builtin.git_status(opt)
  end
end

local function delete_project(prompt_bufnr)
  local picker = state.get_current_picker(prompt_bufnr)
  local selections = picker:get_multi_selection()
  local selectedEntry = state.get_selected_entry(prompt_bufnr)
  if selectedEntry == nil then
    actions.close(prompt_bufnr)
    return
  end
  if #selections == 0 then
    selections = { selectedEntry, }
  end
  local prompt
  if #selections == 1 then
    prompt = string.format('Delete %s from project list?', selections[1].value)
  else
    prompt = string.format('Delete %d items from project list?', #selections)
  end
  local choice = vim.fn.confirm(prompt, '&Yes\n&No', 2)

  if choice == 1 then
    for _, entry in ipairs(selections) do
      history.delete_project(entry)
    end

    local finder = create_finder()
    state.get_current_picker(prompt_bufnr):refresh(finder, {
      reset_prompt = true,
    })
  end
end

---Main entrypoint for Telescope.
---@param opts table
local function my_projects(opts)
  opts = opts or {}

  pickers.new(opts, {
    prompt_title = 'Recent Projects',
    finder = create_finder(),
    previewer = false,
    sorter = telescope_config.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, map)
      map('n', 'z', delete_project, { nowait = true, })
      map('i', '<F2>', delete_project, { nowait = true, })

      map('n', ';', live_grep_cur, { nowait = true, })
      map('i', '<f1>', live_grep_cur, { nowait = true, })

      map('n', '<c-;>', live_grep_root, { nowait = true, })
      map('i', '<c-f1>', live_grep_root, { nowait = true, })

      map('n', 'b', git_status, { nowait = true, })
      map('i', '<F6>', git_status, { nowait = true, })

      map('n', '<c-b>', git_status_all, { nowait = true, })
      map('i', '<C-F6>', git_status_all, { nowait = true, })

      map('n', '<c-cr>', find_files_all, { nowait = true, })
      map('i', '<c-cr>', find_files_all, { nowait = true, })

      map('i', '<cr>', find_files_cur, { nowait = true, })

      local on_project_selected = function()
        find_files_cur(prompt_bufnr)
      end
      actions.select_default:replace(on_project_selected)
      return true
    end,
  }):find()
end

return telescope.register_extension {
  exports = {
    my_projects = my_projects,
  },
}
