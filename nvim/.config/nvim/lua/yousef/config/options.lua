local opt = vim.opt
local g = vim.g
local api = vim.api

-- Leader keys
g.mapleader = " "
g.maplocalleader = " "

-- Nerd font available (checked by lazy.nvim UI and others)
g.have_nerd_font = true

-- General options
opt.mouse = "a" -- Enable mouse support
opt.clipboard = "unnamedplus" -- Use system clipboard
opt.swapfile = false -- Disable swap files
opt.backup = false -- Disable backup files
opt.undofile = true -- Enable persistent undo
opt.undodir = vim.fn.stdpath("data") .. "/undo"
opt.exrc = true -- Enable project-local config (.nvim.lua, .nvimrc, .exrc)

vim.opt.textwidth = 80 -- Set the wrap limit to 80 characters
vim.opt.formatoptions:append("t") -- Auto-wrap text using textwidth

-- UI options
opt.number = true -- Show line numbers
opt.relativenumber = true -- Show relative line numbers
opt.cursorline = true -- Highlight current line
opt.signcolumn = "yes" -- Always show sign column
opt.wrap = true -- Enable line wrapping
opt.textwidth = 80
opt.smoothscroll = true -- Scroll wrapped lines screen-line at a time
opt.scrolloff = 8 -- Keep 8 lines above/below cursor
opt.sidescrolloff = 8 -- Keep 8 columns left/right of cursor
opt.colorcolumn = "120" -- Show column at 120 characters
opt.list = true -- Show whitespace characters
opt.listchars = { tab = "→ ", trail = "·", nbsp = "␣" }
opt.laststatus = 3 -- Global statusline
opt.whichwrap = "b,s,h,l,[,]" -- Allow movement across lines with wrap

-- Split options
opt.splitbelow = true -- Open horizontal splits below
opt.splitright = true -- Open vertical splits to the right

-- Tab options
opt.tabclose = "left" -- Focus left tab when closing a tab (0.11+)

-- Search options
opt.ignorecase = true -- Ignore case in search
opt.smartcase = true -- Case sensitive if uppercase present
opt.inccommand = "split" -- Live preview of search and replace

-- Diff options
opt.diffopt:append("linematch:60") -- Better intra-hunk line matching

-- Indentation options
opt.expandtab = true -- Use spaces instead of tabs
opt.shiftwidth = 2 -- Number of spaces for indentation
opt.tabstop = 2 -- Number of spaces for tab
opt.softtabstop = 2 -- Number of spaces for tab in insert mode
opt.smartindent = true -- Smart indentation

-- Completion options
opt.completeopt = { "menu", "menuone", "noselect", "fuzzy" }
opt.pumheight = 10 -- Popup menu height
opt.pummaxwidth = 80 -- Popup menu max width (0.12+)
opt.pumborder = "rounded" -- Popup menu border (0.12+)

-- Performance options
opt.updatetime = 250 -- CursorHold delay (50 fired reference-highlighting constantly)
opt.timeoutlen = 300 -- Faster key sequence completion

-- Folding options (treesitter-based, async in 0.11+)
opt.foldmethod = "expr"
opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true
opt.foldcolumn = "0"
opt.foldtext = "" -- Show first line of fold with normal syntax highlighting

opt.fillchars:append({
	vert = "▌",
	horiz = "▄",
	fold = " ",
	foldopen = "▼",
	foldclose = "▶",
	foldsep = " ",
	foldinner = " ",
	msgsep = "─",
})

-- Miscellaneous options
opt.isfname:append("@-@")

-- Set default border for all floating windows (Neovim 0.11+)
opt.winborder = "rounded"

-- Colorscheme is set in plugins/bebop.lua with priority 1000.
-- Custom highlights must be re-applied on ColorScheme or the colorscheme
-- (loaded after this file) silently overwrites them.
local function apply_custom_highlights()
	api.nvim_set_hl(0, "VertSplit", { fg = "#5a5a5a", bg = "#5a5a5a", bold = true })
	api.nvim_set_hl(0, "WinSeparator", { fg = "#5a5a5a", bg = "#5a5a5a", bold = true })
	api.nvim_set_hl(0, "ColorColumn", { ctermbg = 236, bg = "#3a3a3a" })
	-- Light gray comments for better visibility on dark background
	api.nvim_set_hl(0, "Comment", { fg = "#e0e0e0", italic = true })
	-- @param tags in comments (matched in autocmds.lua)
	api.nvim_set_hl(0, "CommentParam", { fg = "#00ff7f", bold = true })
end

apply_custom_highlights()
api.nvim_create_autocmd("ColorScheme", {
	group = api.nvim_create_augroup("CustomHighlights", { clear = true }),
	callback = apply_custom_highlights,
})

-- Only copy is supported, paste with Ctrl+shift+v
if vim.env.SSH_TTY then
	local osc52 = require("vim.ui.clipboard.osc52")

	local function copy_reg(reg)
		local orig = osc52.copy(reg)
		return function(lines, regtype)
			-- Write to Vim's internal register
			vim.fn.setreg(reg, table.concat(lines, "\n"), regtype)

			-- Send OSC52 to local clipboard
			orig(lines, regtype)
		end
	end

	vim.g.clipboard = {
		name = "OSC 52 with register sync",
		copy = {
			["+"] = copy_reg("+"),
			["*"] = copy_reg("*"),
		},
		-- Do NOT use OSC52 paste, just use internal registers
		paste = {
			["+"] = function()
				return vim.fn.getreg("+"), "v"
			end,
			["*"] = function()
				return vim.fn.getreg("*"), "v"
			end,
		},
	}

	vim.o.clipboard = "unnamedplus"
end

-- Remote-plugin providers are unused (all plugins are pure Lua); disabling
-- silences :checkhealth provider warnings and skips runtime detection
vim.g.loaded_node_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
