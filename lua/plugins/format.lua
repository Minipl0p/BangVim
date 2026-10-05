-- Formatage à la sauvegarde (conform.nvim). Le choix des formateurs est dans core/format.lua.
return {
  "stevearc/conform.nvim",
  event = "BufWritePre",
  cmd = "ConformInfo",
  opts = function()
    local format = require("core.format")
    local by_ft = {}
    for ft, list in pairs(format.by_ft) do
      if list[1] ~= "lsp" then
        by_ft[ft] = { list[1] }
      end
    end
    return {
      formatters_by_ft = by_ft,
      default_format_opts = { lsp_format = "fallback" },
      format_on_save = function(buf)
        return format.on_save(buf)
      end,
      notify_no_formatters = false,
    }
  end,
}
