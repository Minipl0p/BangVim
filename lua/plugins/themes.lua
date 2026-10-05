-- Thèmes. Catppuccin Mocha par défaut ; le choix se fait dans :Param (aperçu en direct).
-- Ajouter un thème : une ligne ici, il apparaît tout seul dans le sélecteur.
return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true, -- laisse voir le dégradé de WezTerm
      float = { transparent = false, solid = false },
      integrations = { blink_cmp = true, neotree = true, noice = true, snacks = true, which_key = true, flash = true },
    },
  },
  { "folke/tokyonight.nvim", lazy = false, priority = 900, opts = { transparent = true } },
  { "rebelot/kanagawa.nvim", lazy = false, priority = 900, opts = { transparent = true } },
  { "rose-pine/neovim", name = "rose-pine", lazy = false, priority = 900, opts = { styles = { transparency = true } } },
  { "EdenEast/nightfox.nvim", lazy = false, priority = 900, opts = { options = { transparent = true } } },
  { "navarasu/onedark.nvim", lazy = false, priority = 900, opts = { transparent = true } },
  { "scottmckendry/cyberdream.nvim", lazy = false, priority = 900, opts = { transparent = true } },
  { "Mofiqul/dracula.nvim", lazy = false, priority = 900, opts = { transparent_bg = true } },
  { "gbprod/nord.nvim", lazy = false, priority = 900, opts = { transparent = true } },
  { "projekt0n/github-nvim-theme", name = "github-theme", lazy = false, priority = 900, opts = { options = { transparent = true } } },
  { "sainnhe/gruvbox-material", lazy = false, priority = 900, init = function() vim.g.gruvbox_material_transparent_background = 1 end },
  { "sainnhe/everforest", lazy = false, priority = 900, init = function() vim.g.everforest_transparent_background = 1 end },
  { "sainnhe/sonokai", lazy = false, priority = 900, init = function() vim.g.sonokai_transparent_background = 1 end },
  { "nyoom-engineering/oxocarbon.nvim", lazy = false, priority = 900 },
}
