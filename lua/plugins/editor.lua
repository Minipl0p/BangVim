-- Édition : sauts rapides (flash) et historique des copies (yanky).
-- Les touches sont posées par core/keys.lua (modifiables par profil).
return {
  {
    "folke/flash.nvim",
    lazy = true,
    opts = {
      label = { uppercase = false },
      modes = { search = { enabled = false }, char = { enabled = true } },
    },
  },
  {
    "gbprod/yanky.nvim",
    event = "VeryLazy",
    dependencies = { "folke/snacks.nvim" }, -- chargé après snacks : le picker s'enregistre tout seul
    opts = {
      ring = { history_length = 50, storage = "memory", ignore_registers = { "_" } },
      highlight = { on_put = true, on_yank = false, timer = 150 },
      system_clipboard = { sync_with_ring = true },
    },
  },
}
