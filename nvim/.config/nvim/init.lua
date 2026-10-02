for _, layer in ipairs({ "dotfiles-work", "dotfiles-local" }) do
	local path = vim.env.HOME .. "/.config/" .. layer .. "/nvim/before.lua"
	if vim.uv.fs_stat(path) then
		dofile(path)
	end
end
require("yousef.config")
require("yousef.lazy")
-- Filetype detection is now in the top-level filetype.lua (auto-loaded by Neovim)
for _, layer in ipairs({ "dotfiles-work", "dotfiles-local" }) do
	local path = vim.env.HOME .. "/.config/" .. layer .. "/nvim/init.lua"
	if vim.uv.fs_stat(path) then
		dofile(path)
	end
end
