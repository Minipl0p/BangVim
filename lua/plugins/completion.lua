-- Complétion : menu classique (blink.cmp) + suggestions IA en texte grisé (NeoCodeium).
-- Les touches IA (Tab, <C-l>, <C-j>, <C-]>, <C-e>) sont posées par core/keys.lua.
return {
	{
		"saghen/blink.cmp",
		version = "1.*",
		event = { "InsertEnter", "CmdlineEnter" },
		dependencies = { "rafamadriz/friendly-snippets" },
		opts = {
			keymap = {
				preset = "none",
				["<C-n>"] = { "select_next", "fallback" },
				["<C-p>"] = { "select_prev", "fallback" },
				["<CR>"] = { "accept", "fallback" },
				["<C-Space>"] = { "show", "show_documentation", "hide_documentation" },
				["<C-e>"] = { "hide", "fallback" },
				["<S-Tab>"] = { "snippet_backward", "fallback" },
			},
			appearance = { nerd_font_variant = "mono" },
			completion = {
				menu = { border = "rounded", draw = { treesitter = { "lsp" } } },
				documentation = { auto_show = true, auto_show_delay_ms = 300, window = { border = "rounded" } },
				ghost_text = { enabled = false }, -- le texte grisé est réservé à l'IA
			},
			signature = { enabled = true, window = { border = "rounded" } },
			sources = { default = { "lsp", "path", "snippets", "buffer" } },
			cmdline = { enabled = false }, -- noice gère la ligne de commande
			fuzzy = { implementation = "prefer_rust_with_warning" },
		},
	},
	{
		"zbirenbaum/copilot.lua",
		cmd = "Copilot",
		event = "InsertEnter",
		config = function()
			require("copilot").setup({
				suggestion = {
					enabled = true,
					auto_trigger = true,
					hide_during_completion = true,
					-- Les touches sont posées par core/keys.lua.
					keymap = {
						accept = false,
						accept_word = false,
						accept_line = false,
						next = false,
						prev = false,
						dismiss = false,
					},
				},
				panel = { enabled = false },
			})
			if require("core.profiles").value("ai_completion") == false then
				vim.cmd("Copilot disable")
			end
		end,
	},
}
