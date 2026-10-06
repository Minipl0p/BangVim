-- ╭──────────────────────────────────────────────────────────╮
-- │  WezTerm — config minimale et jolie                       │
-- │  Linux · WSL · Windows                                    │
-- │  Copier vers  ~/.wezterm.lua  (Windows : %USERPROFILE%)   │
-- ╰──────────────────────────────────────────────────────────╯
local wezterm = require("wezterm")
local config = wezterm.config_builder()
local is_windows = wezterm.target_triple:find("windows") ~= nil

-- ── Police (changer ici) ─────────────────────────────────────
-- Autres choix : "Maple Mono NF", "Iosevka Nerd Font", "Monaspace Neon"
config.font = wezterm.font_with_fallback({ "JetBrainsMono Nerd Font", "JetBrains Mono" })
config.font_size = 12.5
config.line_height = 1.1

-- ── Couleurs et fond ─────────────────────────────────────────
config.color_scheme = "Catppuccin Mocha"
config.window_background_opacity = 1.0 -- opaque : le fond d'écran ne se voit pas
-- Léger dégradé avec un peu de bruit pour casser l'aspect « couleur unie ».
config.window_background_gradient = {
	orientation = { Linear = { angle = -45.0 } },
	colors = { "#11111b", "#1e1e2e", "#181825", "#1e1e2e" },
	interpolation = "CatmullRom",
	blend = "Oklab",
	noise = 48,
}

-- ── Fenêtre ──────────────────────────────────────────────────
config.enable_tab_bar = false -- pas d'onglets : tout se passe dans Neovim
config.window_decorations = "RESIZE"
config.window_padding = { left = 10, right = 10, top = 8, bottom = 4 }
config.initial_cols = 160
config.initial_rows = 45
config.adjust_window_size_when_changing_font_size = false
config.audible_bell = "Disabled"

-- ── Curseur ──────────────────────────────────────────────────
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 600
config.cursor_blink_ease_in = "EaseOut"
config.cursor_blink_ease_out = "EaseIn"
config.animation_fps = 120
config.max_fps = 120

-- ── Clavier ──────────────────────────────────────────────────
-- Protocole clavier kitty : indispensable pour <C-;>, <C-/>, <C-S-q>, Tab ≠ <C-i>…
config.enable_kitty_keyboard = true
config.allow_win32_input_mode = false
config.keys = {
	-- Raccourcis d'onglets inutiles ici : ils restent disponibles pour Neovim.
	{ key = "Tab", mods = "CTRL", action = wezterm.action.DisableDefaultAssignment },
	{ key = "Tab", mods = "CTRL|SHIFT", action = wezterm.action.DisableDefaultAssignment },
}

-- ── Shell par défaut ─────────────────────────────────────────
if is_windows then
	local has_pwsh = wezterm.run_child_process({ "cmd.exe", "/c", "where", "pwsh.exe" })
	config.default_prog = { has_pwsh and "pwsh.exe" or "powershell.exe", "-NoLogo" }
	-- Pour WSL : taper `wsl` dans le terminal (ou décommenter la ligne suivante).
	-- config.default_domain = "WSL:Ubuntu"
end

-- ── Aperçu Markdown : Neovim demande à WezTerm de se placer à gauche ──
wezterm.on("user-var-changed", function(window, _, name, value)
	if name ~= "nvim_layout" then
		return
	end
	local screen = wezterm.gui.screens().active
	if value == "left" then
		window:restore()
		window:set_position(screen.x, screen.y)
		window:set_inner_size(math.floor(screen.width / 2), screen.height - 60)
	elseif value == "restore" then
		window:maximize()
	end
end)

return config
