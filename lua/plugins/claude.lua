-- Claude Code dans un split vertical à droite.
-- Touches : voir core/keys.lua (<leader>a, <C-;>, <C-j>/<C-k>, <leader>Q).
return {
  "coder/claudecode.nvim",
  event = "VeryLazy",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    terminal = {
      split_side = "right",
      split_width_percentage = 0.38,
      provider = "native", -- terminal simple : aucune touche ajoutée par-dessus Claude
    },
    diff_opts = { layout = "vertical", open_in_new_tab = false },
  },
}
