-- Débogueur (nvim-dap) pour C/C++/Rust, Python, Go, JS/TS (Java : voir lsp.lua).
-- Les moteurs de jeu se déboguent dans Rider.
return {
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    dependencies = {
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "jay-babu/mason-nvim-dap.nvim",
      "theHamsta/nvim-dap-virtual-text",
    },
    config = function()
      vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DiagnosticError" })
      vim.fn.sign_define("DapBreakpointCondition", { text = "◆", texthl = "DiagnosticWarn" })
      vim.fn.sign_define("DapStopped", { text = "▶", texthl = "DiagnosticOk", linehl = "Visual" })

      require("dapui").setup({ floating = { border = "rounded" } })
      require("nvim-dap-virtual-text").setup({})
      -- Adaptateurs installés par Mason, configurés automatiquement.
      require("mason-nvim-dap").setup({
        ensure_installed = { "codelldb", "python", "delve", "js" },
        automatic_installation = false,
        handlers = {},
      })
      require("core.debug").setup_listeners()
    end,
  },
}
