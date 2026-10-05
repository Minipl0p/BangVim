-- Complétion : menu classique (blink.cmp) + suggestions IA en texte grisé (NeoCodeium).
-- Les touches IA (Tab, <C-l>, <C-j>, <C-]>, <C-e>) sont posées par core/keys.lua.
return {
  {
    "saghen/blink.cmp",
    version = "1.*",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = { "rafamadriz/friendly-snippets" },
    opts = {
      keymap = {
        preset = "none",
        ["<C-n>"] = { "select_next", "fallback" },
        ["<C-p>"] = { "select_prev", "fallback" },
        ["<CR>"] = { "accept", "fallback" },
        ["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
        ["<C-e>"] = { "hide", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },
      },
      appearance = { nerd_font_variant = "mono" },
      completion = {
        menu = { border = "rounded", draw = { treesitter = { "lsp" } } },
        documentation = { auto_show = true, auto_show_delay_ms = 300, window = { border = "rounded" } },
        ghost_text = { enabled = false }, -- le texte grisé est réservé à l'IA
      },
      signature = { enabled = true, window = { border = "rounded" } },
      sources = { default = { "lsp", "path", "snippets", "buffer" } },
      cmdline = { enabled = false }, -- noice gère la ligne de commande
      fuzzy = { implementation = "prefer_rust_with_warning" },
    },
  },
  {
    "monkoose/neocodeium",
    event = "InsertEnter",
    config = function()
      local nc = require("neocodeium")
      nc.setup({
        enabled = require("core.profiles").value("ai_completion") ~= false,
        show_label = true,
        silent = true,
        filetypes = { ["snacks_picker_input"] = false, ["neo-tree-popup"] = false, ["snacks_input"] = false },
      })
      -- Pas de suggestion IA pendant que le menu de complétion est ouvert.
      vim.api.nvim_create_autocmd("User", { pattern = "BlinkCmpMenuOpen", callback = nc.clear })
    end,
  },
}
