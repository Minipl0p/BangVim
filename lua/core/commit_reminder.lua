-- ╭──────────────────────────────────────────────────────────╮
-- │  Rappels de commit                                        │
-- │  Compteur discret dans la statusline, une notification    │
-- │  au-delà du seuil, avertissement en quittant.             │
-- │  Hors d'un repo git (Perforce…) : silence total.          │
-- ╰──────────────────────────────────────────────────────────╯
local profiles = require("core.profiles")
local M = {}

M.state = { root = nil, added = 0, removed = 0, files = 0, minutes = 0, level = 0 }
local notified = false
local running = false

local function git_root()
  return vim.fs.root(vim.uv.cwd(), ".git")
end

local function run(root, args)
  local ok, res = pcall(function()
    return vim.system(vim.list_extend({ "git", "-C", root }, args), { text = true }):wait(3000)
  end)
  if not ok or not res or res.code ~= 0 then
    return nil
  end
  return res.stdout or ""
end

local function count_numstat(out, acc)
  for line in (out or ""):gmatch("[^\n]+") do
    local a, r = line:match("^(%S+)%s+(%S+)")
    acc.added = acc.added + (tonumber(a) or 0)
    acc.removed = acc.removed + (tonumber(r) or 0)
  end
end

--- Calcule l'état (synchrone, rapide : git diff --numstat).
function M.compute()
  local root = git_root()
  if not root or vim.fn.executable("git") == 0 then
    M.state = { root = nil, added = 0, removed = 0, files = 0, minutes = 0, level = 0 }
    return M.state
  end
  local acc = { added = 0, removed = 0 }
  local has_head = run(root, { "rev-parse", "--verify", "-q", "HEAD" }) ~= nil
  if has_head then
    count_numstat(run(root, { "diff", "HEAD", "--numstat" }), acc)
  else
    count_numstat(run(root, { "diff", "--numstat" }), acc)
    count_numstat(run(root, { "diff", "--cached", "--numstat" }), acc)
  end
  local status = run(root, { "status", "--porcelain" }) or ""
  local files = select(2, status:gsub("\n", "\n"))

  local minutes = 0
  if has_head and files > 0 then
    local ts = tonumber(vim.trim(run(root, { "log", "-1", "--format=%ct" }) or ""))
    if ts then
      minutes = math.floor((os.time() - ts) / 60)
    end
  end

  local lines = acc.added + acc.removed
  local max_lines = profiles.value("commit.reminder_lines") or 150
  local max_min = profiles.value("commit.reminder_minutes") or 30
  local level = 0
  if files > 0 then
    if lines >= max_lines or minutes >= max_min then
      level = 2
    elseif lines >= max_lines / 2 or minutes >= max_min / 2 then
      level = 1
    end
  end
  M.state = { root = root, added = acc.added, removed = acc.removed, files = files, minutes = minutes, level = level }
  return M.state
end

function M.refresh()
  if running then
    return
  end
  running = true
  vim.schedule(function()
    local ok = pcall(M.compute)
    running = false
    if not ok then
      return
    end
    local s = M.state
    if s.level == 2 and not notified then
      notified = true
      vim.notify(
        ("%d lignes modifiées sur %d fichier(s) depuis le dernier commit."):format(s.added + s.removed, s.files),
        vim.log.levels.WARN,
        { title = "Pense à commiter" }
      )
    elseif s.level < 2 then
      notified = false
    end
    pcall(function()
      require("lualine").refresh()
    end)
  end)
end

--- Texte affiché dans la statusline (vide hors git ou sans modifs).
function M.status()
  local s = M.state
  if not s.root or s.files == 0 then
    return ""
  end
  return ("+%d −%d · %d fichier%s"):format(s.added, s.removed, s.files, s.files > 1 and "s" or "")
end

function M.color()
  local s = M.state
  if s.level == 2 then
    return { fg = "#fab387" } -- orange (peach)
  elseif s.level == 1 then
    return { fg = "#f9e2af" } -- jaune
  end
  return nil
end

--- Avant de quitter : true = on peut quitter.
function M.confirm_quit()
  local ok = pcall(M.compute)
  local s = M.state
  if not ok or not s.root or s.files == 0 then
    return true
  end
  local choice = vim.fn.confirm(
    ("Modifs non commitées : %s.\nQuitter quand même ?"):format(M.status()),
    "&Quitter\n&Annuler",
    2
  )
  return choice == 1
end

function M.setup()
  local group = vim.api.nvim_create_augroup("RappelCommit", { clear = true })
  vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained", "DirChanged", "VimEnter" }, {
    group = group,
    callback = M.refresh,
  })
  vim.api.nvim_create_autocmd("User", { group = group, pattern = "ProfilChange", callback = M.refresh })
  -- Le temps passe aussi sans sauvegarder : petite vérification chaque minute.
  local timer = vim.uv.new_timer()
  if timer then
    timer:start(60000, 60000, M.refresh)
  end
end

return M
