-- lua/yousef/config/autocmds.lua

local autocmd = vim.api.nvim_create_autocmd
local augroup = vim.api.nvim_create_augroup

-- Create autocommand groups
local general_group = augroup("GeneralSettings", { clear = true })
local highlight_group = augroup("HighlightYank", { clear = true })
local terminal_group = augroup("TerminalSettings", { clear = true })
local git_group = augroup("GitSettings", { clear = true })
local cursor_group = augroup("CursorSettings", { clear = true })
local ft_detect_group = augroup("FiletypeDetection", { clear = true })
local matchparen_group = augroup("MatchParenSettings", { clear = true })
local persistence_group = augroup("PersistenceSettings", { clear = true })
local help_group = augroup("HelpWindows", { clear = true })

-- ======================================================
-- General Quality of Life
-- ======================================================

-- Remove trailing whitespace on save (skip non-modifiable buffers)
autocmd("BufWritePre", {
	group = general_group,
	pattern = "*",
	callback = function()
		if not vim.bo.modifiable then
			return
		end
		local save_cursor = vim.fn.getpos(".")
		vim.cmd([[%s/\s\+$//e]])
		vim.fn.setpos(".", save_cursor)
	end,
})

-- Auto-reload files when changed externally
autocmd({ "FocusGained", "BufEnter", "CursorHold", "CursorHoldI" }, {
	group = general_group,
	pattern = "*",
	command = "if mode() != 'c' | checktime | endif",
})

-- Auto create directories before save
autocmd("BufWritePre", {
	group = general_group,
	callback = function(event)
		local file = vim.fn.fnamemodify(event.match, ":p")
		local dir = vim.fn.fnamemodify(file, ":p:h")
		if vim.fn.isdirectory(dir) == 0 then
			vim.fn.mkdir(dir, "p")
		end
	end,
})

-- ======================================================
-- Highlighting and Visual Enhancements
-- ======================================================

-- Highlight yanked text
autocmd("TextYankPost", {
	group = highlight_group,
	pattern = "*",
	callback = function()
		vim.hl.on_yank({ higroup = "IncSearch", timeout = 300 })
	end,
})

-- Automatically enable spellchecking in specific file types
autocmd("FileType", {
	group = general_group,
	pattern = { "markdown", "text", "gitcommit", "tex" },
	callback = function()
		vim.opt_local.spell = true
		vim.opt_local.spelllang = "en_us"
	end,
})

-- Disable line numbers in terminal
autocmd("TermOpen", {
	group = terminal_group,
	callback = function()
		vim.opt_local.number = false
		vim.opt_local.relativenumber = false
		vim.cmd("startinsert")
	end,
})

-- Auto-resize splits on window resize
autocmd("VimResized", {
	group = general_group,
	callback = function()
		vim.cmd("wincmd =")
	end,
})

-- ======================================================
-- Cursor Position and Movement
-- ======================================================

-- Restore cursor position (consolidated, excludes commit buffers)
autocmd("BufReadPost", {
	group = cursor_group,
	callback = function()
		-- Skip for commit messages and other special buffers
		local dominated_fts = { "gitcommit", "gitrebase", "commit" }
		if vim.tbl_contains(dominated_fts, vim.bo.filetype) then
			return
		end

		local mark = vim.api.nvim_buf_get_mark(0, '"')
		local lcount = vim.api.nvim_buf_line_count(0)
		if mark[1] > 0 and mark[1] <= lcount then
			pcall(vim.api.nvim_win_set_cursor, 0, mark)
		end
	end,
})

-- Highlight current line only in active window
autocmd({ "BufEnter", "WinEnter" }, {
	group = cursor_group,
	callback = function()
		vim.opt_local.cursorline = true
	end,
})
autocmd("WinLeave", {
	group = cursor_group,
	callback = function()
		vim.opt_local.cursorline = false
	end,
})

-- ======================================================
-- Language-Specific Settings
-- ======================================================

-- Fix jsx file type detection
autocmd({ "BufNewFile", "BufRead" }, {
	group = ft_detect_group,
	pattern = "*.jsx",
	command = "set filetype=javascriptreact",
})

-- Fix tsx file type detection
autocmd({ "BufNewFile", "BufRead" }, {
	group = ft_detect_group,
	pattern = "*.tsx",
	command = "set filetype=typescriptreact",
})

-- Add .env file detection
autocmd({ "BufNewFile", "BufRead" }, {
	group = ft_detect_group,
	pattern = { ".env*", "*.env" },
	command = "set filetype=sh",
})

-- Ruby file detection for non-standard cases
autocmd({ "BufNewFile", "BufRead" }, {
	group = ft_detect_group,
	pattern = "*",
	callback = function()
		local filename = vim.fn.expand("%:t")
		local first_line = vim.fn.getline(1)

		-- Non-standard shebang patterns (malformed or rails-specific)
		if first_line:match("^#!bin/rails") or first_line:match("^#!/bin/rails runner") then
			vim.bo.filetype = "ruby"
			return
		end
	end,
})

-- ======================================================
-- Git Integration
-- ======================================================

-- outomatically open quickfix window when running git grep
autocmd("QuickFixCmdPost", {
	group = git_group,
	pattern = "*grep*",
	command = "cwindow",
})

-- Set 72 character line limit in git commit messages
autocmd("FileType", {
	group = git_group,
	pattern = "gitcommit",
	callback = function()
		vim.opt_local.textwidth = 72
		vim.opt_local.colorcolumn = "72"
	end,
})

-- ======================================================
-- Terminal Improvements
-- ======================================================

-- Auto-enter insert mode when switching to a terminal
autocmd({ "WinEnter", "BufWinEnter", "TermOpen" }, {
	group = terminal_group,
	pattern = "term://*",
	callback = function()
		vim.cmd("startinsert")
	end,
})

-- ======================================================
-- Project Specific
-- ======================================================

-- Project-local config is now handled natively via opt.exrc = true in options.lua

-- Large file handling is done by snacks.nvim's bigfile module

-- ======================================================
-- MatchParen Settings
-- ======================================================

-- Disable MatchParen highlighting in insert mode
autocmd("InsertEnter", {
	group = matchparen_group,
	callback = function()
		vim.api.nvim_set_hl(0, "MatchParen", {})
	end,
})

autocmd("InsertLeave", {
	group = matchparen_group,
	callback = function()
		vim.api.nvim_set_hl(0, "MatchParen", { fg = "#000000", bg = "#ffd700" })
	end,
})

-- Hide diagnostic virtual text when virtual lines are enabled
local og_virt_text
local og_virt_line
autocmd({ "CursorMoved", "DiagnosticChanged" }, {
	group = augroup("DiagnosticVirtualLines", { clear = true }),
	callback = function()
		if og_virt_line == nil then
			og_virt_line = vim.diagnostic.config().virtual_lines
		end

		-- ignore if virtual_lines.current_line is disabled
		if not (og_virt_line and og_virt_line.current_line) then
			if og_virt_text then
				vim.diagnostic.config({ virtual_text = og_virt_text })
				og_virt_text = nil
			end
			return
		end

		if og_virt_text == nil then
			og_virt_text = vim.diagnostic.config().virtual_text
		end

		local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1

		if vim.tbl_isempty(vim.diagnostic.get(0, { lnum = lnum })) then
			vim.diagnostic.config({ virtual_text = og_virt_text })
		else
			vim.diagnostic.config({ virtual_text = false })
		end
	end,
})

autocmd("User", {
	group = persistence_group,
	pattern = "PersistenceSavePre",
	callback = function()
		for _, b in ipairs(vim.api.nvim_list_bufs()) do
			if vim.api.nvim_buf_is_loaded(b) then
				local bt = vim.bo[b].buftype
				local name = vim.api.nvim_buf_get_name(b)
				-- Keep only real file buffers: normal buftype and has a pathname
				local is_file = bt == "" and name ~= ""
				if not is_file then
					vim.cmd.bunload(b)
				end
			end
		end
	end,
})

autocmd("FileType", {
	group = help_group,
	pattern = "help",
	callback = function()
		vim.cmd("wincmd L")
	end,
})
-- ======================================================
-- Custom Comment Syntax Highlighting
-- ======================================================

-- Highlight @param, @returns, etc. in comments using match patterns
autocmd({ "BufEnter", "BufReadPost", "WinEnter" }, {
	group = augroup("CommentParamHighlighting", { clear = true }),
	callback = function()
		-- Clear any existing matches first
		pcall(vim.fn.clearmatches)
		-- Add match pattern for @tags in comments
		vim.fn.matchadd("CommentParam", [[@\w\+]], 10)
	end,
})

-- ======================================================
-- ShaDa Hygiene
-- ======================================================

-- Killed/crashed instances and concurrent writers (tmux panes, :restart) cause
-- two distinct ShaDa failures, both handled here so the file self-heals:
--
--   1. Leaked main.shada.tmp.a..z files. A live writer holds its tmp for only
--      milliseconds; once all 26 letters exist every write fails with E138, so
--      any tmp older than an hour is leaked and is removed.
--
--   2. A truncated/interleaved write that lands on main.shada itself. Nvim then
--      fails every read (E576 "expected positive integer") AND refuses to
--      overwrite a file that "does not look like a ShaDa file" (E136), so the
--      corruption is permanent until the file is removed by hand. We validate
--      the entry framing *before* Nvim reads it and quarantine a broken file to
--      main.shada.corrupt, letting the next write rebuild it automatically.
--
-- Runs inline (not on VimEnter) so scripted/headless sessions self-heal too.
do
	local shada_dir = vim.fn.stdpath("state") .. "/shada"

	for _, path in ipairs(vim.fn.glob(shada_dir .. "/*.shada.tmp.*", true, true)) do
		local stat = vim.uv.fs_stat(path)
		if stat and os.time() - stat.mtime.sec > 3600 then
			os.remove(path)
		end
	end

	-- A ShaDa file is a flat sequence of entries, each four msgpack objects:
	-- type, timestamp and length (all unsigned ints) then `length` data bytes.
	-- Sizing the three header ints and skipping the data is enough to catch the
	-- framing desync corruption produces, so a tiny positive-integer reader is
	-- all we need (no full msgpack decoder).
	local function shada_is_valid(buf)
		local function read_uint(b, i)
			local c = b:byte(i)
			if c == nil then
				return nil
			elseif c < 0x80 then -- positive fixint
				return c, i + 1
			elseif c == 0xcc then -- uint8
				local v = b:byte(i + 1)
				if not v then return nil end
				return v, i + 2
			elseif c == 0xcd then -- uint16
				local hi, lo = b:byte(i + 1, i + 2)
				if not lo then return nil end
				return hi * 0x100 + lo, i + 3
			elseif c == 0xce then -- uint32
				local b1, b2, b3, b4 = b:byte(i + 1, i + 4)
				if not b4 then return nil end
				return ((b1 * 0x100 + b2) * 0x100 + b3) * 0x100 + b4, i + 5
			elseif c == 0xcf then -- uint64
				local p = { b:byte(i + 1, i + 8) }
				if #p < 8 then return nil end
				local v = 0
				for _, byte in ipairs(p) do
					v = v * 0x100 + byte
				end
				return v, i + 9
			end
			return nil -- not a positive integer: framing is broken
		end

		local len = #buf
		local i = 1
		while i <= len do
			local _, after_type = read_uint(buf, i)
			if not after_type then return false end
			local _, after_ts = read_uint(buf, after_type)
			if not after_ts then return false end
			local data_len, after_len = read_uint(buf, after_ts)
			if not after_len then return false end
			i = after_len + data_len
			if i > len + 1 then return false end -- entry data runs past EOF
		end
		return true
	end

	local main = shada_dir .. "/main.shada"
	local fd = io.open(main, "rb")
	if fd then
		local buf = fd:read("*a")
		fd:close()
		if #buf > 0 and not shada_is_valid(buf) then
			os.rename(main, main .. ".corrupt")
			vim.schedule(function()
				vim.notify(
					"ShaDa: removed corrupt main.shada (backup: main.shada.corrupt)",
					vim.log.levels.WARN
				)
			end)
		end
	end
end

-- Return the module
return {}
