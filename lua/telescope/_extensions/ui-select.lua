-- Copyright (c) 2024 liudepei. All Rights Reserved.
-- create at 2024/04/04 00:07:07 星期四

local B = require 'dp_base'

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require 'telescope.config'.values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'
local strings = require 'plenary.strings'
local entry_display = require 'telescope.pickers.entry_display'
local utils = require 'telescope.utils'
local previewers = require 'telescope.previewers'

local function send_open_to_qflist(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local manager = picker.manager
  local qf_entries = {}
  for entry in manager:iter() do
    table.insert(qf_entries, { text = entry['ordinal'], })
  end
  actions.close(prompt_bufnr)
  vim.fn.setqflist(qf_entries, 'r')
  vim.cmd [[botright copen]]
end

local function grep_string(prompt_bufnr)
  local selected_entry = action_state.get_selected_entry(prompt_bufnr)
  actions.close(prompt_bufnr)
  local project_path = selected_entry.ordinal
  if not B.file_exists(project_path) then
    return
  end
  if B.is_file(project_path) then
    project_path = B.file_parent(project_path)
  end
  local cmd = B.format('Telescope grep_string shorten_path=true word_match=-w only_sort_text=true search= cwd=%s', project_path)
  B.cmd(cmd)
  B.notify_info('Telescope grep_string cwd=' .. project_path)
end

local function live_grep(prompt_bufnr)
  local selected_entry = action_state.get_selected_entry(prompt_bufnr)
  actions.close(prompt_bufnr)
  local project_path = selected_entry.ordinal
  if not B.file_exists(project_path) then
    return
  end
  if B.is_file(project_path) then
    project_path = B.file_parent(project_path)
  end
  local cmd = B.format('Telescope live_grep cwd=%s', project_path)
  B.cmd(cmd)
  B.notify_info(cmd)
end

local function find_files(prompt_bufnr)
  local selected_entry = action_state.get_selected_entry(prompt_bufnr)
  actions.close(prompt_bufnr)
  local project_path = selected_entry.ordinal
  if not B.file_exists(project_path) then
    return
  end
  if B.is_file(project_path) then
    project_path = B.file_parent(project_path)
  end
  local cmd = B.format('Telescope find_files cwd=%s', project_path)
  B.cmd(cmd)
  B.notify_info(cmd)
end

local function explorer(prompt_bufnr)
  local selected_entry = action_state.get_selected_entry(prompt_bufnr)
  actions.close(prompt_bufnr)
  local project_path = selected_entry.ordinal
  if not B.file_exists(project_path) then
    return
  end
  if B.is_file(project_path) then
    project_path = B.file_parent(project_path)
  end
  B.system_run('start silent', 'explorer %s', project_path)
end

local function open(prompt_bufnr)
  local selected_entry = action_state.get_selected_entry(prompt_bufnr)
  actions.close(prompt_bufnr)
  local project_path = selected_entry.ordinal
  if B.is_file(project_path) then
    B.cmd('e %s', project_path)
  elseif B.is_dir(project_path) then
    B.system_run('start silent', 'explorer %s', project_path)
  end
end

local function remove_selected_items(prompt_bufnr)
  local picker = action_state.get_current_picker(prompt_bufnr)
  local selections = picker:get_multi_selection()
  for _, selection in ipairs(selections) do
    table.remove(Ui_sel_items, selection.index)
  end
  actions.close(prompt_bufnr)
  vim.ui.select(Ui_sel_items, Ui_sel_opts, Ui_sel_on_choice)
end

local function multi_selection(prompt_bufnr, cb)
  local picker = action_state.get_current_picker(prompt_bufnr)
  actions.close(prompt_bufnr)
  local selections = picker:get_multi_selection()
  for _, selection in ipairs(selections) do
    cb(Ui_sel_items[selection.value.idx], selection.value.idx)
  end
end

return require 'telescope'.register_extension {
  setup = function(topts)
    local specific_opts = vim.F.if_nil(topts.specific_opts, {})
    topts.specific_opts = nil

    if #topts == 1 and topts[1] ~= nil then
      topts = topts[1]
    end

    __TelescopeUISelectSpecificOpts = vim.F.if_nil(
      __TelescopeUISelectSpecificOpts,
      vim.tbl_extend('keep', specific_opts, {
        ['codeaction'] = {
          make_indexed = function(items)
            local indexed_items = {}
            local widths = {
              idx = 0,
              command_title = 0,
              client_name = 0,
            }
            for idx, item in ipairs(items) do
              local client_id, title
              if vim.version and vim.version.cmp(vim.version(), vim.version.parse '0.10-dev') >= 0 then
                client_id = item.ctx.client_id
                title = item.action.title
              else
                client_id = item[1]
                title = item[2].title
              end

              local client = vim.lsp.get_client_by_id(client_id)

              local entry = {
                idx = idx,
                ['add'] = {
                  command_title = title:gsub('\r\n', '\\r\\n'):gsub('\n', '\\n'),
                  client_name = client and client.name or '',
                },
                text = item,
              }
              table.insert(indexed_items, entry)
              widths.idx = math.max(widths.idx, strings.strdisplaywidth(entry.idx))
              widths.command_title = math.max(widths.command_title, strings.strdisplaywidth(entry.add.command_title))
              widths.client_name = math.max(widths.client_name, strings.strdisplaywidth(entry.add.client_name))
            end
            return indexed_items, widths
          end,
          make_displayer = function(widths)
            return entry_display.create {
              separator = ' ',
              items = {
                { width = widths.idx + 1, }, -- +1 for ":" suffix
                { width = widths.command_title, },
                { width = widths.client_name, },
              },
            }
          end,
          make_display = function(displayer)
            return function(e)
              return displayer {
                { e.value.idx .. ':',        'TelescopePromptPrefix', },
                { e.value.add.command_title, },
                { e.value.add.client_name,   'TelescopeResultsComment', },
              }
            end
          end,
          make_ordinal = function(e)
            return e.idx .. e.add['command_title']
          end,
        },
      })
    )

    vim.ui.select = function(items, opts, on_choice)
      opts = opts or {}
      local prompt = vim.F.if_nil(opts.prompt, 'Select one of')
      if prompt:sub(-1, -1) == ':' then
        prompt = prompt:sub(1, -2)
      end
      opts.format_item = vim.F.if_nil(opts.format_item, function(e)
        return tostring(e)
      end)

      -- schedule_wrap because closing the windows is deferred
      -- See https://github.com/nvim-telescope/telescope.nvim/pull/2336
      -- And we only want to dispatch the callback when we're back in the original win

      Ui_sel_on_choice = on_choice
      Ui_sel_opts = opts
      Ui_sel_items = items

      on_choice = vim.schedule_wrap(on_choice)

      local short_items = {}
      for _, item in ipairs(items) do
        item = string.gsub(item, '\n', '\\n')
        short_items[#short_items + 1] = B.get_short(item)
      end

      -- We want or here because __TelescopeUISelectSpecificOpts[x] can be either nil or even false -> {}
      local sopts = __TelescopeUISelectSpecificOpts[vim.F.if_nil(opts.kind, '')] or {}
      local indexed_items, widths = vim.F.if_nil(sopts.make_indexed, function(items_)
        local indexed_items = {}
        for idx, item in ipairs(items_) do
          table.insert(indexed_items, { idx = idx, text = item, })
        end
        return indexed_items
      end)(short_items)
      local displayer = vim.F.if_nil(sopts.make_displayer, function() end)(widths)
      local make_display = vim.F.if_nil(sopts.make_display, function(_)
        return function(e)
          local x, _ = opts.format_item(e.value.text)
          return x
        end
      end)(displayer)
      local make_ordinal = vim.F.if_nil(sopts.make_ordinal, function(e)
        return opts.format_item(e.text)
      end)
      pickers
          .new(topts, {
            prompt_title = string.gsub(prompt, '\n', ' '),
            finder = finders.new_table {
              results = indexed_items,
              entry_maker = function(e)
                return {
                  value = e,
                  display = make_display,
                  ordinal = make_ordinal(e),
                }
              end,
            },
            attach_mappings = function(prompt_bufnr, map)
              map('n', '<C-Tab>', send_open_to_qflist, { nowait = true, })
              map('i', '<C-Tab>', send_open_to_qflist, { nowait = true, })

              map('n', ';', live_grep, { nowait = true, })
              map('i', '<f1>', live_grep, { nowait = true, })

              map('n', 'n', find_files, { nowait = true, })
              map('i', '<F7>', find_files, { nowait = true, })

              map('n', 'm', explorer, { nowait = true, })
              map('i', '<f8>', explorer, { nowait = true, })

              map('n', 'c', grep_string, { nowait = true, })
              map('i', '<F4>', grep_string, { nowait = true, })

              map('n', 'o', open, { nowait = true, })
              map('i', '<c-o>', open, { nowait = true, })

              map('n', 'dd', remove_selected_items, { nowait = true, })
              map('i', '<a-d>', remove_selected_items, { nowait = true, })

              actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                local cb = on_choice
                on_choice = function(_, _) end
                if selection == nil then
                  actions.close(prompt_bufnr)
                  utils.__warn_no_selection 'ui-select'
                  cb(nil, nil)
                  return
                end
                if opts.multi_en then
                  multi_selection(prompt_bufnr, cb)
                  return
                end
                actions.close(prompt_bufnr)
                cb(items[selection.value.idx], selection.value.idx)
              end)
              actions.close:enhance {
                post = function()
                  on_choice(nil, nil)
                end,
              }
              return true
            end,
            sorter = conf.generic_sorter(topts),
            previewer = previewers.new_buffer_previewer {
              dyn_title = function(_, entry)
                return entry.title
              end,
              define_preview = function(self, entry, status)
                local val = items[entry.index]
                local lines = {}
                if B.is(val) and B.is_file(val) and not B.is_detected_as_bin(val) then
                  lines = vim.fn.readfile(val)
                  entry.title = val
                else
                  lines = vim.split(items[entry.index], '\n')
                  entry.title = ''
                end
                if self.state then
                  vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
                end
              end,
            },
          })
          :find()
    end
  end,
}
