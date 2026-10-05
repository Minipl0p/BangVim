-- ╭──────────────────────────────────────────────────────────╮
-- │  :Param — fenêtre des paramètres et des profils           │
-- │  Entrée / l : modifier   r : touche par défaut   q : fermer│
-- ╰──────────────────────────────────────────────────────────╯
local profiles = require("core.profiles")
local keys = require("core.keys")
local M = {}

local ns = vim.api.nvim_create_namespace("param")
local WIDTH = 78
local ui = { buf = nil, win = nil, items = {} }

local function onoff(v)
  return v and "activé" or "désactivé"
end

local function rerender()
  if ui.win and vim.api.nvim_win_is_valid(ui.win) then
    M.render()
  end
end

local function input(prompt, default, cb)
  vim.ui.input({ prompt = prompt, default = default }, function(v)
    if v ~= nil then
      cb(v)
    end
    vim.schedule(rerender)
  end)
end

local function select(list, prompt, cb, fmt)
  vim.ui.select(list, { prompt = prompt, format_item = fmt }, function(choice)
    if choice ~= nil then
      cb(choice)
    end
    vim.schedule(rerender)
  end)
end

-- ── Actions ──────────────────────────────────────────────────
local function toggle(path)
  return function()
    profiles.set(path, not profiles.value(path))
  end
end

local function choose(path, list, prompt)
  return function()
    select(list, prompt, function(v)
      profiles.set(path, v)
    end)
  end
end

local function number(path, prompt)
  return function()
    input(prompt, tostring(profiles.value(path) or ""), function(v)
      local n = tonumber(v)
      if n and n > 0 then
        profiles.set(path, math.floor(n))
      else
        vim.notify("Entre un nombre positif.", vim.log.levels.WARN)
      end
    end)
  end
end

local function conventions()
  local found, seen = {}, {}
  for _, dir in ipairs({ vim.fn.stdpath("data") .. "/conventions", vim.fn.stdpath("config") .. "/conventions" }) do
    for _, f in ipairs(vim.fn.glob(dir .. "/*.md", true, true)) do
      local name = vim.fn.fnamemodify(f, ":t:r")
      if not seen[name] then
        seen[name] = f
        table.insert(found, name)
      end
    end
  end
  table.sort(found)
  return found, seen
end

local function edit_convention()
  local _, paths = conventions()
  local name = profiles.value("commit.convention")
  local path = paths[name]
  if not path then
    return
  end
  -- Les normes livrées avec la config sont copiées dans <data> avant modification.
  local user_dir = vim.fn.stdpath("data") .. "/conventions"
  if not vim.startswith(vim.fs.normalize(path), vim.fs.normalize(user_dir)) then
    vim.fn.mkdir(user_dir, "p")
    local copy = user_dir .. "/" .. name .. ".md"
    vim.fn.writefile(vim.fn.readfile(path), copy)
    path = copy
  end
  M.close()
  vim.cmd.edit(vim.fn.fnameescape(path))
end

local function new_convention()
  input("Nom de la nouvelle norme : ", "", function(name)
    name = vim.trim(name):gsub("[^%w%-_]", "-")
    if name == "" then
      return
    end
    local dir = vim.fn.stdpath("data") .. "/conventions"
    vim.fn.mkdir(dir, "p")
    local path = dir .. "/" .. name .. ".md"
    if not vim.uv.fs_stat(path) then
      local base = vim.fn.stdpath("config") .. "/conventions/conventional-fr.md"
      vim.fn.writefile(vim.fn.readfile(base), path)
    end
    profiles.set("commit.convention", name)
    M.close()
    vim.cmd.edit(vim.fn.fnameescape(path))
  end)
end

local function pick_theme()
  M.close()
  Snacks.picker.colorschemes({
    confirm = function(picker, item)
      picker:close()
      if item then
        vim.schedule(function()
          profiles.set("theme", item.text)
          M.open()
        end)
      end
    end,
  })
end

local function pick_formatter()
  local format = require("core.format")
  local fts = vim.tbl_filter(function(ft)
    return #format.by_ft[ft] > 1
  end, vim.tbl_keys(format.by_ft))
  table.sort(fts)
  select(fts, "Langage", function(ft)
    vim.schedule(function()
      local list = format.by_ft[ft]
      select(list, "Formateur pour " .. ft, function(choice)
        profiles.set("formatters." .. ft, choice == list[1] and "" or choice)
      end, function(item)
        return item == "lsp" and "lsp (serveur de langage)" or item
      end)
    end)
  end, function(ft)
    return ("%-16s → %s"):format(ft, format.chosen(ft))
  end)
end

local function edit_key(a)
  return function()
    input(("Touche pour « %s » (ex. <C-x>, <leader>t) : "):format(a.desc), keys.get(a.id), function(v)
      v = vim.trim(v)
      if v == "" then
        return
      end
      for _, other in ipairs(keys.actions) do
        if other.id ~= a.id and keys.get(other.id) == v and other.scope == a.scope then
          local m1 = type(a.mode) == "table" and a.mode or { a.mode }
          local m2 = type(other.mode) == "table" and other.mode or { other.mode }
          for _, m in ipairs(m1) do
            if vim.tbl_contains(m2, m) then
              vim.notify(("« %s » est déjà utilisée par « %s »."):format(v, other.desc), vim.log.levels.WARN)
            end
          end
        end
      end
      profiles.set("keys." .. a.id, v ~= a.key and v or nil)
    end)
  end
end

local function profile_actions()
  local name = profiles.name()
  return {
    choose = function()
      select(profiles.list(), "Profil", function(v)
        profiles.activate(v)
      end)
    end,
    new = function()
      input("Nom du nouveau profil : ", "", function(v)
        v = vim.trim(v)
        if v ~= "" and profiles.create(v) then
          profiles.activate(v)
        end
      end)
    end,
    duplicate = function()
      input("Nom de la copie : ", name .. " (copie)", function(v)
        v = vim.trim(v)
        if v ~= "" and profiles.create(v, name) then
          profiles.activate(v)
        end
      end)
    end,
    rename = function()
      input("Nouveau nom : ", name, function(v)
        v = vim.trim(v)
        if v ~= "" and v ~= name and not profiles.rename(name, v) then
          vim.notify("Ce nom existe déjà.", vim.log.levels.WARN)
        end
      end)
    end,
    delete = function()
      if #profiles.list() <= 1 then
        vim.notify("Impossible de supprimer le seul profil.", vim.log.levels.WARN)
        return
      end
      if vim.fn.confirm("Supprimer le profil « " .. name .. " » ?", "&Supprimer\n&Annuler", 2) == 1 then
        profiles.delete(name)
        rerender()
      end
    end,
    associate = function()
      if profiles.association() then
        profiles.dissociate()
      else
        profiles.associate(nil, name)
      end
      rerender()
    end,
  }
end

-- ── Contenu ──────────────────────────────────────────────────
local function build()
  local p = profiles.get()
  local list = {}
  local function H(text)
    table.insert(list, { kind = "header", text = text })
  end
  local function S(text)
    table.insert(list, { kind = "sub", text = text })
  end
  local function I(label, value, action, extra)
    table.insert(list, vim.tbl_extend("force", { kind = "item", label = label, value = value or "", action = action }, extra or {}))
  end

  local pa = profile_actions()
  local assoc = profiles.association()
  H("Profil")
  I("Profil actif", profiles.name(), pa.choose)
  I("Associer ce dossier au profil", assoc and ("associé à « " .. assoc .. " »") or "non associé", pa.associate)
  I("Nouveau profil", "", pa.new)
  I("Dupliquer ce profil", "", pa.duplicate)
  I("Renommer ce profil", "", pa.rename)
  I("Supprimer ce profil", "", pa.delete)

  H("Apparence")
  I("Thème", p.theme, pick_theme)
  I("Traînée du curseur", onoff(p.smear_cursor), toggle("smear_cursor"))
  I("Animation BOUM", onoff(p.boom), toggle("boom"))

  H("Formatage")
  I("Formatage à la sauvegarde", onoff(p.format_on_save), toggle("format_on_save"))
  I("Formateur par langage", "choisir…", pick_formatter)

  H("Commits")
  local conv = conventions()
  I("Norme de commit", p.commit.convention, choose("commit.convention", conv, "Norme de commit"))
  I("Modifier cette norme", "ouvrir…", edit_convention)
  I("Nouvelle norme", "créer…", new_convention)
  I("Rappel : seuil de lignes", tostring(p.commit.reminder_lines), number("commit.reminder_lines", "Lignes modifiées : "))
  I("Rappel : seuil de minutes", tostring(p.commit.reminder_minutes), number("commit.reminder_minutes", "Minutes : "))

  H("Complétion IA")
  I("Suggestions IA (texte grisé)", onoff(p.ai_completion), toggle("ai_completion"))

  H("Débogueur")
  I("Interface", p.debug_layout, choose("debug_layout", { "panneaux", "flottant" }, "Interface du débogueur"))

  H("Markdown")
  I("Navigateur de l'aperçu", p.browser, choose("browser", require("core.markdown").choices, "Navigateur"))

  H("Raccourcis   Entrée : changer · r : touche par défaut")
  local group
  for _, a in ipairs(keys.actions) do
    if a.group ~= group then
      group = a.group
      S(group)
    end
    local custom = not a.fixed and (p.keys or {})[a.id] ~= nil
    I(a.desc, keys.get(a.id) .. (custom and "  ●" or ""), not a.fixed and edit_key(a) or nil, {
      dim = a.fixed,
      reset = not a.fixed and function()
        profiles.set("keys." .. a.id, nil)
      end or nil,
    })
  end
  return list
end

function M.render()
  local list = build()
  local lines, marks = {}, {}
  ui.items = {}
  for _, it in ipairs(list) do
    local text
    if it.kind == "header" then
      if #lines > 0 then
        table.insert(lines, "")
      end
      text = " " .. it.text
      table.insert(marks, { #lines, 0, #text, "Title" })
    elseif it.kind == "sub" then
      text = "   " .. it.text
      table.insert(marks, { #lines, 0, #text, "Comment" })
    else
      local label = "   " .. it.label
      local value = tostring(it.value)
      local dots = WIDTH - vim.fn.strdisplaywidth(label) - vim.fn.strdisplaywidth(value) - 3
      text = label .. " " .. string.rep("·", math.max(1, dots)) .. " " .. value
      local vstart = #text - #value
      table.insert(marks, { #lines, #label, vstart, "NonText" })
      table.insert(marks, { #lines, vstart, #text, it.dim and "Comment" or "Special" })
    end
    table.insert(lines, text)
    ui.items[#lines] = it
  end
  vim.bo[ui.buf].modifiable = true
  vim.api.nvim_buf_set_lines(ui.buf, 0, -1, false, lines)
  vim.bo[ui.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(ui.buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    vim.api.nvim_buf_set_extmark(ui.buf, ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
  end
  if ui.win and vim.api.nvim_win_is_valid(ui.win) then
    vim.api.nvim_win_set_config(ui.win, { title = " Paramètres — profil « " .. profiles.name() .. " » ", title_pos = "center" })
  end
end

local function current_item()
  local row = vim.api.nvim_win_get_cursor(ui.win)[1]
  return ui.items[row]
end

function M.close()
  if ui.win and vim.api.nvim_win_is_valid(ui.win) then
    vim.api.nvim_win_close(ui.win, true)
  end
  ui.win = nil
end

function M.open()
  if ui.win and vim.api.nvim_win_is_valid(ui.win) then
    vim.api.nvim_set_current_win(ui.win)
    return
  end
  ui.buf = vim.api.nvim_create_buf(false, true)
  vim.bo[ui.buf].bufhidden = "wipe"
  vim.bo[ui.buf].filetype = "param"
  local height = math.min(vim.o.lines - 6, 44)
  local width = WIDTH + 2
  ui.win = vim.api.nvim_open_win(ui.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    border = "rounded",
    style = "minimal",
    title = " Paramètres ",
    title_pos = "center",
    footer = " Entrée : modifier · r : par défaut · q : fermer ",
    footer_pos = "center",
  })
  vim.wo[ui.win].cursorline = true
  M.render()
  -- Place le curseur sur la première ligne modifiable.
  for row = 1, vim.api.nvim_buf_line_count(ui.buf) do
    if ui.items[row] and ui.items[row].kind == "item" then
      vim.api.nvim_win_set_cursor(ui.win, { row, 0 })
      break
    end
  end

  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = ui.buf, nowait = true, silent = true })
  end
  local function run()
    local it = current_item()
    if it and it.action then
      it.action()
      vim.schedule(rerender)
    end
  end
  map("<CR>", run)
  map("l", run)
  map("r", function()
    local it = current_item()
    if it and it.reset then
      it.reset()
      rerender()
    end
  end)
  map("q", M.close)
  map("<Esc>", M.close)
end

return M
