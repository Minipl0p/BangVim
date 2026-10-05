-- Markdown : rendu stylé dans Neovim + aperçu navigateur (Mermaid, maths, scroll synchronisé).
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = { completions = { blink = { enabled = true } } },
  },
  { "brianhuster/live-preview.nvim", lazy = true },
}
