-- ╭──────────────────────────────────────────────────────────╮
-- │  Profils : tout ce qui est réglable dans :Param           │
-- │  Enregistrés en local dans  <data>/profils.json           │
-- ╰──────────────────────────────────────────────────────────╯
-- Ce module n'utilise aucun plugin : il est aussi chargé par le script
-- de commit IA (scripts/ai_commit.lua), lancé en dehors de l'éditeur.
local M = {}

local is_windows = vim.fn.has("win32") == 1

M.path = vim.fs.joinpath(vim.fn.stdpath("data"), "profils.json")

-- Valeurs par défaut d'un profil. Toute clé absente d'un profil prend cette valeur.
M.defaults = {
  theme = "catppuccin-mocha",
  format_on_save = true,
  formatters = {}, -- [filetype] = nom du formateur ("" ou absent = celui par défaut)
  ai_completion = true,
  smear_cursor = true,
  boom = false,
  debug_layout = "panneaux", -- "panneaux" | "flottant"
  browser = "defaut", -- "defaut" | "firefox" | "chrome" | "edge" | "brave" | "chromium"
  commit = {
    convention = "conventional-fr", -- nom d'un fichier de conventions/ (sans .md)
    reminder_lines = 150,
    reminder_minutes = 30,
  },
  keys = {}, -- [id d'action] = touche personnalisée
}

---@class ProfilsState
---@field last string
---@field associations table<string, string>
---@field profiles table<string, table>
local state ---@type ProfilsState
local active ---@type string

local function read_json(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local content = f:read("*a")
  f:close()
  local ok, data = pcall(vim.json.decode, content, { luanil = { object = true, array = true } })
  return ok and type(data) == "table" and data or nil
end

--- Normalise un dossier pour servir de clé d'association.
function M.dir_key(dir)
  local key = vim.fs.normalize(vim.fn.fnamemodify(dir, ":p")):gsub("/$", "")
  if is_windows then
    key = key:lower()
  end
  return key
end

function M.load()
  state = read_json(M.path) or {}
  state.profiles = state.profiles or {}
  state.associations = state.associations or {}
  if vim.tbl_isempty(state.profiles) then
    state.profiles["Perso"] = vim.deepcopy(M.defaults)
  end
  if not state.last or not state.profiles[state.last] then
    state.last = M.list()[1]
  end
  return state
end

function M.save()
  vim.fn.mkdir(vim.fs.dirname(M.path), "p")
  local f = io.open(M.path, "w")
  if not f then
    vim.notify("Impossible d'écrire " .. M.path, vim.log.levels.ERROR)
    return
  end
  f:write(vim.json.encode(state))
  f:close()
end

--- Profil à utiliser pour un dossier : association du dossier (ou d'un parent),
--- sinon le dernier profil utilisé.
function M.resolve(dir)
  local key = M.dir_key(dir or vim.uv.cwd())
  local best, best_len = nil, -1
  for path, name in pairs(state.associations) do
    if state.profiles[name] and (key == path or key:sub(1, #path + 1) == path .. "/") and #path > best_len then
      best, best_len = name, #path
    end
  end
  return best or state.last
end

function M.init()
  M.load()
  active = M.resolve()
end

function M.name()
  return active
end

function M.list()
  local names = vim.tbl_keys(state.profiles)
  table.sort(names)
  return names
end

--- Profil actif complété par les valeurs par défaut.
function M.get()
  return vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), state.profiles[active] or {})
end

--- Lit une valeur du profil actif : M.value("commit.convention")
function M.value(path)
  local v = M.get()
  for part in path:gmatch("[^.]+") do
    if type(v) ~= "table" then
      return nil
    end
    v = v[part]
  end
  return v
end

local function changed(key)
  vim.api.nvim_exec_autocmds("User", { pattern = "ProfilChange", data = { key = key } })
end

--- Modifie une valeur du profil actif, l'enregistre et prévient la config.
function M.set(path, value)
  local p = state.profiles[active]
  local parts = vim.split(path, ".", { plain = true })
  for i = 1, #parts - 1 do
    p[parts[i]] = type(p[parts[i]]) == "table" and p[parts[i]] or {}
    p = p[parts[i]]
  end
  p[parts[#parts]] = value
  M.save()
  changed(path)
end

--- Active un profil. remember = true : il devient le « dernier profil utilisé ».
function M.activate(name, remember)
  if not state.profiles[name] then
    return
  end
  active = name
  if remember ~= false then
    state.last = name
    M.save()
  end
  changed("*")
end

function M.create(name, copy_from)
  if state.profiles[name] then
    return false
  end
  state.profiles[name] = vim.deepcopy(copy_from and state.profiles[copy_from] or M.defaults)
  M.save()
  return true
end

function M.rename(old, new)
  if not state.profiles[old] or state.profiles[new] then
    return false
  end
  state.profiles[new], state.profiles[old] = state.profiles[old], nil
  for dir, name in pairs(state.associations) do
    if name == old then
      state.associations[dir] = new
    end
  end
  if state.last == old then
    state.last = new
  end
  if active == old then
    active = new
  end
  M.save()
  changed("*")
  return true
end

function M.delete(name)
  if #M.list() <= 1 or not state.profiles[name] then
    return false
  end
  state.profiles[name] = nil
  for dir, n in pairs(state.associations) do
    if n == name then
      state.associations[dir] = nil
    end
  end
  if state.last == name then
    state.last = M.list()[1]
  end
  if active == name then
    M.activate(state.last)
  else
    M.save()
  end
  return true
end

function M.association(dir)
  return state.associations[M.dir_key(dir or vim.uv.cwd())]
end

function M.associate(dir, name)
  state.associations[M.dir_key(dir or vim.uv.cwd())] = name
  M.save()
end

function M.dissociate(dir)
  state.associations[M.dir_key(dir or vim.uv.cwd())] = nil
  M.save()
end

return M
