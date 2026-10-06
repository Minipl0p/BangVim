-- ╭──────────────────────────────────────────────────────────╮
-- │  Registre des raccourcis                                  │
-- │  Chaque action a une touche par défaut, modifiable par    │
-- │  profil depuis :Param. Ajouter une action = ajouter une   │
-- │  ligne A{ … } ci-dessous.                                 │
-- ╰──────────────────────────────────────────────────────────╯
local profiles = require("core.profiles")
local M = {}

---@class KeyAction
---@field id string identifiant unique (sert de clé dans le profil)
---@field group string section dans :Param
---@field desc string description (affichée aussi par which-key)
---@field key string touche par défaut
---@field mode? string|string[] modes ("n" par défaut)
---@field fn? function|string action (fonction ou suite de touches)
---@field rhs? table<string,string> action différente selon le mode
---@field remap? boolean
---@field expr? boolean
---@field scope? "global"|"lsp"|"claude"|"info" global par défaut ; "info" = affiché seulement
---@field fixed? boolean touche non modifiable (définie par un outil externe)

---@type KeyAction[]
M.actions = {}
local by_id = {} ---@type table<string, KeyAction>

local function A(t)
  t.mode = t.mode or "n"
  t.scope = t.scope or "global"
  table.insert(M.actions, t)
  by_id[t.id] = t
end

local function lazy(mod, fname, ...)
  local args = { ... }
  return function()
    require(mod)[fname](unpack(args))
  end
end

-- ── Bases ────────────────────────────────────────────────────
A({ id = "save", group = "Bases", desc = "Sauvegarder", key = "<C-s>", mode = { "n", "i", "x" },
  fn = "<Esc><Cmd>silent! write<CR>" })
A({ id = "close_buffer", group = "Bases", desc = "Fermer le buffer (avec sauvegarde)", key = "<C-q>",
  mode = { "n", "i", "x" }, fn = function() vim.cmd("stopinsert") require("core.buffers").write_and_close() end })
A({ id = "force_close", group = "Bases", desc = "Fermer le buffer sans sauvegarder", key = "<C-S-q>",
  fn = lazy("core.buffers", "force_close") })
A({ id = "escape", group = "Bases", desc = "Sortir du mode insertion", key = "jk", mode = "i", fn = "<Esc>" })
A({ id = "nohl", group = "Bases", desc = "Effacer le surlignage de recherche", key = "<Esc>",
  fn = "<Cmd>nohlsearch<CR><Esc>" })
A({ id = "comment", group = "Bases", desc = "Commenter ligne / sélection", key = "<C-/>", mode = { "n", "x" },
  rhs = { n = "gcc", x = "gc" }, remap = true })
A({ id = "join", group = "Bases", desc = "Joindre les lignes (curseur fixe)", key = "J", fn = "mzJ`z" })
A({ id = "indent_left", group = "Bases", desc = "Désindenter (garde la sélection)", key = "<", mode = "x", fn = "<gv" })
A({ id = "indent_right", group = "Bases", desc = "Indenter (garde la sélection)", key = ">", mode = "x", fn = ">gv" })

-- ── Mouvements ───────────────────────────────────────────────
A({ id = "down_fast", group = "Mouvements", desc = "Descendre de 5 lignes", key = "<C-j>", mode = { "n", "x" }, fn = "5j" })
A({ id = "up_fast", group = "Mouvements", desc = "Monter de 5 lignes", key = "<C-k>", mode = { "n", "x" }, fn = "5k" })

-- ── Buffers ──────────────────────────────────────────────────
A({ id = "buf_prev", group = "Buffers", desc = "Buffer précédent", key = "<C-h>", fn = lazy("core.buffers", "cycle", -1) })
A({ id = "buf_next", group = "Buffers", desc = "Buffer suivant", key = "<C-l>", fn = lazy("core.buffers", "cycle", 1) })
A({ id = "buf_close_others", group = "Buffers", desc = "Fermer tous les autres buffers", key = "<C-`>",
  fn = lazy("core.buffers", "close_others") })
A({ id = "buf_list", group = "Buffers", desc = "Liste des buffers ouverts", key = "<leader><Space>",
  fn = function() Snacks.picker.buffers() end })

-- ── Fenêtres ─────────────────────────────────────────────────
A({ id = "win_cycle", group = "Fenêtres", desc = "Rotation entre splits / sortir de Claude", key = "<C-;>",
  fn = lazy("core.claude", "cycle") })
A({ id = "split_v", group = "Fenêtres", desc = "Split vertical", key = "<leader>v", fn = "<Cmd>vsplit<CR>" })
A({ id = "split_h", group = "Fenêtres", desc = "Split horizontal", key = "<leader>h", fn = "<Cmd>split<CR>" })
A({ id = "win_close", group = "Fenêtres", desc = "Fermer le split", key = "<leader>w", fn = "<C-w>c" })
A({ id = "win_equal", group = "Fenêtres", desc = "Égaliser les splits", key = "<leader>=", fn = "<C-w>=" })
A({ id = "win_taller", group = "Fenêtres", desc = "Agrandir en hauteur", key = "<C-Up>", fn = "<Cmd>resize +2<CR>" })
A({ id = "win_shorter", group = "Fenêtres", desc = "Réduire en hauteur", key = "<C-Down>", fn = "<Cmd>resize -2<CR>" })
A({ id = "win_narrower", group = "Fenêtres", desc = "Réduire en largeur", key = "<C-Left>", fn = "<Cmd>vertical resize -2<CR>" })
A({ id = "win_wider", group = "Fenêtres", desc = "Agrandir en largeur", key = "<C-Right>", fn = "<Cmd>vertical resize +2<CR>" })

-- ── Terminal ─────────────────────────────────────────────────
A({ id = "term_toggle", group = "Terminal", desc = "Ouvrir / cacher le terminal flottant", key = "<C-t>",
  fn = lazy("core.terminal", "toggle") })
A({ id = "term_normal", group = "Terminal", desc = "Passer en mode normal (terminal flottant)", key = "<Esc><Esc>",
  scope = "info", fixed = true })

-- ── Claude Code ──────────────────────────────────────────────
A({ id = "claude_toggle", group = "Claude Code", desc = "Ouvrir / cacher Claude Code", key = "<leader>a",
  fn = lazy("core.claude", "toggle") })
A({ id = "claude_scroll_down", group = "Claude Code", desc = "Défiler vers le bas dans Claude", key = "<C-j>",
  scope = "claude", fn = lazy("core.claude", "scroll", 1) })
A({ id = "claude_scroll_up", group = "Claude Code", desc = "Défiler vers le haut dans Claude", key = "<C-k>",
  scope = "claude", fn = lazy("core.claude", "scroll", -1) })
A({ id = "quit_all", group = "Claude Code", desc = "Tout quitter (Neovim + Claude)", key = "<leader>Q",
  fn = lazy("core.claude", "quit_all") })

-- ── Recherche ────────────────────────────────────────────────
A({ id = "find_files", group = "Recherche", desc = "Chercher un fichier", key = "<leader>f",
  fn = function() Snacks.picker.files({ hidden = true }) end })
A({ id = "live_grep", group = "Recherche", desc = "Live grep", key = "<leader>g",
  fn = function() Snacks.picker.grep({ hidden = true }) end })
A({ id = "flash", group = "Recherche", desc = "Saut rapide", key = "s", mode = { "n", "x", "o" },
  fn = function() require("flash").jump() end })
A({ id = "flash_ts", group = "Recherche", desc = "Sélection de blocs (Treesitter)", key = "S", mode = { "n", "o" },
  fn = function() require("flash").treesitter() end })

-- ── Arbre ────────────────────────────────────────────────────
A({ id = "tree", group = "Arbre", desc = "Ouvrir l'arbre flottant", key = "<leader>e", fn = lazy("core.tree", "open") })
A({ id = "tree_l", group = "Arbre", desc = "Déplier / ouvrir (dans l'arbre)", key = "l", scope = "info", fixed = true })
A({ id = "tree_h", group = "Arbre", desc = "Replier / remonter (dans l'arbre)", key = "h", scope = "info", fixed = true })
A({ id = "tree_cr", group = "Arbre", desc = "Ouvrir le fichier (dans l'arbre)", key = "<CR>", scope = "info", fixed = true })
A({ id = "tree_ccr", group = "Arbre", desc = "Ouvrir et fermer les autres buffers", key = "<C-CR>", scope = "info", fixed = true })
A({ id = "tree_edit", group = "Arbre", desc = "Créer / supprimer / renommer / déplacer", key = "a d r m", scope = "info", fixed = true })

-- ── Copier-coller ────────────────────────────────────────────
A({ id = "put_after", group = "Copier-coller", desc = "Coller après (indentation auto)", key = "p", mode = { "n", "x" },
  expr = true, remap = true, fn = function() return require("core.paste").put("After") end })
A({ id = "put_before", group = "Copier-coller", desc = "Coller avant (indentation auto)", key = "P", mode = { "n", "x" },
  expr = true, remap = true, fn = function() return require("core.paste").put("Before") end })
A({ id = "yank", group = "Copier-coller", desc = "Copier (dans l'historique)", key = "y", mode = { "n", "x" },
  remap = true, fn = "<Plug>(YankyYank)" })
A({ id = "yank_prev", group = "Copier-coller", desc = "Copie précédente (après un collage)", key = "<C-p>",
  remap = true, fn = "<Plug>(YankyPreviousEntry)" })
A({ id = "yank_next", group = "Copier-coller", desc = "Copie suivante (après un collage)", key = "<C-n>",
  remap = true, fn = "<Plug>(YankyNextEntry)" })
A({ id = "yank_history", group = "Copier-coller", desc = "Historique des copies", key = "<leader>y",
  fn = function() Snacks.picker.yanky() end })

-- ── Code (actif quand un LSP est attaché) ────────────────────
A({ id = "lsp_def", group = "Code", desc = "Aller à la définition", key = "gd", scope = "lsp",
  fn = function() Snacks.picker.lsp_definitions() end })
A({ id = "lsp_decl", group = "Code", desc = "Aller à la déclaration", key = "gD", scope = "lsp",
  fn = function() Snacks.picker.lsp_declarations() end })
A({ id = "lsp_impl", group = "Code", desc = "Aller à l'implémentation", key = "gi", scope = "lsp",
  fn = function() Snacks.picker.lsp_implementations() end })
A({ id = "lsp_type", group = "Code", desc = "Aller au type", key = "gy", scope = "lsp",
  fn = function() Snacks.picker.lsp_type_definitions() end })
A({ id = "lsp_refs", group = "Code", desc = "Références", key = "gr", scope = "lsp",
  fn = function() Snacks.picker.lsp_references() end })
A({ id = "lsp_hover", group = "Code", desc = "Documentation au survol", key = "K", scope = "lsp",
  fn = function() vim.lsp.buf.hover({ border = "rounded" }) end })
A({ id = "diag_line", group = "Code", desc = "Diagnostic de la ligne (flottant)", key = "gl",
  fn = function() vim.diagnostic.open_float() end })
A({ id = "diag_prev", group = "Code", desc = "Diagnostic précédent", key = "[d",
  fn = function() vim.diagnostic.jump({ count = -1, float = true }) end })
A({ id = "diag_next", group = "Code", desc = "Diagnostic suivant", key = "]d",
  fn = function() vim.diagnostic.jump({ count = 1, float = true }) end })
A({ id = "lsp_rename", group = "Code", desc = "Renommer partout (LSP)", key = "<leader>b", scope = "lsp",
  fn = lazy("core.rename", "lsp") })
A({ id = "rename_file", group = "Code", desc = "Renommer dans le fichier", key = "<leader>n", fn = lazy("core.rename", "in_file") })
A({ id = "replace_sel", group = "Code", desc = "Remplacer dans la sélection", key = "<leader>n", mode = "x",
  fn = lazy("core.rename", "in_selection") })

-- ── Git ──────────────────────────────────────────────────────
A({ id = "lazygit", group = "Git", desc = "Lazygit", key = "<C-g>", fn = function() require("core.lazygit").setup() Snacks.lazygit() end })
A({ id = "ai_commit", group = "Git", desc = "Commit IA (dans lazygit)", key = "<c-a>", scope = "info" })

-- ── IA (texte grisé, mode insertion) ─────────────────────────
A({ id = "ai_accept", group = "IA", desc = "Accepter toute la suggestion", key = "<Tab>", mode = "i",
  fn = lazy("core.ai", "accept") })
A({ id = "ai_word", group = "IA", desc = "Accepter un mot", key = "<C-l>", mode = "i", fn = lazy("core.ai", "accept_word") })
A({ id = "ai_line", group = "IA", desc = "Accepter une ligne", key = "<C-j>", mode = "i", fn = lazy("core.ai", "accept_line") })
A({ id = "ai_cycle", group = "IA", desc = "Variante suivante (en boucle)", key = "<C-]>", mode = "i", fn = lazy("core.ai", "cycle") })
A({ id = "ai_clear", group = "IA", desc = "Rejeter la suggestion", key = "<C-e>", mode = "i", fn = lazy("core.ai", "clear") })

-- ── Complétion (menu) ────────────────────────────────────────
A({ id = "cmp_nav", group = "Complétion", desc = "Naviguer dans le menu", key = "<C-n> / <C-p>", scope = "info", fixed = true })
A({ id = "cmp_accept", group = "Complétion", desc = "Valider", key = "<CR>", scope = "info", fixed = true })
A({ id = "cmp_show", group = "Complétion", desc = "Forcer l'ouverture", key = "<C-Space>", scope = "info", fixed = true })
A({ id = "cmp_prev", group = "Complétion", desc = "Placeholder précédent", key = "<S-Tab>", scope = "info", fixed = true })

-- ── Debug ────────────────────────────────────────────────────
A({ id = "dbg_continue", group = "Debug", desc = "Lancer / continuer", key = "<F5>", fn = function() require("dap").continue() end })
A({ id = "dbg_stop", group = "Debug", desc = "Arrêter", key = "<S-F5>", fn = function() require("dap").terminate() end })
A({ id = "dbg_bp", group = "Debug", desc = "Breakpoint on/off", key = "<F9>", fn = function() require("dap").toggle_breakpoint() end })
A({ id = "dbg_bp_cond", group = "Debug", desc = "Breakpoint conditionnel", key = "<leader>B", fn = lazy("core.debug", "conditional") })
A({ id = "dbg_over", group = "Debug", desc = "Passer par-dessus", key = "<F10>", fn = function() require("dap").step_over() end })
A({ id = "dbg_into", group = "Debug", desc = "Entrer dans la fonction", key = "<F11>", fn = function() require("dap").step_into() end })
A({ id = "dbg_out", group = "Debug", desc = "Sortir de la fonction", key = "<S-F11>", fn = function() require("dap").step_out() end })
A({ id = "dbg_ui", group = "Debug", desc = "Afficher / cacher l'interface", key = "<leader>D", fn = lazy("core.debug", "toggle_ui") })

-- ── Markdown et paramètres ───────────────────────────────────
A({ id = "md_preview", group = "Markdown", desc = "Aperçu Markdown (navigateur)", key = "<leader>m",
  fn = lazy("core.markdown", "toggle") })
A({ id = "param", group = "Paramètres", desc = "Fenêtre des paramètres", key = "<leader>,", fn = lazy("core.param", "open") })

-- ════════════════════════════════════════════════════════════
--  Mécanique
-- ════════════════════════════════════════════════════════════

local applied = {} ---@type {mode:string, lhs:string}[]
local lsp_applied = {} ---@type table<integer, {mode:string, lhs:string}[]>
M.owned = {} ---@type table<string, boolean> touches posées par ce module (pour which-key)

local function modes(a)
  return type(a.mode) == "table" and a.mode or { a.mode }
end

local function norm(mode, lhs)
  return mode .. ":" .. vim.fn.keytrans(vim.keycode(lhs))
end

function M.action(id)
  return by_id[id]
end

--- Touche effective d'une action pour le profil actif.
function M.get(id)
  local a = by_id[id]
  if not a then
    return nil
  end
  if a.fixed then
    return a.key
  end
  local overrides = profiles.value("keys") or {}
  return overrides[id] or a.key
end

local function set(a, lhs, buf)
  local placed = {}
  for _, mode in ipairs(modes(a)) do
    local rhs = a.rhs and a.rhs[mode] or a.fn
    if rhs then
      vim.keymap.set(mode, lhs, rhs, { desc = a.desc, remap = a.remap, expr = a.expr, silent = true, buffer = buf })
      table.insert(placed, { mode = mode, lhs = lhs })
      M.owned[norm(mode, lhs)] = true
    end
  end
  return placed
end

--- (Re)pose toutes les touches globales selon le profil actif.
function M.apply()
  for _, m in ipairs(applied) do
    pcall(vim.keymap.del, m.mode, m.lhs)
  end
  applied = {}
  M.owned = {}
  for _, a in ipairs(M.actions) do
    if a.scope == "global" then
      local lhs = M.get(a.id)
      if lhs and lhs ~= "" then
        vim.list_extend(applied, set(a, lhs))
      end
    elseif a.scope == "lsp" or a.scope == "claude" then
      for _, mode in ipairs(modes(a)) do
        M.owned[norm(mode, M.get(a.id))] = true
      end
    end
  end
  -- Ré-attache les touches LSP aux buffers déjà ouverts.
  for buf in pairs(lsp_applied) do
    if vim.api.nvim_buf_is_valid(buf) then
      M.attach_lsp(buf)
    end
  end
  pcall(require("core.claude").attach_keys)
end

--- Touches propres aux buffers où un LSP est attaché.
function M.attach_lsp(buf)
  for _, m in ipairs(lsp_applied[buf] or {}) do
    pcall(vim.keymap.del, m.mode, m.lhs, { buffer = buf })
  end
  lsp_applied[buf] = {}
  for _, a in ipairs(M.actions) do
    if a.scope == "lsp" then
      vim.list_extend(lsp_applied[buf], set(a, M.get(a.id), buf))
    end
  end
end

--- Touches propres à la fenêtre de Claude (mode terminal et normal).
function M.attach_claude(buf)
  local function o(desc)
    return { buffer = buf, desc = desc, silent = true }
  end
  local down, up = M.get("claude_scroll_down"), M.get("claude_scroll_up")
  -- Pendant la saisie : <C-j>/<C-k> passent en mode lecture (normal) et défilent.
  vim.keymap.set("t", down, "<C-\\><C-n><Cmd>lua require('core.claude').scroll(1)<CR>", o("Lire / défiler vers le bas"))
  vim.keymap.set("t", up, "<C-\\><C-n><Cmd>lua require('core.claude').scroll(-1)<CR>", o("Lire / défiler vers le haut"))
  -- En mode lecture : défilement, et j/k font défiler quand on touche le bord.
  vim.keymap.set("n", down, function() require("core.claude").scroll(1) end, o("Défiler vers le bas"))
  vim.keymap.set("n", up, function() require("core.claude").scroll(-1) end, o("Défiler vers le haut"))
  vim.keymap.set("n", "j", function() require("core.claude").edge("j") end, o("Ligne suivante (défile au bord)"))
  vim.keymap.set("n", "k", function() require("core.claude").edge("k") end, o("Ligne précédente (défile au bord)"))
  -- Sortir de Claude, ou ouvrir le terminal flottant par-dessus.
  vim.keymap.set("t", M.get("win_cycle"), "<C-\\><C-n><Cmd>lua require('core.claude').cycle()<CR>", o("Revenir au code"))
  vim.keymap.set("t", M.get("term_toggle"), "<C-\\><C-n><Cmd>lua require('core.terminal').toggle()<CR>", o("Terminal flottant"))
end

function M.setup()
  -- Neovim 0.11+ pose des touches gr* par défaut : elles feraient attendre « gr ».
  for _, lhs in ipairs({ "grn", "gra", "grr", "gri", "grt", "grx" }) do
    pcall(vim.keymap.del, "n", lhs)
    pcall(vim.keymap.del, "x", lhs)
  end
  M.apply()
  vim.api.nvim_create_autocmd("LspAttach", {
    callback = function(ev)
      M.attach_lsp(ev.buf)
    end,
  })
  vim.api.nvim_create_autocmd("BufWipeout", {
    callback = function(ev)
      lsp_applied[ev.buf] = nil
    end,
  })
end

return M
