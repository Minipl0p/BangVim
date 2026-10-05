-- Terminal flottant (indépendant de Claude Code).
local M = {}

function M.toggle()
  Snacks.terminal.toggle(nil, {
    win = {
      position = "float",
      width = 0.8,
      height = 0.75,
      border = "rounded",
      title = " Terminal ",
      title_pos = "center",
      keys = {
        -- Même touche pour cacher le terminal depuis le mode terminal.
        hide_term = { require("core.keys").get("term_toggle"), "hide", mode = "t", desc = "Cacher le terminal" },
      },
    },
  })
end

return M
