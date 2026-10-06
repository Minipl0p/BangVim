-- Suggestions IA en texte grisé (GitHub Copilot) + repli sur le comportement normal.
local M = {}

local function sug()
	if not package.loaded["copilot"] then
		return nil
	end
	local ok, s = pcall(require, "copilot.suggestion")
	if ok and s.is_visible() then
		return s
	end
end

local function fallback(key)
	vim.api.nvim_feedkeys(vim.keycode(key), "n", false)
end

function M.accept()
	local s = sug()
	if s then
		return s.accept()
	end
	if vim.snippet.active({ direction = 1 }) then
		return vim.snippet.jump(1)
	end
	fallback("<Tab>")
end

function M.accept_word()
	local s = sug()
	if s then
		return s.accept_word()
	end
end

function M.accept_line()
	local s = sug()
	if s then
		return s.accept_line()
	end
	fallback("<C-j>")
end

function M.cycle()
	if package.loaded["copilot"] then
		require("copilot.suggestion").next()
	end
end

function M.clear()
	local s = sug()
	if s then
		s.dismiss()
	end
end

--- Active ou coupe les suggestions selon le profil.
function M.set_enabled(on)
	if not package.loaded["copilot"] then
		return
	end
	pcall(vim.cmd, "Copilot " .. (on and "enable" or "disable"))
end

return M
