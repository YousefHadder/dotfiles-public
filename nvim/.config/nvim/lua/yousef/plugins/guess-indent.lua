return {
	"nmac427/guess-indent.nvim",
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		auto_cmd = true, -- Automatically run on BufRead and BufNewFile
		buftype_exclude = { "terminal", "nofile" },
	},
}
