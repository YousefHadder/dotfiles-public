local keymap = vim.keymap.set

-- ======================================================
-- Essential Mappings
-- ======================================================

-- Disable the spacebar key's default behavior in Normal and Visual modes
keymap({ "n", "v" }, "<Space>", "<Nop>", { silent = true })

-- Use jk instead of Esc
keymap("i", "jk", "<ESC>")

-- Clear search highlighting
keymap("n", "<Esc>", "<cmd>nohlsearch<CR>")

-- ======================================================
-- Movement and Navigation
-- ======================================================

-- Better up/down movement
keymap({ "n", "x" }, "j", "v:count == 0 ? 'gj' : 'j'", { expr = true, silent = true })
keymap({ "n", "x" }, "k", "v:count == 0 ? 'gk' : 'k'", { expr = true, silent = true })

-- Keep cursor centered when scrolling
keymap("n", "<C-d>", "<C-d>zz")
keymap("n", "<C-u>", "<C-u>zz")

-- Keep cursor centered when searching
keymap("n", "n", "nzzzv")
keymap("n", "N", "Nzzzv")

-- ======================================================
-- Text Manipulation
-- ======================================================

-- Better indenting
keymap("v", "<", "<gv")
keymap("v", ">", ">gv")

-- Move text up and down (normal mode must use the current line, not the
-- last visual marks, which go stale)
keymap("n", "<a-k>", "<cmd>m .-2<CR>==", { silent = true })
keymap("n", "<a-j>", "<cmd>m .+1<CR>==", { silent = true })
keymap("v", "<a-k>", ":m '<-2<CR>gv=gv", { silent = true })
keymap("v", "<a-j>", ":m '>+1<CR>gv=gv", { silent = true })

-- Better paste (doesn't replace clipboard)
keymap("x", "<leader>p", [["_dP]])
keymap("v", "p", '"_dp', { noremap = true, silent = true })

-- Delete single character without copying into register
keymap("n", "x", '"_x', { noremap = true, silent = true })

-- Select All
keymap("n", "vag", "<cmd>keepjumps normal! ggVG<cr>")

-- ======================================================
-- File Operations
-- ======================================================

-- Reload configuration
keymap("n", "<leader>rf", "<cmd>so %<CR>", { silent = true })

-- Quick save and quit
keymap("n", "<leader>wa", "<cmd>wa<CR>", { desc = "Save file" })
keymap("n", "<leader>q", "<cmd>quit<CR>", { desc = "Quit" })
keymap("n", "<leader>Q", "<cmd>qall<CR>", { desc = "Quit all" })
keymap("n", "<leader>rn", function()
	vim.cmd("wa")
	local session = vim.fn.stdpath("state") .. "/restart_session.vim"
	vim.cmd("mksession! " .. vim.fn.fnameescape(session))
	vim.cmd("restart source " .. vim.fn.fnameescape(session))
end, { desc = "Save and restart Neovim (restore session)" })

-- ======================================================
-- Window Management
-- ======================================================

-- Window navigation: <C-h/j/k/l> is owned by smart-splits.nvim (handles both
-- Neovim splits and herdr/tmux panes, crossing between them at split edges)

-- Window resizing
keymap("n", "<Up>", ":resize +2<CR>", { noremap = true, silent = true })
keymap("n", "<Down>", ":resize -2<CR>", { noremap = true, silent = true })
keymap("n", "<Left>", ":vertical resize +2<CR>", { noremap = true, silent = true })
keymap("n", "<Right>", ":vertical resize -2<CR>", { noremap = true, silent = true })

-- Split creation
keymap("n", "<leader>|", "<cmd>vsplit<CR>", { noremap = true, silent = true, desc = "Vertical split" })
keymap("n", "<leader>-", "<cmd>split<CR>", { noremap = true, silent = true, desc = "Horizontal split" })

-- ======================================================
-- Buffer and Tab Management
-- ======================================================

-- Buffer navigation
-- (<leader>bd is handled by Snacks.bufdelete — preserves window layout)
keymap("n", "<Tab>", ":BufferLineCycleNext<CR>", { silent = true })
keymap("n", "<S-Tab>", ":BufferLineCyclePrev<CR>", { silent = true })
keymap("n", "<leader>bn", "<cmd>enew<CR>", { noremap = true, silent = true, desc = "New buffer" })

-- Tab navigation: builtin gt/gT ([t/]t belongs to neotest failed-test jumps)
keymap("n", "<leader>ot", "<cmd>tabnew<CR>", { desc = "New tab" })
keymap("n", "<leader>ct", "<cmd>tabclose<CR>", { desc = "Close tab" })

-- ======================================================
-- Terminal
-- ======================================================

keymap("n", "<leader>tt", "<cmd>terminal<CR>", { desc = "Open terminal" })
keymap("n", "<leader>tv", "<cmd>vsplit | terminal<CR>", { desc = "Open terminal in vertical split" })
keymap("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Exit terminal mode" })

-- ======================================================
-- Utility Functions
-- ======================================================

-- Open Lazy/Mason windows
keymap("n", "<leader>lm", "<cmd>Lazy<CR>", { desc = "Open Lazy" })
keymap("n", "<leader>mm", "<cmd>Mason<CR>", { desc = "Open Mason" })

-- Global find and replace
keymap(
	"n",
	"<leader>rw",
	[[:%s/\<<C-r><C-w>\>/<C-r><C-w>/gI<Left><Left><Left>]],
	{ desc = "Replace word cursor is on globally" }
)

-- Copy file path to clipboard
keymap("n", "<leader>cp", function()
	local filePath = vim.fn.expand("%:~")
	vim.fn.setreg("+", filePath)
	print("File path copied to clipboard: " .. filePath)
end, { desc = "Copy file path to clipboard" })

-- Copy file:line to clipboard (relative path)
keymap("n", "<leader>ly", function()
	local path = vim.fn.expand("%:.") -- relative path from cwd
	local line = vim.fn.line(".")
	local result = string.format("%s:%d", path, line)
	vim.fn.setreg("+", result)
	vim.notify("Copied: " .. result)
end, { desc = "Copy file:line to clipboard" })

-- Copy file:line to clipboard (absolute path)
keymap("n", "<leader>lY", function()
	local path = vim.fn.expand("%:p") -- absolute path
	local line = vim.fn.line(".")
	local result = string.format("%s:%d", path, line)
	vim.fn.setreg("+", result)
	vim.notify("Copied: " .. result)
end, { desc = "Copy absolute file:line to clipboard" })

-- Copy diagnostics of current line to clipboard
keymap("n", "<leader>cd", function()
	local diagnostics = vim.diagnostic.get(0, { lnum = vim.fn.line(".") - 1 })
	if #diagnostics == 0 then
		vim.notify("No diagnostics on current line", vim.log.levels.INFO)
		return
	end

	vim.notify(string.format("Found %d diagnostic(s) on current line", #diagnostics), vim.log.levels.INFO)

	local messages = {}
	for _, diagnostic in ipairs(diagnostics) do
		local severity = vim.diagnostic.severity[diagnostic.severity]
		local source = diagnostic.source or "LSP"
		local code = diagnostic.code and ("(" .. diagnostic.code .. ")") or ""
		table.insert(messages, string.format("[%s] %s %s: %s", severity, source, code, diagnostic.message))
	end

	local text = table.concat(messages, "\n")
	vim.fn.setreg("+", text)
	vim.notify(string.format("Copied %d diagnostic(s) to clipboard", #diagnostics), vim.log.levels.INFO)
end, { desc = "Copy current line diagnostics to clipboard" })

-- Run the current line as an Ex command.
-- Handles two shapes commonly found in markdown docs:
--   1. Bare line:           `:lua require('foo').bar()`
--   2. Markdown bullet:     `- \`:lua require('foo').bar()\` → expected output`
-- Strategy: prefer the first :cmd wrapped in backticks if present; otherwise
-- treat the whole line as the command. Leading whitespace and ':' are stripped.
keymap("n", "<leader>xl", function()
	local line = vim.api.nvim_get_current_line()
	local cmd = line:match("`(:[^`]+)`")
	if cmd then
		cmd = cmd:gsub("^:", "")
	else
		cmd = line:gsub("^%s+", ""):gsub("^:", ""):gsub("%s+$", "")
	end
	if cmd == "" then
		vim.notify("No command on current line", vim.log.levels.WARN)
		return
	end
	local ok, err = pcall(vim.cmd, cmd)
	if not ok then
		vim.notify("Command failed: " .. tostring(err), vim.log.levels.ERROR)
	end
end, { desc = "Run line as Lua/Ex command" })

-- Run the current line as a shell command.
-- Handles bare commands and markdown lines with a shell command wrapped in backticks.
keymap("n", "<leader>xs", function()
	local line = vim.api.nvim_get_current_line()
	local cmd = line:match("`([^`]+)`") or line
	cmd = cmd:gsub("^%s+", ""):gsub("%s+$", "")
	if cmd == "" then
		vim.notify("No shell command on current line", vim.log.levels.WARN)
		return
	end

	local output = vim.fn.system(cmd)
	if vim.v.shell_error ~= 0 then
		vim.notify("Shell command failed: " .. output, vim.log.levels.ERROR)
		return
	end

	vim.notify(output ~= "" and output or "Shell command executed", vim.log.levels.INFO)
end, { desc = "Run line as shell command" })

-- Open all files that are changed (staged/unstaged) or untracked
-- Put this in your keymaps.lua (or wherever you configure mappings)
keymap("n", "<leader>go", function()
	local shellescape = vim.fn.shellescape
	local join = vim.fs.joinpath

	-- Find repo root
	local root = (vim.fn.systemlist("git rev-parse --show-toplevel")[1] or ""):gsub("%s+$", "")
	if root == "" then
		vim.notify("Not a git repository", vim.log.levels.WARN)
		return
	end
	local gitC = "git -C " .. shellescape(root) .. " "

	local function systemlist(cmd)
		local out = vim.fn.systemlist(cmd)
		if vim.v.shell_error ~= 0 then
			return {}
		end
		return out
	end

	-- Collect relative paths (from repo root)
	local changed_unstaged = systemlist(gitC .. "diff --name-only")
	local changed_staged = systemlist(gitC .. "diff --name-only --cached")
	local untracked = systemlist(gitC .. "ls-files --others --exclude-standard")
	local status_lines = systemlist(gitC .. "status --porcelain=v1 -unormal")

	-- Build a set of deleted paths to skip
	local deleted = {}
	for _, line in ipairs(status_lines) do
		local x = line:sub(1, 1)
		local y = line:sub(2, 2)
		local payload = vim.trim(line:sub(4))
		if x == "D" or y == "D" then
			if payload:find(" -> ") then
				local oldp, newp = payload:match("^(.-)%s+->%s+(.-)$")
				if oldp then
					deleted[oldp] = true
				end
				if newp then
					deleted[newp] = true
				end
			else
				deleted[payload] = true
			end
		end
	end

	-- Merge + dedupe
	local rel_set = {}
	local function add(list)
		for _, p in ipairs(list) do
			p = vim.trim(p)
			if p ~= "" and not deleted[p] then
				rel_set[p] = true
			end
		end
	end
	add(changed_unstaged)
	add(changed_staged)
	add(untracked)

	-- To array of absolute paths
	local files = {}
	for rel, _ in pairs(rel_set) do
		table.insert(files, join(root, rel))
	end
	table.sort(files)

	if #files == 0 then
		vim.notify("No changed or untracked files to open.", vim.log.levels.INFO)
		return
	end

	-- Add all to buffer list (no jumping), then open the first
	for _, abs in ipairs(files) do
		vim.cmd.badd(vim.fn.fnameescape(abs))
	end
	vim.cmd.edit(vim.fn.fnameescape(files[1]))

	vim.notify(("Opened %d file(s) from %s"):format(#files, root), vim.log.levels.INFO)
end, { desc = "Open all changed/staged/untracked files (repo-root aware)" })

-- Toggle boolean values and common operators
vim.keymap.set("n", "<A-t>", function()
	local word = vim.fn.expand("<cword>")

	-- Bidirectional toggle pairs
	local toggles = {
		["true"] = "false",
		["false"] = "true",
		["True"] = "False",
		["False"] = "True",
		["TRUE"] = "FALSE",
		["FALSE"] = "TRUE",
		["yes"] = "no",
		["no"] = "yes",
		["Yes"] = "No",
		["No"] = "Yes",
		["YES"] = "NO",
		["NO"] = "YES",
		["on"] = "off",
		["off"] = "on",
		["On"] = "Off",
		["Off"] = "On",
		["ON"] = "OFF",
		["OFF"] = "ON",
	}

	if toggles[word] then
		vim.cmd("normal! ciw" .. toggles[word])
		return
	end
end, { desc = "Toggle boolean/operator" })

-- Mark next Result as PASS
vim.keymap.set("n", "<leader>mtp", function()
	local line = vim.fn.search([[^\*\*Result\*\*:]], "W")
	if line == 0 then
		return
	end
	local text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1]
	text = text:gsub("%[ %] PASS", "[x] PASS")
	vim.api.nvim_buf_set_lines(0, line - 1, line, false, { text })
end, { desc = "Mark next Result PASS" })

-- Mark next Result as FAIL
vim.keymap.set("n", "<leader>mtf", function()
	local line = vim.fn.search([[^\*\*Result\*\*:]], "W")
	if line == 0 then
		return
	end
	local text = vim.api.nvim_buf_get_lines(0, line - 1, line, false)[1]
	text = text:gsub("%[ %] FAIL", "[x] FAIL")
	vim.api.nvim_buf_set_lines(0, line - 1, line, false, { text })
end, { desc = "Mark next Result FAIL" })

-- ======================================================
-- LSP Cleanup
-- ======================================================

-- Remove Neovim default LSP mappings (overridden by fzf-lua bindings)
local function clean_lsp_mappings()
	pcall(vim.keymap.del, "n", "grn") -- Rename
	pcall(vim.keymap.del, "n", "gra") -- Code action
	pcall(vim.keymap.del, "n", "grr") -- References
	pcall(vim.keymap.del, "n", "gri") -- Implementation
	pcall(vim.keymap.del, "i", "<C-S>") -- Signature help
end

clean_lsp_mappings()
