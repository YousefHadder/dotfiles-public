return {
	"lewis6991/gitsigns.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local gitsigns = require("gitsigns")
		local gitsigns_base = vim.env.GITSIGNS_BASE
		local applied_env_base = false

		if gitsigns_base == "" then
			gitsigns_base = nil
		end

		gitsigns.setup({
			base = gitsigns_base,
			signs = {
				add = { text = "+" },
				change = { text = "~" },
				delete = { text = "_" },
				topdelete = { text = "‾" },
				changedelete = { text = "~" },
			},
			on_attach = function(bufnr)
				local function map(lhs, rhs, desc)
					vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
				end

				if gitsigns_base and not applied_env_base then
					applied_env_base = true
					vim.defer_fn(function()
						gitsigns.change_base(gitsigns_base, true, function(err)
							if err then
								vim.notify(
									string.format("gitsigns: failed to change base to %s: %s", gitsigns_base, err),
									vim.log.levels.WARN
								)
							end
						end)
					end, 50)
				end

				map("]c", function()
					if vim.wo.diff then
						vim.cmd.normal({ "]c", bang = true })
					else
						gitsigns.nav_hunk("next")
					end
				end, "Next hunk")

				map("[c", function()
					if vim.wo.diff then
						vim.cmd.normal({ "[c", bang = true })
					else
						gitsigns.nav_hunk("prev")
					end
				end, "Previous hunk")
			end,
		})
	end,
}
