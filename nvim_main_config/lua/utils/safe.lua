-- lua/utils/safe.lua
local M = {}

function M.require(mod)
  local ok, m = pcall(require, mod)
  if not ok then return nil end
  if type(m) == "boolean" then return nil end
  return m
end

function M.call(fn)
  local ok, err = pcall(fn)
  if not ok then
    vim.schedule(function()
      vim.notify(err, vim.log.levels.ERROR)
    end)
  end
end

return M

