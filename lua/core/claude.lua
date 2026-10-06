-- ╭──────────────────────────────────────────────────────────╮
-- │  Claude Code : split vertical à droite                    │
-- │  focus code ↔ Claude, défilement au clavier, tout quitter │
-- ╰──────────────────────────────────────────────────────────╯
local buffers = require("core.buffers")
local M = {}

-- Nombre d'événements « molette » envoyés par appui (≈ 5 lignes chez Claude Code).
M.scroll_steps = 2

local last_code_win ---@type integer?

--- Buffer du terminal Claude, s'il tourne.
function M.buf()
  local ok, term = pcall(require, "claudecode.terminal")
  if not ok then
    return nil
  end
  local b = term.get_active_terminal_bufnr()
  if b and vim.api.nvim_buf_is_valid(b) then
    return b
  end
end

local function is_split(win)
  return vim.api.nvim_win_get_config(win).relative == ""
end

function M.toggle()
  vim.cmd("ClaudeCode")
end

--- Rotation entre les splits (pas les flottants). Depuis Claude : retour au code.
function M.cycle()
  local cur = vim.api.nvim_get_current_win()
  local cbuf = M.buf()
  if cbuf and vim.api.nvim_win_get_buf(cur) == cbuf then
    if last_code_win and vim.api.nvim_win_is_valid(last_code_win) then
      vim.api.nvim_set_current_win(last_code_win)
    else
      buffers.ensure_code_win()
    end
    return
  end
  local wins = vim.tbl_filter(is_split, vim.api.nvim_tabpage_list_wins(0))
  if #wins <= 1 then
    return
  end
  local idx = 1
  for i, w in ipairs(wins) do
    if w == cur then
      idx = i
    end
  end
  local target = wins[idx % #wins + 1]
  vim.api.nvim_set_current_win(target)
  if vim.bo[vim.api.nvim_win_get_buf(target)].buftype == "terminal" then
    vim.cmd("startinsert")
  end
end

--- Défilement dans Claude Code : on lui envoie des événements de molette,
--- exactement ce que ferait la souris (Claude dessine lui-même son historique).
function M.scroll(dir, steps)
  local buf = M.buf()
  if not buf then
    return
  end
  local chan = vim.bo[buf].channel
  local win = vim.fn.bufwinid(buf)
  if chan == 0 or win == -1 then
    return
  end
  local col = math.max(1, math.floor(vim.api.nvim_win_get_width(win) / 2))
  local row = math.max(1, math.floor(vim.api.nvim_win_get_height(win) / 2))
  local button = dir > 0 and 65 or 64 -- 64 = molette haut, 65 = molette bas (SGR)
  local seq = ("\27[<%d;%d;%dM"):format(button, col, row)
  for _ = 1, steps or M.scroll_steps do
    vim.api.nvim_chan_send(chan, seq)
  end
end

--- Mode lecture : j/k bougent normalement, et font défiler Claude
--- quand le curseur atteint le haut ou le bas de la fenêtre.
function M.edge(key)
  local line, last = vim.fn.line("."), vim.fn.line("$")
  if key == "k" and line <= 1 then
    M.scroll(-1, 1)
  elseif key == "j" and line >= last then
    M.scroll(1, 1)
  else
    vim.cmd("normal! " .. vim.v.count1 .. key)
  end
end

local function is_claude(buf)
  if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].buftype ~= "terminal" then
    return false
  end
  return M.buf() == buf or vim.api.nvim_buf_get_name(buf):lower():find("claude") ~= nil
end

--- Pose les touches propres à la fenêtre de Claude.
function M.attach_keys(buf)
  buf = buf or M.buf()
  if buf and vim.api.nvim_buf_is_valid(buf) then
    vim.bo[buf].buflisted = false
    require("core.keys").attach_claude(buf)
  end
end

--- Quitte tout : fichiers non sauvegardés, rappel de commit, /exit à Claude.
---@param opts? {force?: boolean}
function M.quit_all(opts)
  opts = opts or {}
  if not opts.force then
    local modified = vim.tbl_filter(function(b)
      return vim.api.nvim_buf_is_valid(b) and vim.bo[b].modified and vim.bo[b].buftype == ""
    end, vim.api.nvim_list_bufs())
    if #modified > 0 then
      local choice = vim.fn.confirm(
        ("%d fichier(s) non sauvegardé(s)."):format(#modified),
        "&Tout sauvegarder\n&Quitter sans sauvegarder\n&Annuler",
        1
      )
      if choice == 1 then
        vim.cmd("silent! wall")
      elseif choice ~= 2 then
        return
      end
    end
    if not require("core.commit_reminder").confirm_quit() then
      return
    end
  end
  local buf = M.buf()
  if buf and vim.bo[buf].channel > 0 then
    pcall(vim.api.nvim_chan_send, vim.bo[buf].channel, "/exit\r")
    vim.defer_fn(function()
      vim.cmd("qa!")
    end, 400)
  else
    vim.cmd("qa!")
  end
end

function M.setup()
  local group = vim.api.nvim_create_augroup("ClaudeFenetre", { clear = true })
  vim.api.nvim_create_autocmd("WinEnter", {
    group = group,
    callback = function()
      local w = vim.api.nvim_get_current_win()
      if buffers.is_code_win(w) then
        last_code_win = w
      end
    end,
  })
  -- Le terminal de Claude est créé à la demande : on pose ses touches dès qu'il apparaît.
  vim.api.nvim_create_autocmd({ "TermOpen", "BufEnter", "TermEnter" }, {
    group = group,
    callback = function(ev)
      local buf = ev.buf
      vim.schedule(function()
        if is_claude(buf) and not vim.b[buf].claude_keys then
          vim.b[buf].claude_keys = true
          M.attach_keys(buf)
        end
      end)
    end,
  })
end

return M
