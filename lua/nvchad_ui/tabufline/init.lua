local M = {}
local api = vim.api

M.bufilter = function()
  local bufs = vim.t.bufs or nil

  if not bufs then
    return {}
  end

  for i = #bufs, 1, -1 do
    if not api.nvim_buf_is_valid(bufs[i]) then
      table.remove(bufs, i)
    end
  end

  return bufs
end

M.tabuflineNext = function()
  local bufs = M.bufilter() or {}

  for i, v in ipairs(bufs) do
    if api.nvim_get_current_buf() == v then
      vim.cmd(i == #bufs and "b" .. bufs[1] or "b" .. bufs[i + 1])
      break
    end
  end
end

M.tabuflinePrev = function()
  local bufs = M.bufilter() or {}

  for i, v in ipairs(bufs) do
    if api.nvim_get_current_buf() == v then
      vim.cmd(i == 1 and "b" .. bufs[#bufs] or "b" .. bufs[i - 1])
      break
    end
  end
end

M.close_buffer = function(bufnr)
  if vim.bo.buftype == "terminal" then
    vim.cmd(vim.bo.buflisted and "set nobl | enew" or "hide")
  else
    bufnr = bufnr or api.nvim_get_current_buf()
    require("nvchad_ui.tabufline").tabuflinePrev()
    vim.cmd("confirm bd" .. bufnr)
  end
end

-- closes tab + all of its buffers
M.closeAllBufs = function(action)
  local bufs = vim.t.bufs

  if action == "closeTab" then
    vim.cmd "tabclose"
  end

  for _, buf in ipairs(bufs) do
    M.close_buffer(buf)
  end

  if action ~= "closeTab" then
    vim.cmd "enew"
  end
end

M.handle_duplicate_bufnames = function(buf1, buf2)
  buf1, buf2 = api.nvim_buf_get_name(buf1), api.nvim_buf_get_name(buf2)

  -- remove '/' from a str -> split str in a table
  local split_str = function(text)
    local result = {}

    for word in string.gmatch(text, "([^/]+)") do
      result[#result + 1] = word
    end

    return result
  end

  buf1, buf2 = split_str(buf1), split_str(buf2)

  for i = 1, #buf1 do
    if buf1[#buf1 + 1 - i] ~= buf2[#buf2 + 1 - i] then
      return buf1[#buf1 + 1 - i] .. (i == 1 and "/" or "/../") .. buf1[#buf1]
    end
  end
end

M.run = function(opts)
  local modules = require "nvchad_ui.tabufline.modules"

  -- merge user modules :D
  if opts.overriden_modules then
    modules = vim.tbl_deep_extend("force", modules, opts.overriden_modules())
  end

  local defaults = {
    modules.bufferlist(),
    modules.tablist() or "",
    modules.buttons(),
  }

  if vim.g.nvimtree_side == "left" then
    table.insert(defaults, 1, modules.CoverNvimTree())
  else
    table.insert(defaults, modules.CoverNvimTree())
  end

  -- Pass in all the modules, and let users decide their order
  if opts.overriden_table then
    defaults = opts.overriden_table(modules)
  end

  return table.concat(defaults)
end

return M
