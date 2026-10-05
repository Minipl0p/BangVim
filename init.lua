-- ╭──────────────────────────────────────────────────────────╮
-- │  Config Neovim — point d'entrée                          │
-- │  Linux · WSL · Windows  —  Neovim 0.12 ou plus récent    │
-- ╰──────────────────────────────────────────────────────────╯
if vim.fn.has("nvim-0.12") == 0 then
  vim.api.nvim_echo({ { "Cette config demande Neovim 0.12 ou plus récent.", "ErrorMsg" } }, true, {})
  return
end

-- La touche leader doit être définie avant le chargement des plugins.
vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.options")
require("core.profiles").init() -- les profils sont lus avant les plugins (thème, IA…)
require("config.lazy")
require("config.autocmds")
require("core.keys").setup()
require("core.apply").setup()
require("core.commands")
