-- Interface : barre des buffers, statusline, ligne de commande flottante,
-- aide aux raccourcis, séparateurs, curseur.
return {
  { "nvim-tree/nvim-web-devicons", lazy = true },
  { "MunifTanjim/nui.nvim", lazy = true },

  -- Barre des buffers (style LazyVim : onglets inclinés).
  {
    "akinsho/bufferline.nvim",
    version = "*",
    event = "VeryLazy",
    opts = {
      options = {
        mode = "buffers",
        separator_style = "slant",
        always_show_bufferline = true,
        show_buffer_close_icons = false,
        show_close_icon = false,
        diagnostics = "nvim_lsp",
        close_command = function(n)
          Snacks.bufdelete(n)
        end,
        custom_filter = function(buf)
          return vim.bo[buf].buftype == ""
        end,
      },
    },
  },

  -- Statusline.
  {
    "nvim-lualine/lualine.nvim",
    event = "VeryLazy",
    opts = function()
      local reminder = require("core.commit_reminder")
      return {
        options = {
          theme = "auto",
          globalstatus = true,
          section_separators = { left = "", right = "" },
          component_separators = "",
          disabled_filetypes = { statusline = { "neo-tree" } },
        },
        sections = {
          lualine_a = { { "mode", separator = { left = "", right = "" } } },
          lualine_b = { "branch" },
          lualine_c = { { "filename", path = 1 }, "diagnostics" },
          lualine_x = {
            { reminder.status, color = reminder.color },
            "filetype",
          },
          lualine_y = {
            {
              function()
                return " " .. require("core.profiles").name()
              end,
            },
          },
          lualine_z = { { "location", separator = { left = "", right = "" } } },
        },
      }
    end,
  },

  -- Ligne de commande et messages en flottant.
  {
    "folke/noice.nvim",
    event = "VeryLazy",
    dependencies = { "MunifTanjim/nui.nvim" },
    opts = {
      cmdline = { view = "cmdline_popup" },
      lsp = {
        hover = { enabled = false }, -- géré par K (bordure arrondie)
        signature = { enabled = false }, -- géré par blink.cmp
        override = {
          ["vim.lsp.util.convert_input_to_markdown_lines"] = true,
          ["vim.lsp.util.stylize_markdown"] = true,
        },
      },
      presets = { command_palette = true, long_message_to_split = true, lsp_doc_border = true },
      routes = {
        { filter = { event = "msg_show", find = "%d+B written" }, opts = { skip = true } },
        { filter = { event = "msg_show", find = "écrit" }, opts = { skip = true } },
      },
    },
  },

  -- Aide aux raccourcis : uniquement les raccourcis de cette config.
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {
      preset = "modern",
      delay = 400,
      filter = function(m)
        local owned = require("core.keys").owned
        return owned[m.mode .. ":" .. vim.fn.keytrans(vim.keycode(m.lhs))] == true
      end,
      plugins = {
        marks = false,
        registers = false,
        spelling = { enabled = false },
        presets = { operators = false, motions = false, text_objects = false, windows = false, nav = false, z = false, g = false },
      },
      icons = { mappings = false },
    },
  },

  -- Bordure colorée autour du split actif.
  {
    "nvim-zh/colorful-winsep.nvim",
    event = "WinLeave",
    config = function()
      local function hl()
        local accent = vim.api.nvim_get_hl(0, { name = "Function", link = false }).fg
        vim.api.nvim_set_hl(0, "ColorfulWinSep", { fg = accent })
      end
      require("colorful-winsep").setup({ border = "single", excluded_ft = { "neo-tree", "snacks_picker_input", "param" } })
      hl()
      vim.api.nvim_create_autocmd("ColorScheme", { callback = hl })
    end,
  },

  -- Traînée animée du curseur (activable dans :Param).
  { "sphamba/smear-cursor.nvim", event = "VeryLazy", opts = { legacy_computing_symbols_support = false } },
}
