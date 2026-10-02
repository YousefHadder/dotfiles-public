vim.filetype.add({
	extension = {
		gs = "javascript",
		tf = "terraform",
		tfvars = "terraform",
		hcl = "hcl",
	},
	filename = {
		["test"] = "ruby",
	},
	-- Large file handling is done by snacks.nvim's bigfile module
})
