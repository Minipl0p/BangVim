-- ╭──────────────────────────────────────────────────────────╮
-- │  Formatage (conform.nvim)                                 │
-- │  Formateur par défaut de chaque langage + alternatives    │
-- │  sélectionnables par profil dans :Param.                  │
-- │  Ajouter un langage : une ligne dans M.by_ft.             │
-- ╰──────────────────────────────────────────────────────────╯
local profiles = require("core.profiles")
local M = {}

-- [filetype] = { défaut, alternatives… }   ("lsp" = formatage fourni par le serveur LSP)
M.by_ft = {
  c = { "clang_format", "lsp" },
  cpp = { "clang_format", "lsp" },
  cs = { "csharpier", "lsp" },
  rust = { "rustfmt", "lsp" },
  go = { "goimports", "gofmt", "lsp" },
  python = { "ruff_format", "black", "lsp" },
  lua = { "stylua", "lsp" },
  java = { "google-java-format", "lsp" },
  sh = { "shfmt" },
  bash = { "shfmt" },
  zsh = { "shfmt" },
  javascript = { "prettier", "biome", "lsp" },
  typescript = { "prettier", "biome", "lsp" },
  javascriptreact = { "prettier", "biome", "lsp" },
  typescriptreact = { "prettier", "biome", "lsp" },
  vue = { "prettier", "lsp" },
  svelte = { "prettier", "lsp" },
  html = { "prettier", "lsp" },
  css = { "prettier", "lsp" },
  scss = { "prettier", "lsp" },
  json = { "prettier", "biome", "lsp" },
  jsonc = { "prettier", "biome", "lsp" },
  yaml = { "prettier", "lsp" },
  markdown = { "prettier" },
  toml = { "taplo", "lsp" },
  sql = { "sql_formatter", "lsp" },
  gdscript = { "gdformat" },
  xml = { "lsp" },
  cmake = { "lsp" },
}

--- Formateur choisi pour un filetype dans le profil actif.
function M.chosen(ft)
  local list = M.by_ft[ft]
  if not list then
    return nil
  end
  local override = (profiles.value("formatters") or {})[ft]
  if override and override ~= "" and vim.tbl_contains(list, override) then
    return override
  end
  return list[1]
end

--- Options pour conform au moment de sauvegarder (nil = pas de formatage).
function M.on_save(buf)
  if not profiles.value("format_on_save") then
    return nil
  end
  local choice = M.chosen(vim.bo[buf].filetype)
  if choice == "lsp" then
    return { timeout_ms = 2000, lsp_format = "prefer", formatters = {} }
  end
  return { timeout_ms = 2000, lsp_format = "fallback", formatters = choice and { choice } or nil }
end

return M
