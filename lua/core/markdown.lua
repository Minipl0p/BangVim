-- ╭──────────────────────────────────────────────────────────╮
-- │  Aperçu Markdown dans le navigateur (live-preview.nvim)   │
-- │  Mermaid, KaTeX, coloration, scroll synchronisé.          │
-- │  Chrome / Edge / Brave / Chromium : écran partagé auto    │
-- │  (navigateur à droite, WezTerm à gauche).                 │
-- ╰──────────────────────────────────────────────────────────╯
local platform = require("core.platform")
local profiles = require("core.profiles")
local M = {}

M.port = 5500
local running = false
local screen_cache ---@type {w:integer, h:integer}?

-- Noms d'exécutables par navigateur et par plateforme.
local browsers = {
  firefox = { linux = { "firefox" }, windows = "firefox", chromium = false },
  chrome = { linux = { "google-chrome", "google-chrome-stable" }, windows = "chrome", chromium = true },
  edge = { linux = { "microsoft-edge", "microsoft-edge-stable" }, windows = "msedge", chromium = true },
  brave = { linux = { "brave-browser", "brave" }, windows = "brave", chromium = true },
  chromium = { linux = { "chromium", "chromium-browser" }, windows = "chromium", chromium = true },
}
M.choices = { "defaut", "firefox", "chrome", "edge", "brave", "chromium" }

--- Envoie une variable à WezTerm (OSC 1337 SetUserVar) pour qu'il se place à gauche.
local function wezterm_layout(value)
  local seq = ("\27]1337;SetUserVar=%s=%s\7"):format("nvim_layout", vim.base64.encode(value))
  if vim.env.TMUX then
    seq = "\27Ptmux;" .. seq:gsub("\27", "\27\27") .. "\27\\"
  end
  if vim.api.nvim_ui_send then
    pcall(vim.api.nvim_ui_send, seq)
  else
    io.stdout:write(seq)
  end
end

--- Taille de l'écran principal (zone de travail), en pixels logiques.
local function screen()
  if screen_cache then
    return screen_cache
  end
  local w, h
  if platform.is_windows or platform.is_wsl then
    local ps = platform.is_windows and (platform.has("pwsh") and "pwsh" or "powershell") or "powershell.exe"
    local out = vim.fn.system({
      ps, "-NoLogo", "-NoProfile", "-Command",
      "Add-Type -AssemblyName System.Windows.Forms; $a=[System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea; \"$($a.Width) $($a.Height)\"",
    })
    w, h = out:match("(%d+)%s+(%d+)")
  elseif platform.has("xrandr") then
    local out = vim.fn.system({ "xrandr", "--current" })
    w, h = out:match("current (%d+) x (%d+)")
  end
  screen_cache = { w = tonumber(w) or 1920, h = tonumber(h) or 1080 }
  return screen_cache
end

local function open_browser(url, name)
  local def = browsers[name]
  if not def then
    vim.ui.open(url)
    return
  end
  local args = {}
  if def.chromium then
    local s = screen()
    local half = math.floor(s.w / 2)
    -- Profil séparé : force une nouvelle fenêtre qui respecte position et taille.
    local profile_dir = vim.fs.joinpath(vim.fn.stdpath("cache"), "apercu-markdown")
    if platform.is_wsl then
      profile_dir = vim.trim(vim.fn.system({ "wslpath", "-w", profile_dir }))
    end
    args = {
      "--app=" .. url,
      "--new-window",
      ("--window-position=%d,0"):format(half),
      ("--window-size=%d,%d"):format(s.w - half, s.h),
      "--user-data-dir=" .. profile_dir,
    }
    wezterm_layout("left")
  else
    args = { "--new-window", url }
  end

  if platform.is_windows or platform.is_wsl then
    -- Start-Process trouve les navigateurs enregistrés dans Windows (App Paths).
    local quoted = vim.tbl_map(function(a)
      return "'" .. a:gsub("'", "''") .. "'"
    end, args)
    local ps = platform.is_wsl and "powershell.exe" or (platform.has("pwsh") and "pwsh" or "powershell")
    platform.spawn({
      ps, "-NoLogo", "-NoProfile", "-Command",
      ("Start-Process %s -ArgumentList %s"):format(def.windows, table.concat(quoted, ",")),
    }, platform.is_wsl and { cwd = "/mnt/c" } or nil)
    return
  end
  for _, exe in ipairs(def.linux) do
    if platform.has(exe) then
      platform.spawn(vim.list_extend({ exe }, args))
      return
    end
  end
  vim.notify("Navigateur « " .. name .. " » introuvable, ouverture avec le navigateur par défaut.", vim.log.levels.WARN)
  vim.ui.open(url)
end

local function url_encode(s)
  return (s:gsub("[^%w%-%._~/]", function(c)
    return ("%%%02X"):format(c:byte())
  end))
end

function M.start()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" or not file:match("%.md$") and vim.bo.filetype ~= "markdown" then
    vim.notify("Ouvre un fichier Markdown pour l'aperçu.", vim.log.levels.INFO)
    return
  end
  require("livepreview.config").set({ dynamic_root = true, port = M.port, sync_scroll = true })
  require("livepreview").start(file, M.port)
  running = true
  local url = ("http://127.0.0.1:%d/%s"):format(M.port, url_encode(vim.fs.basename(file)))
  open_browser(url, profiles.value("browser") or "defaut")
end

function M.stop()
  pcall(function()
    require("livepreview").close()
  end)
  running = false
  wezterm_layout("restore")
end

function M.toggle()
  local ok, err = pcall(running and M.stop or M.start)
  if not ok then
    vim.notify("Aperçu Markdown impossible :\n" .. tostring(err), vim.log.levels.ERROR)
  end
end

return M
