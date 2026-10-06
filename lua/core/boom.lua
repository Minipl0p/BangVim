-- ╭──────────────────────────────────────────────────────────╮
-- │  Animation « BOUM »                                       │
-- │  1. La lettre tapée surgit en GÉANT (vraie lettre en      │
-- │     pixels), blanche, « depuis tes yeux »                 │
-- │  2. Elle fonce vers sa case en rétrécissant et en         │
-- │     changeant de couleur (blanc → jaune → orange → accent)│
-- │  3. Impact : onde d'étincelles + la lettre tremble        │
-- │  Les zones vides sont transparentes : on voit le code     │
-- │  à travers.                                               │
-- ╰──────────────────────────────────────────────────────────╯
local M = {}

M.enabled = false
M.max_flying = 4 -- au-delà, les lettres suivantes ne sont pas animées (frappe rapide)
M.frame_ms = 32
M.start_scale = 3 -- taille de départ (3 = lettre de 30 × 15 cases)

-- ── Police 5 × 5 ─────────────────────────────────────────────
local font = {
  a = { " ### ", "#   #", "#####", "#   #", "#   #" },
  b = { "#### ", "#   #", "#### ", "#   #", "#### " },
  c = { " ####", "#    ", "#    ", "#    ", " ####" },
  d = { "#### ", "#   #", "#   #", "#   #", "#### " },
  e = { "#####", "#    ", "#### ", "#    ", "#####" },
  f = { "#####", "#    ", "#### ", "#    ", "#    " },
  g = { " ####", "#    ", "#  ##", "#   #", " ####" },
  h = { "#   #", "#   #", "#####", "#   #", "#   #" },
  i = { "#####", "  #  ", "  #  ", "  #  ", "#####" },
  j = { "#####", "   # ", "   # ", "#  # ", " ##  " },
  k = { "#   #", "#  # ", "###  ", "#  # ", "#   #" },
  l = { "#    ", "#    ", "#    ", "#    ", "#####" },
  m = { "#   #", "## ##", "# # #", "#   #", "#   #" },
  n = { "#   #", "##  #", "# # #", "#  ##", "#   #" },
  o = { " ### ", "#   #", "#   #", "#   #", " ### " },
  p = { "#### ", "#   #", "#### ", "#    ", "#    " },
  q = { " ### ", "#   #", "# # #", "#  # ", " ## #" },
  r = { "#### ", "#   #", "#### ", "#  # ", "#   #" },
  s = { " ####", "#    ", " ### ", "    #", "#### " },
  t = { "#####", "  #  ", "  #  ", "  #  ", "  #  " },
  u = { "#   #", "#   #", "#   #", "#   #", " ### " },
  v = { "#   #", "#   #", "#   #", " # # ", "  #  " },
  w = { "#   #", "#   #", "# # #", "## ##", "#   #" },
  x = { "#   #", " # # ", "  #  ", " # # ", "#   #" },
  y = { "#   #", " # # ", "  #  ", "  #  ", "  #  " },
  z = { "#####", "   # ", "  #  ", " #   ", "#####" },
  ["0"] = { " ### ", "#  ##", "# # #", "##  #", " ### " },
  ["1"] = { "  #  ", " ##  ", "  #  ", "  #  ", " ### " },
  ["2"] = { " ### ", "#   #", "  ## ", " #   ", "#####" },
  ["3"] = { "#### ", "    #", " ### ", "    #", "#### " },
  ["4"] = { "#   #", "#   #", "#####", "    #", "    #" },
  ["5"] = { "#####", "#    ", "#### ", "    #", "#### " },
  ["6"] = { " ### ", "#    ", "#### ", "#   #", " ### " },
  ["7"] = { "#####", "    #", "   # ", "  #  ", "  #  " },
  ["8"] = { " ### ", "#   #", " ### ", "#   #", " ### " },
  ["9"] = { " ### ", "#   #", " ####", "    #", " ### " },
}
-- Caractères sans dessin (ponctuation, accents…) : un bloc plein.
local fallback = { "#####", "#####", "#####", "#####", "#####" }

-- Couleurs successives pendant la chute.
local trail = { "BoomWhite", "BoomYellow", "BoomPeach", "BoomAccent" }

-- ── Couleurs ─────────────────────────────────────────────────
local function color(name, fallback_hex)
  local hl = vim.api.nvim_get_hl(0, { name = name, link = false })
  return hl.fg and ("#%06x"):format(hl.fg) or fallback_hex
end

local function set_hl()
  vim.api.nvim_set_hl(0, "BoomWhite", { fg = "#ffffff", bold = true })
  vim.api.nvim_set_hl(0, "BoomYellow", { fg = color("DiagnosticWarn", "#f9e2af"), bold = true })
  vim.api.nvim_set_hl(0, "BoomPeach", { fg = color("Number", "#fab387"), bold = true })
  vim.api.nvim_set_hl(0, "BoomAccent", { fg = color("Function", "#89b4fa"), bold = true })
  vim.api.nvim_set_hl(0, "BoomSpark", { fg = color("DiagnosticWarn", "#f9e2af"), bold = true })
  vim.api.nvim_set_hl(0, "BoomSparkDim", { fg = color("Comment", "#6c7086") })
end

-- ── Construction des images ──────────────────────────────────
-- Une image = { lines = {…}, marks = { {ligne, col_octet, fin_octet, hl}, … } }

--- Lettre géante : chaque pixel devient (2 × s) colonnes × s lignes
--- (les cases d'un terminal sont deux fois plus hautes que larges).
local function giant(char, s, hl)
  local glyph = font[char:lower()] or fallback
  local lines, marks = {}, {}
  for _, row in ipairs(glyph) do
    local cells = {}
    for c = 1, #row do
      local px = row:sub(c, c) == "#" and "█" or " "
      for _ = 1, 2 * s do
        table.insert(cells, px)
      end
    end
    local line = table.concat(cells)
    for _ = 1, s do
      table.insert(lines, line)
      table.insert(marks, { #lines - 1, 0, #line, hl })
    end
  end
  return { lines = lines, marks = marks, w = 10 * s, h = 5 * s }
end

--- Impact : la lettre au centre (décalée de `dx` pour trembler) et une onde
--- d'étincelles de rayon `r` dans 8 directions.
local R = 3
local function impact(char, r, dx)
  local h, w = 2 * R + 1, 4 * R + 1
  local cr, cc = R + 1, 2 * R + 1
  local grid = {}
  for y = 1, h do
    grid[y] = {}
    for x = 1, w do
      grid[y][x] = { " " }
    end
  end
  if r > 0 then
    local spark = ({ "✦", "✧", "•", "·" })[math.min(r, 4)]
    local hl = r >= 3 and "BoomSparkDim" or "BoomSpark"
    for _, d in ipairs({ { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 }, { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 } }) do
      local y, x = cr + d[1] * r, cc + d[2] * r * 2
      if grid[y] and grid[y][x] then
        grid[y][x] = { spark, hl }
      end
    end
  end
  grid[cr][cc + dx] = { char, "BoomAccent" }

  local lines, marks = {}, {}
  for y = 1, h do
    local parts, byte = {}, 0
    for x = 1, w do
      local cell = grid[y][x]
      if cell[2] then
        table.insert(marks, { y - 1, byte, byte + #cell[1], cell[2] })
      end
      table.insert(parts, cell[1])
      byte = byte + #cell[1]
    end
    table.insert(lines, table.concat(parts))
  end
  return { lines = lines, marks = marks, w = w, h = h }
end

--- Toutes les images de l'animation d'une lettre.
local function frames_for(char)
  local frames = {}
  for i, s in ipairs({ M.start_scale, M.start_scale - 1, math.max(1, M.start_scale - 2) }) do
    table.insert(frames, giant(char, math.max(1, s), trail[i]))
  end
  local shake = { 1, -1, 1, 0, 0 }
  for r = 1, 4 do
    table.insert(frames, impact(char, r, shake[r]))
  end
  table.insert(frames, impact(char, 0, 0))
  return frames
end

-- ── Animation ────────────────────────────────────────────────
local flying = 0
local ns = vim.api.nvim_create_namespace("boom")
local group = vim.api.nvim_create_augroup("Boom", { clear = true })

local function animate(char)
  if flying >= M.max_flying then
    return
  end
  -- Position de la lettre dans le buffer : l'animation reste dessus même si on continue à taper.
  local src_win = vim.api.nvim_get_current_win()
  local cur = vim.api.nvim_win_get_cursor(src_win)
  local anchor = { cur[1] - 1, math.max(0, cur[2] - #char) }
  local frames = frames_for(char)

  flying = flying + 1
  local buf = vim.api.nvim_create_buf(false, true)
  local win ---@type integer?
  local step = 0
  local timer = assert(vim.uv.new_timer())

  local function finish()
    if timer:is_active() then
      timer:stop()
    end
    if not timer:is_closing() then
      timer:close()
    end
    if win and vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    if vim.api.nvim_buf_is_valid(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
    flying = flying - 1
  end

  local function draw(f)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, f.lines)
    vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
    for _, m in ipairs(f.marks) do
      vim.api.nvim_buf_set_extmark(buf, ns, m[1], m[2], { end_col = m[3], hl_group = m[4] })
    end
    local cfg = {
      relative = "win",
      win = src_win,
      bufpos = anchor,
      row = -math.floor((f.h - 1) / 2),
      col = -math.floor((f.w - 1) / 2),
      width = f.w,
      height = f.h,
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
      -- Fond 100 % transparent : seules les lettres et étincelles se voient.
      vim.wo[win].winblend = 100
      vim.wo[win].winhighlight = "Normal:BoomAccent,NormalFloat:BoomAccent"
    end
  end

  timer:start(0, M.frame_ms, vim.schedule_wrap(function()
    step = step + 1
    local ok = step <= #frames and pcall(draw, frames[step])
    if not ok then
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
