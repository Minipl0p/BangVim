-- Interface du débogueur : « panneaux » (style VS Code) ou « flottant » (à la demande).
local profiles = require("core.profiles")
local M = {}

local elements = {
  { "Variables", "scopes" },
  { "Pile d'appels", "stacks" },
  { "Breakpoints", "breakpoints" },
  { "Expressions surveillées", "watches" },
  { "Console", "repl" },
}

local function layout()
  return profiles.value("debug_layout") or "panneaux"
end

function M.toggle_ui()
  local dapui = require("dapui")
  if layout() == "panneaux" then
    dapui.toggle({ reset = true })
    return
  end
  vim.ui.select(elements, {
    prompt = "Vue de debug",
    format_item = function(item)
      return item[1]
    end,
  }, function(choice)
    if choice then
      dapui.float_element(choice[2], { enter = true, width = 90, height = 22, position = "center" })
    end
  end)
end

function M.conditional()
  vim.ui.input({ prompt = "Condition du breakpoint : " }, function(cond)
    if cond and cond ~= "" then
      require("dap").set_breakpoint(cond)
    end
  end)
end

--- Ouverture / fermeture automatiques des panneaux au début et à la fin d'une session.
function M.setup_listeners()
  local dap, dapui = require("dap"), require("dapui")
  dap.listeners.after.event_initialized["interface"] = function()
    if layout() == "panneaux" then
      dapui.open({ reset = true })
    end
  end
  local function close()
    if layout() == "panneaux" then
      dapui.close()
    end
  end
  dap.listeners.before.event_terminated["interface"] = close
  dap.listeners.before.event_exited["interface"] = close
end

return M
