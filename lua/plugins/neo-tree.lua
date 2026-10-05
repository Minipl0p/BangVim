-- Arbre de fichiers, toujours flottant. h/l pour replier/déplier.
return {
  "nvim-neo-tree/neo-tree.nvim",
  branch = "v3.x",
  cmd = "Neotree",
  dependencies = { "nvim-lua/plenary.nvim", "nvim-tree/nvim-web-devicons", "MunifTanjim/nui.nvim" },
  opts = {
    popup_border_style = "rounded",
    enable_git_status = true,
    enable_diagnostics = true,
    close_if_last_window = false,
    window = {
      position = "float",
      popup = { size = { width = 60, height = "75%" }, position = "50%" },
      mappings = {
        ["l"] = "open",
        ["<CR>"] = "open",
        -- Ouvrir le fichier et fermer tous les autres buffers.
        ["<C-CR>"] = function(state)
          local node = state.tree:get_node()
          require("neo-tree.sources.filesystem.commands").open(state)
          if node.type == "file" then
            vim.schedule(function()
              require("core.buffers").close_others()
            end)
          end
        end,
        -- Dossier ouvert : le replier. Sinon : remonter au parent et le replier.
        ["h"] = function(state)
          local node = state.tree:get_node()
          local fs = require("neo-tree.sources.filesystem")
          if node.type == "directory" and node:is_expanded() then
            fs.toggle_directory(state, node)
            return
          end
          local parent_id = node:get_parent_id()
          if parent_id then
            local parent = state.tree:get_node(parent_id)
            require("neo-tree.ui.renderer").focus_node(state, parent_id)
            if parent and parent.type == "directory" and parent:is_expanded() then
              fs.toggle_directory(state, parent)
            end
          end
        end,
      },
    },
    filesystem = {
      hijack_netrw_behavior = "disabled",
      follow_current_file = { enabled = true },
      use_libuv_file_watcher = true,
      filtered_items = { visible = true, hide_dotfiles = false, hide_gitignored = false },
    },
    default_component_configs = {
      indent = { with_expanders = true },
      git_status = {
        symbols = { added = "", modified = "", deleted = "", renamed = "", untracked = "", ignored = "", unstaged = "", staged = "", conflict = "" },
      },
    },
  },
}
