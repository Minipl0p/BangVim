-- ╭──────────────────────────────────────────────────────────╮
-- │  Animation « BOUM »                                       │
-- │  Chaque lettre tapée arrive « depuis tes yeux » : elle    │
-- │  apparaît en grand puis rétrécit jusqu'à sa case, et      │
-- │  tremble un peu à l'atterrissage.                         │
-- │  Un terminal affiche une grille de cases fixes : le zoom  │
-- │  est simulé par des blocs de plus en plus petits.         │
-- ╰──────────────────────────────────────────────────────────╯
local M = {}

M.enabled = false
M.max_flying = 6 -- au-delà, les lettres suivantes ne sont pas animées (frappe rapide)
M.frame_ms = 28

-- Tailles successives (largeur, hauteur) : de « près des yeux » à « posée ».
local frames = { { 9, 5 }, { 7, 3 }, { 5, 3 }, { 3, 1 }, { 1, 1 } }
local shake = { 1, -1, 1, 0 } -- décalages horizontaux à l'atterrissage

local flying = 0
local group = vim.api.nvim_create_augroup("Boom", { clear = true })

local function set_hl()
  local accent = vim.api.nvim_get_hl(0, { name = "Function", link = false }).fg
  local bg = vim.api.nvim_get_hl(0, { name = "NormalFloat", link = false }).bg
  vim.api.nvim_set_hl(0, "BoomLetter", { fg = accent, bg = bg, bold = true })
end

local function animate(char)
  -- Position de la lettre dans le buffer : l'animation reste dessus même si on continue à taper.
  local src_win = vim.api.nvim_get_current_win()
  local cur = vim.api.nvim_win_get_cursor(src_win)
  local anchor = { cur[1] - 1, math.max(0, cur[2] - #char) }
  if flying >= M.max_flying then
    return
  end
  flying = flying + 1
  local buf = vim.api.nvim_create_buf(false, true)
  local win ---@type integer?
  local step = 0
  local timer = vim.uv.new_timer()
  if not timer then
    flying = flying - 1
    return
  end

  local function finish()
    timer:stop()
    timer:close()
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    flying = flying - 1
  end

  local function place(w, h, dx)
    local lines = {}
    for _ = 1, h do
      table.insert(lines, string.rep(char, w))
    end
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    -- Bloc centré sur la case de la lettre.
    local cfg = {
      relative = "win",
      win = src_win,
      bufpos = anchor,
      row = -math.floor((h - 1) / 2),
      col = -math.floor((w - 1) / 2) + (dx or 0),
      width = w,
      height = h,
      style = "minimal",
      border = "none",
      focusable = false,
      noautocmd = true,
      zindex = 250,
    }
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_set_config(win, cfg)
    else
      win = vim.api.nvim_open_win(buf, false, cfg)
      vim.wo[win].winhighlight = "Normal:BoomLetter,NormalFloat:BoomLetter"
    end
  end

  timer:start(0, M.frame_ms, vim.schedule_wrap(function()
    step = step + 1
    local ok = pcall(function()
      if step <= #frames then
        place(frames[step][1], frames[step][2], 0)
      elseif step <= #frames + #shake then
        place(1, 1, shake[step - #frames])
      else
        error("fin")
      end
    end)
    if not ok and timer:is_active() then
      finish()
    end
  end))
end

function M.enable(on)
  M.enabled = on
  vim.api.nvim_clear_autocmds({ group = group })
  if not on then
    return
  end
  set_hl()
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_hl })
  vim.api.nvim_create_autocmd("InsertCharPre", {
    group = group,
    callback = function()
      local char = vim.v.char
      if vim.bo.buftype ~= "" or char:match("^%s$") or vim.fn.strdisplaywidth(char) ~= 1 then
        return
      end
      -- On attend que la lettre soit insérée pour connaître sa position.
      vim.schedule(function()
        if vim.fn.mode() == "i" then
          animate(char)
        end
      end)
    end,
  })
end

return M
