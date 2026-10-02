return { -- Autoformat
	"stevearc/conform.nvim",
	event = { "BufWritePre" },
	cmd = { "ConformInfo" },
	keys = {
		{
			"<leader>cf",
			function()
				require("conform").format({ async = true, lsp_format = "fallback" })
			end,
			mode = "",
			desc = "[F]ormat buffer",
		},
	},
	opts = {
		notify_on_error = false,
		format_on_save = function(bufnr)
			-- Disable "format_on_save lsp_fallback" for languages that don't
			-- have a well standardized coding style. You can add additional
			-- languages here or re-enable it for the disabled ones.
			local disable_filetypes = { c = true, cpp = true }
			if disable_filetypes[vim.bo[bufnr].filetype] then
				return nil
			else
				return {
					timeout_ms = 500,
					lsp_format = "fallback",
				}
			end
		end,
		formatters_by_ft = {
			lua = { "stylua" },
			python = { "isort", "black" },
			javascript = { "eslint_d", "prettierd", "prettier", stop_after_first = true },
			typescript = { "eslint_d", "prettierd", "prettier", stop_after_first = true },
			javascriptreact = { "eslint_d", "prettierd", "prettier", stop_after_first = true },
			typescriptreact = { "eslint_d", "prettierd", "prettier", stop_after_first = true },
			css = { "prettier" },
			html = { "prettier" },
			json = { "jq" },
			yaml = { "prettier" },
			markdown = { "prettier" },
			graphql = { "prettier" },
			go = { "goimports", "gofmt" },
			ruby = { "rubocop" },
			sh = { "shfmt" },
			bash = { "shfmt" },
			zsh = { "shfmt" },
			terraform = { "terraform_fmt" },
			tf = { "terraform_fmt" },
			hcl = { "terraform_fmt" },
		},
	},
	init = function()
		-- Let prose buffers use Neovim's built-in formatter so textwidth and
		-- formatoptions can insert physical line breaks while typing.
		vim.api.nvim_create_autocmd("FileType", {
			group = vim.api.nvim_create_augroup("ConformProseFormatting", { clear = true }),
			pattern = { "gitcommit", "markdown", "text" },
			callback = function(event)
				vim.bo[event.buf].formatexpr = ""
			end,
		})

		vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
	end,
}
