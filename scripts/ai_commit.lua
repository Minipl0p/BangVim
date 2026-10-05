-- ╭──────────────────────────────────────────────────────────╮
-- │  Commit IA — lancé par lazygit (touche <c-a>)             │
-- │  nvim -l scripts/ai_commit.lua                            │
-- │                                                          │
-- │  1. Lit le diff indexé (stagé)                            │
-- │  2. Demande un message à Claude Code (`claude -p`) selon  │
-- │     la norme du profil                                    │
-- │  3. Ouvre le message dans Neovim pour relecture           │
-- │  4. Commit si tu sauvegardes, annule si tu vides          │
-- ╰──────────────────────────────────────────────────────────╯
local script_dir = vim.fs.dirname(vim.fs.normalize(debug.getinfo(1, "S").source:sub(2)))
local config_dir = vim.fs.dirname(script_dir)
package.path = config_dir .. "/lua/?.lua;" .. config_dir .. "/lua/?/init.lua;" .. package.path

local function out(msg)
  io.stdout:write(msg .. "\n")
  io.stdout:flush()
end

local function fail(msg)
  out(msg)
  os.exit(1)
end

local function run(cmd, stdin)
  local ok, res = pcall(function()
    return vim.system(cmd, { text = true, stdin = stdin }):wait()
  end)
  if not ok then
    return nil, tostring(res)
  end
  return res
end

-- ── 1. Diff indexé ───────────────────────────────────────────
local check = run({ "git", "diff", "--cached", "--quiet" })
if not check then
  fail("Git introuvable.")
end
if check.code == 0 then
  fail("Rien à commiter : aucun fichier indexé (stagé).")
end
local diff = run({ "git", "diff", "--cached", "--stat", "--patch", "--no-color", "--unified=3" }).stdout or ""
-- On limite la taille envoyée (gros fichiers générés, binaires…).
local MAX = 60000
if #diff > MAX then
  diff = diff:sub(1, MAX) .. "\n[… diff tronqué …]"
end

-- ── 2. Norme de commit ───────────────────────────────────────
local profiles = require("core.profiles")
local root = vim.trim((run({ "git", "rev-parse", "--show-toplevel" }) or {}).stdout or "")
profiles.load()
local profile_name = profiles.resolve(root ~= "" and root or vim.uv.cwd())
profiles.init()
profiles.activate(profile_name, false)

local function read(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local c = f:read("*a")
  f:close()
  return c
end

local convention
-- Un fichier .commit-convention.md à la racine du projet a la priorité.
if root ~= "" then
  convention = read(root .. "/.commit-convention.md")
end
if not convention then
  local name = profiles.value("commit.convention") or "conventional-fr"
  convention = read(vim.fn.stdpath("data") .. "/conventions/" .. name .. ".md")
    or read(config_dir .. "/conventions/" .. name .. ".md")
    or read(config_dir .. "/conventions/conventional-fr.md")
end

-- ── 3. Génération ────────────────────────────────────────────
local claude = vim.fn.exepath("claude")
if claude == "" then
  fail("Claude Code (commande `claude`) introuvable dans le PATH.")
end
local cmd = { claude }
if vim.fn.has("win32") == 1 and (claude:lower():match("%.cmd$") or claude:lower():match("%.bat$")) then
  cmd = { "cmd.exe", "/c", claude }
end
vim.list_extend(cmd, { "-p", "Rédige le message de commit décrit dans l'entrée standard." })

local prompt = table.concat({
  "Tu rédiges UN message de commit git pour les modifications ci-dessous.",
  "Respecte strictement la norme suivante :",
  "",
  convention or "",
  "",
  "Règles impératives :",
  "- Réponds uniquement avec le message de commit, sans explication, sans bloc de code, sans guillemets.",
  "- N'ajoute aucune ligne Co-Authored-By, Signed-off-by, ni aucune mention d'IA, de Claude ou d'outil.",
  "",
  "Modifications indexées :",
  diff,
}, "\n")

out("Génération du message de commit…")
local res = run(cmd, prompt)
if not res or res.code ~= 0 then
  fail("Échec de Claude Code : " .. ((res and (res.stderr ~= "" and res.stderr or res.stdout)) or "inconnu"))
end

-- Nettoyage : blocs de code, traces d'IA, espaces.
local lines = {}
for line in (res.stdout or ""):gmatch("[^\r\n]*") do
  local l = line:lower()
  if not line:match("^```") and not l:match("co%-authored%-by") and not l:match("generated with")
    and not l:match("signed%-off%-by") then
    table.insert(lines, line)
  end
end
local message = vim.trim(table.concat(lines, "\n"):gsub("\n\n\n+", "\n\n"))
if message == "" then
  fail("Claude n'a renvoyé aucun message.")
end

-- ── 4. Relecture puis commit ─────────────────────────────────
local tmp = vim.fn.tempname()
local f = assert(io.open(tmp, "w"))
f:write(message .. "\n")
f:close()

-- Git lit GIT_EDITOR avec son propre shell : on entoure le chemin de guillemets simples.
vim.env.GIT_EDITOR = vim.env.AI_COMMIT_EDITOR or ("'" .. vim.v.progpath .. "'")
local code = os.execute(('git commit -e -F "%s"'):format(tmp))
os.remove(tmp)
-- os.execute renvoie true/false (LuaJIT : un code numérique selon les versions).
if code == true or code == 0 then
  os.exit(0)
end
os.exit(1)
