-- Arbre de fichiers flottant (neo-tree).
local M = {}

function M.open(dir)
  require("neo-tree.command").execute({
    source = "filesystem",
    position = "float",
    reveal = vim.bo.buftype == "" and vim.api.nvim_buf_get_name(0) ~= "",
    dir = dir,
    toggle = true,
  })
end

return M
