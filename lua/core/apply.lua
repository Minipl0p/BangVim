-- Applique le profil actif à la config (au démarrage et à chaque changement).
local profiles = require("core.profiles")
local M = {}

local function theme(name)
  local ok = pcall(vim.cmd.colorscheme, name)
  if not ok then
    vim.notify("Thème introuvable : " .. name .. " (retour à catppuccin-mocha)", vim.log.levels.WARN)
    pcall(vim.cmd.colorscheme, "catppuccin-mocha")
  end
end

function M.apply(key)
  local p = profiles.get()
  local all = key == nil or key == "*"
  if all or key == "theme" then
    theme(p.theme)
  end
  if all or key:match("^keys") then
    require("core.keys").apply()
    pcall(require("core.lazygit").write)
  end
  if all or key == "ai_completion" then
    require("core.ai").set_enabled(p.ai_completion)
  end
  if (all or key == "smear_cursor") and package.loaded["smear_cursor"] then
    pcall(function()
      require("smear_cursor").enabled = p.smear_cursor
    end)
  end
  if all or key == "boom" then
    require("core.boom").enable(p.boom)
  end
  if key == "debug_layout" then
    pcall(function()
      require("dapui").close()
    end)
  end
end

--- Fond transparent : on laisse voir le dégradé de WezTerm.
local transparent = {
  "Normal", "NormalNC", "SignColumn", "LineNr", "CursorLineNr", "FoldColumn",
  "EndOfBuffer", "WinSeparator", "StatusLine", "StatusLineNC",
}
local function clear_bg()
  for _, g in ipairs(transparent) do
    local hl = vim.api.nvim_get_hl(0, { name = g, link = false })
    hl.bg = nil
    hl.ctermbg = nil
    vim.api.nvim_set_hl(0, g, hl)
  end
end

function M.setup()
  vim.api.nvim_create_autocmd("ColorScheme", { callback = clear_bg })
  vim.api.nvim_create_autocmd("User", {
    pattern = "ProfilChange",
    callback = function(ev)
      M.apply(ev.data and ev.data.key or "*")
    end,
  })
  -- Changement de dossier : le profil associé s'applique (sans devenir le « dernier utilisé »).
  vim.api.nvim_create_autocmd("DirChanged", {
    callback = function()
      local name = profiles.resolve()
      if name ~= profiles.name() then
        profiles.activate(name, false)
        vim.notify("Profil « " .. name .. " » appliqué pour ce dossier.", vim.log.levels.INFO)
      end
    end,
  })
  M.apply("*")
  vim.api.nvim_create_autocmd("User", {
    pattern = "VeryLazy",
    once = true,
    callback = function()
      local p = profiles.get()
      pcall(function()
        require("smear_cursor").enabled = p.smear_cursor
      end)
    end,
  })
end

return M
