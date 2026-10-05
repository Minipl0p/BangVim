-- Renommer : sémantique (LSP), dans le fichier (texte), dans une sélection.
local M = {}

local function feed(keys)
  vim.api.nvim_feedkeys(vim.keycode(keys), "n", false)
end

--- Renommage LSP dans tout le projet. Invite vide, prête pour le nouveau nom.
function M.lsp()
  local old = vim.fn.expand("<cword>")
  vim.ui.input({ prompt = "Renommer « " .. old .. " » en : " }, function(new)
    if new and new ~= "" and new ~= old then
      vim.lsp.buf.rename(new)
    end
  end)
end

--- :%s/\<mot\>//gI avec le curseur placé pour taper le remplacement.
function M.in_file()
  local word = vim.fn.expand("<cword>")
  if word == "" then
    return
  end
  word = vim.fn.escape(word, [[\/.*$^~[]])
  feed(":%s/\\<" .. word .. "\\>//gI" .. string.rep("<Left>", 3))
end

--- :'<,'>s//g avec le curseur placé pour taper le motif.
function M.in_selection()
  feed(":s//g<Left><Left>")
end

return M
