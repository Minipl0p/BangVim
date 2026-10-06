-- snacks.nvim : picker flottant (fichiers, grep, buffers…), terminal flottant,
-- lazygit, notifications, saisie flottante, guides d'indentation.
return {
	"folke/snacks.nvim",
	lazy = false,
	priority = 1000,
	opts = {
		bigfile = { enabled = true },
		notifier = { enabled = true, timeout = 3000 },
		input = { enabled = true },
		picker = {
			enabled = true,
			ui_select = true, -- vim.ui.select devient un picker flottant
			layout = { preset = "default" },
			sources = {
				files = { hidden = true },
				grep = { hidden = true },
			},
		},
		terminal = { enabled = true },
		lazygit = { enabled = true, configure = true },
		indent = { enabled = true },
		scroll = { enabled = true },
		words = { enabled = true },
		dashboard = { enabled = false },
		explorer = { enabled = false },
		statuscolumn = { enabled = false },
	},
}
