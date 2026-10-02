-- Seamless <C-h/j/k/l> navigation between Neovim splits and multiplexer panes.
--
-- Replaces christoomey/vim-tmux-navigator, which only spoke tmux (it shells out
-- to `tmux select-pane`) and so could not cross herdr pane boundaries.
--
-- The multiplexer back-end is auto-detected at startup: HERDR_ENV picks the
-- herdr back-end, TERM_PROGRAM=tmux picks tmux. One config covers both, so the
-- same keys work whichever multiplexer is in use.
--
-- The herdr side is driven by the plugin shipped in this repo
-- (herdr-plugin.toml + scripts/herdr-navigate.sh), linked with:
--   herdr plugin link ~/.local/share/nvim/lazy/smart-splits.nvim
-- and bound to ctrl+h/j/k/l as plugin_action entries in
-- ~/.config/herdr/config.toml. That script is the herdr equivalent of tmux's
-- @pane-is-vim check: it asks `herdr pane process-info` whether the focused
-- pane runs vim/nvim, then either forwards the key or moves herdr focus.
return {
	"mrjones2014/smart-splits.nvim",
	lazy = false, -- keys must be live immediately; nav is a base motion
	opts = {
		-- multiplexer_integration intentionally unset: auto-detects herdr vs tmux.
		at_edge = "stop", -- do not wrap; let the multiplexer take the edge instead
		ignored_filetypes = { "NvimTree", "neo-tree" },
	},
	config = function(_, opts)
		require("smart-splits").setup(opts)

		local map = vim.keymap.set
		local smart_splits = require("smart-splits")

		map("n", "<C-h>", smart_splits.move_cursor_left, { desc = "Move to split/pane left" })
		map("n", "<C-j>", smart_splits.move_cursor_down, { desc = "Move to split/pane below" })
		map("n", "<C-k>", smart_splits.move_cursor_up, { desc = "Move to split/pane above" })
		map("n", "<C-l>", smart_splits.move_cursor_right, { desc = "Move to split/pane right" })
	end,
}
