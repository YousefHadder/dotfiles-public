return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		-- JS/TS linting is handled by eslint-lsp.
		-- zsh is excluded: shellcheck does not support zsh.
		lint.linters_by_ft = {
			lua = { "luacheck" },
			ruby = { "rubocop" },
			go = { "revive" },
			python = { "pylint" },
			bash = { "shellcheck" },
			sh = { "shellcheck" },
			terraform = { "tflint" },
			tf = { "tflint" },
		}

		-- Filter at lint time, not load time: mason (VeryLazy) prepends its
		-- bin dir to PATH after this plugin loads, so an executable() check
		-- at setup would silently drop mason-managed linters.
		local function runnable_linters()
			local linters = lint.linters_by_ft[vim.bo.filetype] or {}
			return vim.tbl_filter(function(name)
				return vim.fn.executable(name) == 1
			end, linters)
		end

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({
			"BufEnter",
			"BufWritePost",
			"InsertLeave",
		}, {
			group = lint_augroup,
			callback = function()
				if vim.fn.filereadable(vim.fn.expand("%")) ~= 1 then
					return
				end
				local linters = runnable_linters()
				if #linters > 0 then
					lint.try_lint(linters)
				end
			end,
		})

		-- Manual lint keymap
		vim.keymap.set("n", "<leader>cl", function()
			local linters = runnable_linters()
			if #linters > 0 then
				lint.try_lint(linters)
			else
				vim.notify("No runnable linter for filetype: " .. vim.bo.filetype, vim.log.levels.INFO)
			end
		end, { desc = "[L]int current file" })
	end,
}
