-- ╭──────────────────────────────────────────────────────────╮
-- │  LSP : serveurs installés automatiquement par Mason       │
-- │  Ajouter un langage :                                     │
-- │    1. son serveur (nom Mason) dans `tools`                │
-- │    2. son nom lspconfig dans `servers`                    │
-- ╰──────────────────────────────────────────────────────────╯
local tools = {
  -- Serveurs LSP
  "clangd", "rust-analyzer", "gopls", "pyright", "lua-language-server", "bash-language-server",
  "jdtls", "typescript-language-server", "html-lsp", "css-lsp", "tailwindcss-language-server",
  "vue-language-server", "svelte-language-server", "json-lsp", "yaml-language-server", "taplo",
  "lemminx", "sqls", "dockerfile-language-server", "neocmakelsp", "marksman", "glsl_analyzer",
  "roslyn-language-server",
  -- Formateurs
  "stylua", "clang-format", "csharpier", "ruff", "black", "prettier", "shfmt",
  "google-java-format", "sql-formatter", "goimports", "gdtoolkit",
  -- Débogueurs
  "codelldb", "debugpy", "delve", "js-debug-adapter", "java-debug-adapter",
  -- Treesitter
  "tree-sitter-cli",
}

local servers = {
  "clangd", "rust_analyzer", "gopls", "pyright", "lua_ls", "bashls", "ts_ls", "html", "cssls",
  "tailwindcss", "vue_ls", "svelte", "jsonls", "yamlls", "taplo", "lemminx", "sqls", "dockerls",
  "neocmake", "marksman", "glsl_analyzer", "gdscript",
}

return {
  { "mason-org/mason.nvim", lazy = false, opts = { ui = { border = "rounded" } } },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    lazy = false,
    dependencies = { "mason-org/mason.nvim" },
    opts = {
      ensure_installed = tools,
      run_on_start = true,
      start_delay = 1000,
      integrations = { ["mason-lspconfig"] = false, ["mason-null-ls"] = false, ["mason-nvim-dap"] = false },
    },
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason-org/mason.nvim" },
    config = function()
      -- C / C++ (et Unreal via compile_commands.json).
      vim.lsp.config("clangd", {
        cmd = {
          "clangd", "--background-index", "--clang-tidy", "--header-insertion=never",
          "--completion-style=detailed", "--function-arg-placeholders", "--fallback-style=llvm",
        },
      })
      vim.lsp.config("lua_ls", {
        settings = {
          Lua = {
            workspace = { checkThirdParty = false },
            completion = { callSnippet = "Replace" },
            diagnostics = { globals = { "vim", "Snacks" } },
          },
        },
      })
      -- TypeScript + Vue (le plugin Vue est fourni par le paquet Mason vue-language-server).
      local vue_plugin = vim.fs.joinpath(vim.fn.stdpath("data"), "mason", "packages", "vue-language-server",
        "node_modules", "@vue", "language-server")
      vim.lsp.config("ts_ls", {
        init_options = {
          plugins = { { name = "@vue/typescript-plugin", location = vue_plugin, languages = { "vue" } } },
        },
        filetypes = { "javascript", "javascriptreact", "typescript", "typescriptreact", "vue" },
      })
      vim.lsp.enable(servers)
    end,
  },

  -- C# / Unity : serveur Roslyn (le même que VS Code). Demande le SDK .NET.
  { "seblyng/roslyn.nvim", ft = "cs", opts = { filewatching = "auto" } },

  -- Java : jdtls + débogage.
  {
    "mfussenegger/nvim-jdtls",
    ft = "java",
    config = function()
      local function attach()
        local root = vim.fs.root(0, { "gradlew", "mvnw", "pom.xml", "build.gradle", "build.gradle.kts", ".git" })
        if not root then
          return
        end
        local mason = vim.fs.joinpath(vim.fn.stdpath("data"), "mason")
        local bundles = vim.fn.glob(mason .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar", true, true)
        local workspace = vim.fs.joinpath(vim.fn.stdpath("cache"), "jdtls", vim.fn.fnamemodify(root, ":p:h:t"))
        require("jdtls").start_or_attach({
          cmd = { vim.fn.exepath("jdtls") ~= "" and vim.fn.exepath("jdtls") or "jdtls", "-data", workspace },
          root_dir = root,
          init_options = { bundles = bundles },
          on_attach = function()
            pcall(function()
              require("jdtls").setup_dap({ hotcodereplace = "auto" })
              require("jdtls.dap").setup_dap_main_class_configs()
            end)
          end,
        })
      end
      vim.api.nvim_create_autocmd("FileType", { pattern = "java", callback = attach })
      attach()
    end,
  },
}
