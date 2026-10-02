return { -- Collection of various small independent plugins/modules
	"echasnovski/mini.nvim",
	-- TEMP(#376 manual testing): eager load so mini.pairs' global <BS> mapping exists
	-- before markdown-plus enables on a buffer opened directly from the CLI
	-- (VeryLazy fires after FileType, so the fallback capture would miss it).
	-- Revert to `event = "VeryLazy"` after testing.
	lazy = false,
	config = function()
		-- Generic a/i textobjects: q = any quote (" ' `), b = brackets, ? = prompt,
		-- plus the n/l next/last modifiers (e.g. yinq). Longest-match wins, so the
		-- explicit af/ic/ao/... maps from nvim-treesitter-textobjects still take
		-- precedence (see treesitter.lua).
		require("mini.ai").setup({ n_lines = 500 })
		require("mini.pairs").setup()
		require("mini.icons").setup()
	end,
}
