-- Suggestions IA en texte grisé (NeoCodeium) + repli sur le comportement normal.
local M = {}

local function nc()
  local ok, mod = pcall(require, "neocodeium")
  if ok and mod.visible() then
    return mod
  end
end

local function fallback(key)
  vim.api.nvim_feedkeys(vim.keycode(key), "n", false)
end

function M.accept()
  local mod = nc()
  if mod then
    return mod.accept()
  end
  if vim.snippet.active({ direction = 1 }) then
    return vim.snippet.jump(1)
  end
  fallback("<Tab>")
end

function M.accept_word()
  local mod = nc()
  if mod then
    return mod.accept_word()
  end
end

function M.accept_line()
  local mod = nc()
  if mod then
    return mod.accept_line()
  end
  fallback("<C-j>")
end

function M.cycle()
  local ok, mod = pcall(require, "neocodeium")
  if ok then
    mod.cycle_or_complete(1)
  end
end

function M.clear()
  local ok, mod = pcall(require, "neocodeium")
  if ok then
    mod.clear()
  end
end

--- Active ou coupe les suggestions selon le profil.
function M.set_enabled(on)
  -- Si NeoCodeium n'est pas encore chargé, il lira le profil à son démarrage.
  if not package.loaded["neocodeium"] then
    return
  end
  pcall(vim.cmd, "NeoCodeium " .. (on and "enable" or "disable"))
end

return M
