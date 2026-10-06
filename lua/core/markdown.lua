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

--- Commande qui ouvre l'URL dans le navigateur choisi (nil = navigateur par défaut du système).
---@return string[]|nil cmd, table|nil opts, boolean chromium
local function browser_cmd(url, name)
  local def = browsers[name]
  if not def then
    return nil, nil, false
  end
  local args
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
  else
    args = { "--new-window", url }
  end

  if platform.is_windows or platform.is_wsl then
    -- Start-Process trouve les navigateurs enregistrés dans Windows (App Paths).
    local quoted = vim.tbl_map(function(a)
      return "'" .. a:gsub("'", "''") .. "'"
    end, args)
    local ps = platform.is_wsl and "powershell.exe" or (platform.has("pwsh") and "pwsh" or "powershell")
    return {
      ps, "-NoLogo", "-NoProfile", "-Command",
      ("Start-Process %s -ArgumentList %s"):format(def.windows, table.concat(quoted, ",")),
    }, platform.is_wsl and { cwd = "/mnt/c" } or nil, def.chromium
  end
  for _, exe in ipairs(def.linux) do
    if platform.has(exe) then
      return vim.list_extend({ exe }, args), nil, def.chromium
    end
  end
  return nil, nil, false
end

local function open_browser(url, name)
  local cmd, opts, chromium = browser_cmd(url, name)
  if not cmd then
    if browsers[name] then
      vim.notify("Navigateur « " .. name .. " » introuvable, ouverture avec le navigateur par défaut.", vim.log.levels.WARN)
    end
    vim.ui.open(url)
    return
  end
  if chromium then
    wezterm_layout("left")
  end
  platform.spawn(cmd, opts)
end

--- Premier port libre à partir de `start` (5500 est souvent pris par Live Server de VS Code).
local function free_port(start)
  for port = start, start + 20 do
    local tcp = vim.uv.new_tcp()
    if tcp then
      local ok = tcp:bind("127.0.0.1", port) == 0 and tcp:listen(1, function() end) == 0
      tcp:close()
      if ok then
        return port
      end
    end
  end
  return start
end

local function url_encode(s)
  return (s:gsub("[^%w%-%._~/]", function(c)
    return ("%%%02X"):format(c:byte())
  end))
end

local function is_markdown(file)
  return file ~= "" and (file:match("%.md$") or vim.bo.filetype == "markdown")
end

local function url_for(file, port)
  return ("http://127.0.0.1:%d/%s"):format(port, url_encode(vim.fs.basename(vim.fs.normalize(file))))
end

function M.start()
  local file = vim.api.nvim_buf_get_name(0)
  if not is_markdown(file) then
    vim.notify("Ouvre un fichier Markdown pour l'aperçu.", vim.log.levels.INFO)
    return
  end
  local port = free_port(M.port)
  require("livepreview.config").set({ dynamic_root = true, port = port, sync_scroll = true })
  require("livepreview").start(vim.fs.normalize(file), port)
  running = true
  open_browser(url_for(file, port), profiles.value("browser") or "defaut")
end

--- :MarkdownDiag — teste chaque étape de l'aperçu et affiche un rapport à copier.
function M.diag()
  local lines = { "# Diagnostic de l'aperçu Markdown", "" }
  local function add(ok, label, detail)
    table.insert(lines, ("%s %s%s"):format(ok and "[OK]   " or "[ÉCHEC]", label, detail and (" : " .. detail) or ""))
  end
  local file = vim.api.nvim_buf_get_name(0)
  add(is_markdown(file), "Fichier Markdown", file ~= "" and file or "aucun fichier")
  add(true, "Plateforme", platform.is_windows and "Windows" or platform.is_wsl and "WSL" or "Linux/macOS")

  local ok_plugin, lp = pcall(require, "livepreview")
  add(ok_plugin, "Plugin live-preview", not ok_plugin and tostring(lp) or nil)

  local port = free_port(M.port)
  add(true, "Port", port == M.port and tostring(port) or (M.port .. " occupé, utilisation de " .. port))

  if ok_plugin and is_markdown(file) then
    local ok_start, err = pcall(function()
      require("livepreview.config").set({ dynamic_root = true, port = port, sync_scroll = true })
      lp.start(vim.fs.normalize(file), port)
    end)
    add(ok_start, "Démarrage du serveur", not ok_start and tostring(err) or nil)

    local url = url_for(file, port)
    add(true, "Adresse", url)
    vim.wait(300)
    local curl = platform.is_windows and "curl.exe" or "curl"
    if platform.has(curl) then
      local res = vim.system({ curl, "-s", "-m", "5", "-H", "Accept: text/html", "-w", "\n%{http_code}", url }, { text = true }):wait()
      local body = res.stdout or ""
      local code = body:match("(%d+)%s*$") or "?"
      add(code == "200", "Réponse HTTP", "code " .. code .. ", " .. #body .. " octets"
        .. (res.stderr ~= "" and (", " .. res.stderr) or ""))
      add(body:find("mermaid") ~= nil, "Mermaid dans la page")
    else
      add(false, "Réponse HTTP", "curl introuvable, test impossible")
    end

    local name = profiles.value("browser") or "defaut"
    local cmd, opts = browser_cmd(url, name)
    add(true, "Navigateur choisi", name)
    if cmd then
      table.insert(lines, "        commande : " .. table.concat(cmd, " "))
      local res = vim.system(cmd, vim.tbl_extend("force", { text = true }, opts or {})):wait(10000)
      add(res.code == 0, "Lancement du navigateur", "code " .. tostring(res.code)
        .. ((res.stderr or "") ~= "" and ("\n        " .. res.stderr:gsub("\n", "\n        ")) or ""))
    else
      local ok_open, err = pcall(vim.ui.open, url)
      add(ok_open, "Ouverture avec le navigateur par défaut", not ok_open and tostring(err) or nil)
    end
    running = true
  end

  table.insert(lines, "")
  table.insert(lines, "Copie ce rapport (ggyG) et envoie-le. q pour fermer.")
  vim.cmd("botright new")
  local buf = vim.api.nvim_get_current_buf()
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(table.concat(lines, "\n"), "\n"))
  vim.bo[buf].filetype = "markdown"
  vim.keymap.set("n", "q", "<Cmd>close<CR>", { buffer = buf })
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
