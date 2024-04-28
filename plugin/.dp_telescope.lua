require 'dp_telescope'
local t = vim.fn.reltimefloat(vim.fn.reltime(StartTime))
if not StartTimeList then
  StartTimeList = {}
end
StartTimeList[#StartTimeList+1] = string.format("%.6f: %s", t, vim.fn.fnamemodify(debug.getinfo(1)['source'], ':t:r'))