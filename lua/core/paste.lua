-- Collage via yanky avec indentation automatique pour les lignes entières.
local M = {}

---@param where "After"|"Before"
function M.put(where)
  local mode = vim.fn.mode()
  if mode:match("[vV\22]") then
    return "<Plug>(YankyPut" .. where .. ")"
  end
  local regtype = vim.fn.getregtype(vim.v.register)
  if regtype == "V" then
    -- Lignes entières : on aligne l'indentation sur la ligne courante.
    return "<Plug>(YankyPutIndent" .. where .. "Linewise)"
  end
  return "<Plug>(YankyPut" .. where .. ")"
end

return M
