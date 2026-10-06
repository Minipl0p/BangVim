-- Autocommandes générales.
local au = vim.api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup("ConfigPerso", { clear = true })

-- Surligne brièvement le texte copié.
au("TextYankPost", {
  group = group,
  callback = function()
    vim.hl.on_yank({ timeout = 150 })
  end,
})

-- Revient à la dernière position connue en rouvrant un fichier.
au("BufReadPost", {
  group = group,
  callback = function(ev)
    local mark = vim.api.nvim_buf_get_mark(ev.buf, '"')
    local lines = vim.api.nvim_buf_line_count(ev.buf)
    if mark[1] > 0 and mark[1] <= lines and vim.bo[ev.buf].filetype ~= "gitcommit" then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

-- Les terminaux (terminal flottant, Claude) n'apparaissent pas dans la barre des buffers.
au("TermOpen", {
  group = group,
  callback = function(ev)
    vim.bo[ev.buf].buflisted = false
    vim.wo.number = false
    vim.wo.relativenumber = false
    vim.wo.signcolumn = "no"
  end,
})

-- Démarrage : pas d'écran d'accueil, juste l'arbre flottant.
au("VimEnter", {
  group = group,
  callback = function()
    local argv = vim.fn.argv()
    local dir
    if #argv == 0 then
      dir = vim.uv.cwd()
      -- Le buffer vide « [No Name] » du démarrage : invisible dans la barre des
      -- buffers, et supprimé dès qu'un fichier prend sa place.
      local buf = vim.api.nvim_get_current_buf()
      if vim.api.nvim_buf_get_name(buf) == "" and not vim.bo[buf].modified then
        vim.bo[buf].buflisted = false
        vim.bo[buf].bufhidden = "wipe"
      end
    elseif #argv == 1 and vim.fn.isdirectory(argv[1]) == 1 then
      dir = vim.fn.fnamemodify(argv[1], ":p")
      vim.cmd.cd(vim.fn.fnameescape(dir))
      -- Supprime le buffer vide du dossier.
      local buf = vim.api.nvim_get_current_buf()
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) and vim.fn.isdirectory(vim.api.nvim_buf_get_name(buf)) == 1 then
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
      end)
    end
    if dir then
      vim.schedule(function()
        require("core.tree").open(dir)
      end)
    end
  end,
})

-- Treesitter : coloration et indentation dès qu'un parseur existe pour le langage.
au("FileType", {
  group = group,
  callback = function(ev)
    local lang = vim.treesitter.language.get_lang(ev.match) or ev.match
    if pcall(vim.treesitter.start, ev.buf, lang) then
      local ok, q = pcall(vim.treesitter.query.get, lang, "indents")
      if ok and q then
        vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end
  end,
})

require("core.claude").setup()
require("core.commit_reminder").setup()
