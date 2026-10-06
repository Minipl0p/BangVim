-- Config lazygit propre à Neovim : ajoute la touche « commit IA ».
-- Écrit un petit fichier YAML et l'ajoute à LG_CONFIG_FILE (la config lazygit
-- personnelle éventuelle reste prise en compte).
local M = {}

M.path = vim.fs.joinpath(vim.fn.stdpath("cache"), "lazygit-commit-ia.yml")

local function yaml_str(s)
  return "'" .. s:gsub("'", "''") .. "'"
end

function M.write()
  local key = require("core.keys").get("ai_commit") or "<c-a>"
  local script = vim.fs.joinpath(vim.fn.stdpath("config"), "scripts", "ai_commit.lua")
  -- Sous Windows, lazygit passe par `cmd /c`, qui casse les commandes commençant
  -- par un guillemet : on n'en met que si le chemin contient un espace.
  local function q(path)
    return path:find(" ") and ('"' .. path .. '"') or path
  end
  local nvim = vim.fn.executable("nvim") == 1 and "nvim" or vim.v.progpath
  local command = q(nvim) .. " -l " .. q(script)
  local lines = {
    "customCommands:",
    "  - key: " .. yaml_str(key),
    "    context: 'files'",
    "    description: 'Commit avec message généré par IA'",
    "    output: terminal",
    "    command: " .. yaml_str(command),
  }
  vim.fn.mkdir(vim.fs.dirname(M.path), "p")
  vim.fn.writefile(lines, M.path)
end

function M.setup()
  M.write()
  -- Fichiers de config lazygit : la config perso (si elle existe) + la nôtre.
  -- snacks.nvim ajoutera ensuite son fichier de thème.
  local files = {}
  if vim.env.LG_CONFIG_FILE and vim.env.LG_CONFIG_FILE ~= "" then
    files = vim.split(vim.env.LG_CONFIG_FILE, ",", { plain = true, trimempty = true })
  elseif vim.fn.executable("lazygit") == 1 then
    local out = vim.fn.system({ "lazygit", "-cd" })
    local dir = vim.v.shell_error == 0 and vim.trim(vim.split(out, "\n")[1] or "") or ""
    local user_cfg = dir ~= "" and vim.fs.joinpath(dir, "config.yml") or nil
    if user_cfg and vim.uv.fs_stat(user_cfg) then
      table.insert(files, user_cfg)
    end
  end
  if not vim.tbl_contains(files, M.path) then
    table.insert(files, M.path)
  end
  vim.env.LG_CONFIG_FILE = table.concat(files, ",")
end

return M
