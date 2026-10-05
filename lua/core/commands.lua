-- Commandes utilisateur.
local cmd = vim.api.nvim_create_user_command

cmd("Param", function()
  require("core.param").open()
end, { desc = "Fenêtre des paramètres et des profils" })

-- `:param` en minuscules est converti en `:Param`.
vim.cmd([[cnoreabbrev <expr> param (getcmdtype() ==# ':' && getcmdline() ==# 'param') ? 'Param' : 'param']])

cmd("Profil", function(o)
  local profiles = require("core.profiles")
  if o.args == "" then
    vim.notify("Profil actif : " .. profiles.name())
  else
    profiles.activate(o.args)
  end
end, {
  nargs = "?",
  complete = function()
    return require("core.profiles").list()
  end,
  desc = "Afficher ou changer le profil",
})

cmd("MarkdownApercu", function()
  require("core.markdown").start()
end, { desc = "Aperçu Markdown dans le navigateur" })

cmd("MarkdownStop", function()
  require("core.markdown").stop()
end, { desc = "Arrêter l'aperçu Markdown" })
