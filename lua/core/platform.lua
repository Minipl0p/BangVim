-- Détection de la plateforme et petits utilitaires système.
local M = {}

local release = (vim.uv.os_uname().release or ""):lower()

M.is_windows = vim.fn.has("win32") == 1
M.is_wsl = not M.is_windows and (vim.fn.has("wsl") == 1 or release:find("microsoft") ~= nil)
M.is_mac = vim.fn.has("mac") == 1
M.is_linux = not M.is_windows and not M.is_mac

---@param name string
function M.has(name)
  return vim.fn.executable(name) == 1
end

--- Lance une commande détachée, sans bloquer Neovim ni afficher d'erreur.
---@param cmd string[]
---@param opts? table
function M.spawn(cmd, opts)
  opts = vim.tbl_extend("force", { detach = true }, opts or {})
  local ok = pcall(vim.fn.jobstart, cmd, opts)
  return ok
end

--- Préfixe de commande capable de lancer un exécutable (gère les .cmd/.bat sous Windows).
---@param exe string
---@return string[]
function M.cmd_prefix(exe)
  local path = vim.fn.exepath(exe)
  local lower = path:lower()
  if M.is_windows and (lower:match("%.cmd$") or lower:match("%.bat$")) then
    return { "cmd.exe", "/c", path }
  end
  return { path ~= "" and path or exe }
end

return M
