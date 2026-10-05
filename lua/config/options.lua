-- Options générales de Neovim.
local platform = require("core.platform")
local o = vim.opt

o.number = true
o.relativenumber = true
o.mouse = "a" -- souris active : redimensionner les splits en tirant les bordures
o.mousemoveevent = true
o.termguicolors = true
o.signcolumn = "yes"
o.cursorline = true
o.scrolloff = 8
o.sidescrolloff = 8
o.wrap = false
o.splitright = true
o.splitbelow = true
o.splitkeep = "screen"
o.undofile = true
o.swapfile = false
o.ignorecase = true
o.smartcase = true
o.updatetime = 250
o.timeoutlen = 400
o.laststatus = 3 -- une seule statusline globale
o.showmode = false
o.cmdheight = 0 -- la ligne de commande s'affiche en flottant (noice)
o.fillchars = { eob = " ", fold = " " }
o.expandtab = true
o.shiftwidth = 4
o.tabstop = 4
o.smartindent = true
o.confirm = true
o.pumheight = 12
o.winborder = "rounded" -- bordure arrondie par défaut pour les fenêtres flottantes
o.shortmess:append("sIc")

-- Presse-papier système (chargé après le démarrage pour ne pas le ralentir).
vim.schedule(function()
  if platform.is_wsl and not platform.has("win32yank.exe") then
    local paste = 'powershell.exe -NoLogo -NoProfile -c [Console]::Out.Write($(Get-Clipboard -Raw).tostring().replace("`r", ""))'
    vim.g.clipboard = {
      name = "WSL",
      copy = { ["+"] = "clip.exe", ["*"] = "clip.exe" },
      paste = { ["+"] = paste, ["*"] = paste },
      cache_enabled = 0,
    }
  end
  o.clipboard = "unnamedplus"
end)

-- Windows : PowerShell comme shell (`:!`, terminal flottant…).
if platform.is_windows then
  vim.o.shell = platform.has("pwsh") and "pwsh" or "powershell"
  vim.o.shellcmdflag =
    "-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;"
  vim.o.shellredir = '2>&1 | %%{ "$_" } | Out-File %s; exit $LastExitCode'
  vim.o.shellpipe = '2>&1 | %%{ "$_" } | Tee-Object %s; exit $LastExitCode'
  vim.o.shellquote = ""
  vim.o.shellxquote = ""
end

-- Diagnostics : flottants arrondis, texte virtuel discret.
vim.diagnostic.config({
  virtual_text = { spacing = 2, prefix = "●" },
  severity_sort = true,
  float = { border = "rounded", source = true },
  signs = {
    text = {
      [vim.diagnostic.severity.ERROR] = "",
      [vim.diagnostic.severity.WARN] = "",
      [vim.diagnostic.severity.INFO] = "",
      [vim.diagnostic.severity.HINT] = "",
    },
  },
})
