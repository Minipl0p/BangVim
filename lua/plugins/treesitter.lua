-- Treesitter : coloration et indentation pour tous les langages.
-- Les parseurs s'installent tout seuls (ils demandent `tree-sitter-cli`, installé
-- par Mason, et un compilateur C).
-- Ajouter un langage : l'ajouter à la liste ci-dessous.
local langs = {
  "c", "cpp", "c_sharp", "rust", "go", "gomod", "gosum", "python", "lua", "luadoc", "bash",
  "java", "javascript", "typescript", "tsx", "jsdoc", "html", "css", "scss", "vue", "svelte",
  "json", "yaml", "toml", "xml", "sql", "dockerfile", "make", "cmake",
  "markdown", "markdown_inline", "gdscript", "godot_resource", "gdshader", "hlsl", "glsl",
  "vim", "vimdoc", "query", "regex", "diff", "gitcommit", "git_config", "gitignore", "git_rebase",
}

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = function()
    if vim.fn.executable("tree-sitter") == 1 then
      vim.cmd("TSUpdate")
    end
  end,
  config = function()
    local ts = require("nvim-treesitter")
    ts.setup({})
    local function install()
      ts.install(langs)
    end
    -- Mason place tree-sitter-cli dans le PATH : on attend qu'il soit là.
    vim.defer_fn(function()
      if vim.fn.executable("tree-sitter") == 1 then
        install()
      else
        vim.api.nvim_create_autocmd("User", { pattern = "MasonToolsUpdateCompleted", once = true, callback = install })
      end
    end, 1500)
  end,
}
