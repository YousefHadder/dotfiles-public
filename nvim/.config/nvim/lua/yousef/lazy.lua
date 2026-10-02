local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
	local success = pcall(vim.fn.system, {
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})

	if not success then
		vim.notify("Failed to clone lazy.nvim", vim.log.levels.ERROR)
		return
	end
end

vim.opt.runtimepath:prepend(lazypath)

require("lazy").setup({
	spec = {
		{ import = "yousef.plugins" },
	},
	checker = {
		enabled = true,
		notify = false,
	},
	-- No rockspec-based plugins in use; disabling stops :checkhealth lazy
	-- from demanding a lua 5.1 + luarocks toolchain
	rocks = {
		enabled = false,
	},
	change_detection = {
		notify = false,
	},
	-- Move UI options into the main opts table so Lazy applies them
	ui = {
		border = "rounded",
		icons = vim.g.have_nerd_font and {} or {
			cmd = "⌘",
			config = "🛠",
			event = "📅",
			ft = "📂",
			init = "⚙",
			keys = "🗝",
			plugin = "🔌",
			runtime = "💻",
			require = "🌙",
			source = "📄",
			start = "🚀",
			task = "📌",
			lazy = "💤 ",
		},
	},
})
