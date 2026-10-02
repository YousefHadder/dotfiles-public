return {
	"zbirenbaum/copilot.lua",
	cmd = "Copilot",
	event = "InsertEnter",
	config = function()
		require("copilot").setup({
			suggestion = {
				auto_trigger = true,
				hide_during_completion = true,
				keymap = {
					accept = "<S-Tab>",
					accept_word = "<C-w>",
					accept_line = "<C-l>",
				},
			},
		})

		-- Hide Copilot ghost text while Blink's menu is visible
		-- (copilot.lua's hide_during_completion only knows nvim-cmp, not blink).
		-- The suggestion reappears on the next text change — no manual re-trigger,
		-- which used to fire requests even when leaving insert mode.
		vim.api.nvim_create_autocmd("User", {
			pattern = "BlinkCmpMenuOpen",
			group = vim.api.nvim_create_augroup("CopilotBlinkHarmony", { clear = true }),
			callback = function()
				require("copilot.suggestion").dismiss()
			end,
		})
	end,
}
