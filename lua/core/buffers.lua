-- Gestion des buffers : navigation, fermeture.
local M = {}

local function is_code_win(win)
  if not vim.api.nvim_win_is_valid(win) then
    return false
  end
  if vim.api.nvim_win_get_config(win).relative ~= "" then
    return false -- fenêtre flottante
  end
  return vim.bo[vim.api.nvim_win_get_buf(win)].buftype == ""
end
M.is_code_win = is_code_win

--- Buffers de fichiers listés (sans terminaux ni Claude).
function M.listed()
  return vim.tbl_filter(function(b)
    return vim.api.nvim_buf_is_valid(b) and vim.bo[b].buflisted and vim.bo[b].buftype == ""
  end, vim.api.nvim_list_bufs())
end

--- Se place dans une fenêtre de code si on est ailleurs (Claude, terminal…).
function M.ensure_code_win()
  if is_code_win(vim.api.nvim_get_current_win()) then
    return true
  end
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if is_code_win(w) then
      vim.api.nvim_set_current_win(w)
      return true
    end
  end
  return false
end

function M.cycle(dir)
  M.ensure_code_win()
  local ok = pcall(vim.cmd, dir > 0 and "BufferLineCycleNext" or "BufferLineCyclePrev")
  if not ok then
    vim.cmd(dir > 0 and "bnext" or "bprevious")
  end
end

--- Sauvegarde puis ferme le buffer. Dernier buffer : quitte Neovim proprement.
function M.write_and_close()
  local buf = vim.api.nvim_get_current_buf()
  if vim.bo[buf].buftype ~= "" then
    return
  end
  -- Message de commit (édité depuis lazygit) : on valide simplement.
  if vim.bo[buf].filetype == "gitcommit" then
    vim.cmd("wq")
    return
  end
  if vim.bo[buf].modified and vim.api.nvim_buf_get_name(buf) ~= "" then
    vim.cmd("silent! write")
  end
  if #M.listed() <= 1 then
    require("core.claude").quit_all()
    return
  end
  Snacks.bufdelete({ buf = buf })
end

function M.force_close()
  if #M.listed() <= 1 then
    require("core.claude").quit_all({ force = true })
    return
  end
  Snacks.bufdelete({ force = true })
end

function M.close_others()
  M.ensure_code_win()
  Snacks.bufdelete.other()
end

return M
