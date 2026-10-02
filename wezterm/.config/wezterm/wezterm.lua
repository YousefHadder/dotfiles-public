-- =============================================================================
-- WezTerm configuration
-- Mirrors ~/.config/ghostty/config (appearance) and ~/.tmux.conf (multiplexing)
-- =============================================================================

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- Catppuccin Mocha palette (matches your tmux @catppuccin_flavor 'mocha').
-- NB: this themes WezTerm's *chrome* (tab bar, status, pane borders) only.
-- Terminal *content* colors stay Slate, exactly like your Ghostty + tmux split.
local ctp = {
	rosewater = "#f5e0dc",
	flamingo = "#f2cdcd",
	pink = "#f5c2e7",
	mauve = "#cba6f7",
	red = "#f38ba8",
	maroon = "#eba0ac",
	peach = "#fab387",
	yellow = "#f9e2af",
	green = "#a6e3a1",
	teal = "#94e2d5",
	sky = "#89dceb",
	sapphire = "#74c7ec",
	blue = "#89b4fa",
	lavender = "#b4befe",
	text = "#cdd6f4",
	subtext1 = "#bac2de",
	subtext0 = "#a6adc8",
	overlay2 = "#9399b2",
	overlay1 = "#7f849c",
	overlay0 = "#6c7086",
	surface2 = "#585b70",
	surface1 = "#45475a",
	surface0 = "#313244",
	base = "#1e1e2e",
	mantle = "#181825",
	crust = "#11111b",
}

-- -----------------------------------------------------------------------------
-- Multiplexing mode: how WezTerm relates to tmux. Flip this one line to switch.
--
--   'replace'    -> WezTerm replaces tmux. Your tmux keybinds are ported to
--                   WezTerm's native multiplexing (C-b leader, splits, tab
--                   navigation, vim-aware pane navigation). Do NOT run tmux
--                   inside: C-b is captured by WezTerm.
--
--   'complement' -> Keep running tmux inside WezTerm. WezTerm only matches
--                   Ghostty's appearance and leaves C-b untouched so it reaches
--                   tmux. WezTerm's own tab bar is hidden so tmux's status bar
--                   is the only one on screen.
-- -----------------------------------------------------------------------------
local MULTIPLEXING_MODE = "replace"

-- =============================================================================
-- APPEARANCE  (shared by both modes -- mirrors ~/.config/ghostty/config)
-- =============================================================================

-- Slate color scheme (matches ghostty background/foreground/palette) -----------
config.colors = {
	foreground = "#ffffff",
	background = "#262626",

	-- cursor-invert-fg-bg = true: cursor takes the foreground color and the glyph
	-- beneath it takes the background color.
	cursor_bg = "#ffffff",
	cursor_fg = "#262626",
	cursor_border = "#ffffff",

	ansi = {
		"#000000", -- 0  black
		"#cd0000", -- 1  red
		"#00cd00", -- 2  green
		"#cdcd00", -- 3  yellow
		"#0087ff", -- 4  blue
		"#cd00cd", -- 5  magenta
		"#00cdcd", -- 6  cyan
		"#e5e5e5", -- 7  white
	},
	brights = {
		"#7f7f7f", -- 8  bright black
		"#ff0000", -- 9  bright red
		"#00ff00", -- 10 bright green
		"#ffff00", -- 11 bright yellow
		"#87d7ff", -- 12 bright blue
		"#ff00ff", -- 13 bright magenta
		"#00ffff", -- 14 bright cyan
		"#ffffff", -- 15 bright white
	},
}

-- Catppuccin-mocha chrome (tab bar + pane borders). Content colors stay Slate.
config.colors.tab_bar = {
	background = ctp.crust,
	active_tab = { bg_color = ctp.mauve, fg_color = ctp.crust },
	inactive_tab = { bg_color = ctp.surface0, fg_color = ctp.subtext0 },
	inactive_tab_hover = { bg_color = ctp.surface1, fg_color = ctp.text },
	new_tab = { bg_color = ctp.crust, fg_color = ctp.surface2 },
	new_tab_hover = { bg_color = ctp.surface0, fg_color = ctp.text },
}
config.colors.split = ctp.surface2
-- Dim inactive panes so the focused one stands out (tmux-like focus).
config.inactive_pane_hsb = { saturation = 0.8, brightness = 0.7 }

-- Background image (ghostty: black.jpg, cover, 0.15 opacity) --------------------
-- Layer 0 is the solid slate background; layer 1 is the image faded to 15%.
config.background = {
	{
		source = { Color = "#262626" },
		width = "100%",
		height = "100%",
	},
}

-- Font (ghostty wanted "Hack Nerd Font Mono"; using installed JetBrainsMono) ----
config.font = wezterm.font_with_fallback({
	"JetBrainsMono Nerd Font",
	"FiraCode Nerd Font",
	"Hack Nerd Font Mono",
})
config.font_size = 15.0

-- Cursor (ghostty: underline, no blink) ----------------------------------------
config.default_cursor_style = "SteadyUnderline"
config.cursor_blink_rate = 0

-- Window (ghostty: window-decoration = none, mouse-hide-while-typing) -----------
config.window_decorations = "RESIZE"
config.hide_mouse_cursor_when_typing = true
config.window_padding = { left = 4, right = 4, top = 4, bottom = 2 }
config.window_close_confirmation = "NeverPrompt"

-- macOS: treat Option as Alt (ghostty: macos-option-as-alt = true) --------------
config.send_composed_key_when_left_alt_is_pressed = false
config.send_composed_key_when_right_alt_is_pressed = false

-- Kitty keyboard protocol: lets WezTerm send DISTINCT encodings for Ctrl+h/j/k/m
-- instead of the legacy control bytes (Ctrl+h=Backspace, Ctrl+j=Enter, ...).
-- Without this, handing Ctrl+h/j/k to Neovim collapses them into BS/CR, so only
-- Ctrl+l navigates. Neovim 0.10+ opts in automatically; other apps are
-- unaffected unless they request it.
config.enable_kitty_keyboard = true

-- Terminal type (ghostty: term = xterm-256color). COLORTERM=truecolor is still
-- set by WezTerm so 24-bit color works. Switch to 'wezterm' after installing its
-- terminfo if you want undercurl etc.
config.term = "xterm-256color"

config.audible_bell = "Disabled"
config.scrollback_lines = 50000

-- Optional tmux-like persistence (detach / reattach). Uncomment to route the GUI
-- through a headless mux server so panes survive quitting the WezTerm window --
-- the closest native analog to tmux-resurrect/continuum (does NOT survive a
-- reboot). LEADER d then detaches; relaunch or `wezterm connect unix` to return.
-- config.unix_domains = { { name = 'unix' } }
-- config.default_gui_startup_args = { 'connect', 'unix' }

-- Tab bar at the top, 1-based indices (tmux: status-position top, base-index 1) -
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = false
config.tab_and_split_indices_are_zero_based = false
config.hide_tab_bar_if_only_one_tab = false
config.tab_max_width = 32

-- =============================================================================
-- TABLINE + STATUS BAR
-- Ports your catppuccin-mocha tmux status bar (session on the left; battery and
-- date/time on the right) and joshmedeski/tmux-nerd-font-window-name (per-tab
-- process icons). Only visible in 'replace' mode (WezTerm draws the tab bar).
-- =============================================================================

-- Rounded powerline separators U+E0B6 / U+E0B4, built via utf8.char because raw
-- PUA glyphs (U+E000-F8FF) are stripped when this file is written to disk.
local SEP_LEFT = utf8.char(0xE0B6)
local SEP_RIGHT = utf8.char(0xE0B4)

-- Tabs render at a fixed width so the centered layout is deterministic.
local column_width = wezterm.column_width
local SEP_W = column_width(SEP_LEFT) -- cell width of a separator (usually 1)
local TAB_INNER = 18 -- inner label width per tab
local TAB_WIDTH = SEP_W * 2 + TAB_INNER + 1 -- + both separators + trailing space

-- Nerd-font codepoint per foreground process (joshmedeski/tmux-nerd-font-window-name).
-- Stored as codepoints, not raw glyphs: PUA glyphs (U+E000-F8FF) are stripped on write.
local process_icons = {
	nvim = 0xE62B,
	vim = 0xE62B,
	vi = 0xE62B,
	node = 0xE718,
	npm = 0xE71E,
	pnpm = 0xE718,
	yarn = 0xE718,
	python = 0xE606,
	python3 = 0xE606,
	ipython = 0xE606,
	ruby = 0xE739,
	cargo = 0xE7A8,
	rustc = 0xE7A8,
	go = 0xE627,
	lua = 0xE620,
	git = 0xE702,
	lazygit = 0xE702,
	docker = 0xF308,
	kubectl = 0xF10FE,
	ssh = 0xF08C0,
	tmux = 0xF120,
	bash = 0xF120,
	zsh = 0xF120,
	fish = 0xF120,
	sh = 0xF120,
	htop = 0xF0E4,
	btop = 0xF0E4,
	top = 0xF0E4,
	fzf = 0xF002,
	man = 0xF02D,
	make = 0xF0AD,
}
local DEFAULT_ICON = 0xF120 -- nf-fa-terminal

local function basename(p)
	return (p or ""):gsub("%.exe$", ""):gsub(".*[/\\]", "")
end

local function proc_icon(pane)
	local cp = process_icons[basename(pane and pane.foreground_process_name)] or DEFAULT_ICON
	return utf8.char(cp)
end

-- Helper: push a colored segment onto a wezterm.format list
local function seg(items, bg, fg, t)
	table.insert(items, { Background = { Color = bg } })
	table.insert(items, { Foreground = { Color = fg } })
	table.insert(items, { Text = t })
end

-- System stats for the right status (cpu/mem/ip/prayer). The helper script is
-- run on a 10s throttle and cached in wezterm.GLOBAL so the slow `top`-free
-- sampling never blocks the UI thread on every ~1s status tick.
local SYS_SCRIPT = wezterm.config_dir .. "/bin/sysinfo.sh"

local function lines_of(s)
	local t = {}
	for line in ((s or "") .. "\n"):gmatch("([^\n]*)\n") do
		t[#t + 1] = line
	end
	return t
end

local function refresh_sysinfo()
	local g = wezterm.GLOBAL
	local now = os.time()
	if g.sys_at and (now - g.sys_at) < 10 then
		return
	end
	g.sys_at = now
	local ok, stdout = wezterm.run_child_process({ "bash", SYS_SCRIPT })
	if not ok then
		return
	end
	local l = lines_of(stdout)
	g.cpu, g.mem, g.ip, g.prayer, g.prayer_color = l[1], l[2], l[3], l[4], l[5]
end

-- green < med <= yellow < high <= red (mirrors tmux-cpu low/medium/high colors)
local function lvl_color(pct, med, high)
	local n = tonumber(pct) or 0
	if n >= high then
		return ctp.red
	elseif n >= med then
		return ctp.yellow
	end
	return ctp.green
end

-- Map the prayer calculator's urgency color into the catppuccin palette.
local function urgency_color(hex)
	local r, g = tostring(hex):match("#(%x%x)(%x%x)%x%x")
	if not r then
		return ctp.green
	end
	r, g = tonumber(r, 16), tonumber(g, 16)
	if r > 150 and g < 120 then
		return ctp.red
	elseif r > 150 then
		return ctp.yellow
	end
	return ctp.green
end

wezterm.on("format-tab-title", function(tab, tabs, panes, conf, hover, max_width)
	local i = tab.tab_index + 1
	local icon = proc_icon(tab.active_pane)
	local title = tab.tab_title
	if title == nil or #title == 0 then
		title = basename(tab.active_pane.title)
	end
	local bg = tab.is_active and ctp.mauve or ctp.surface0
	local fg = tab.is_active and ctp.crust or ctp.subtext0
	local edge = ctp.crust
	-- Fixed-width inner label, window number right-aligned within the tab
	-- (tmux @catppuccin_window_number_position 'right').
	local rightpart = string.format("%d ", i)
	local leftpart = string.format(" %s %s", icon, title)
	local avail = TAB_INNER - column_width(rightpart)
	leftpart = wezterm.pad_right(wezterm.truncate_right(leftpart, avail), avail)
	local inner = leftpart .. rightpart
	return {
		{ Background = { Color = edge } },
		{ Foreground = { Color = bg } },
		{ Text = SEP_LEFT },
		{ Background = { Color = bg } },
		{ Foreground = { Color = fg } },
		{ Text = inner },
		{ Background = { Color = edge } },
		{ Foreground = { Color = bg } },
		{ Text = SEP_RIGHT },
		{ Background = { Color = edge } },
		{ Text = " " },
	}
end)

wezterm.on("update-status", function(window, pane)
	local leader = window:leader_is_active()
	local accent = leader and ctp.peach or ctp.green
	local ws = window:active_workspace()

	-- LEFT: every session (workspace) as a pill, active one highlighted; then a
	-- spacer that centers the tab strip (tmux: status-justify absolute-centre with
	-- the session list on status-left).
	local names = wezterm.mux.get_workspace_names and wezterm.mux.get_workspace_names() or { ws }
	table.sort(names)
	local left = {}
	local left_w = 0
	for _, name in ipairs(names) do
		local is_active = (name == ws)
		local pill_bg = is_active and accent or ctp.surface0
		local pill_fg = is_active and ctp.crust or ctp.subtext0
		local text = " " .. name .. " "
		seg(left, ctp.crust, pill_bg, SEP_LEFT)
		seg(left, pill_bg, pill_fg, text)
		seg(left, ctp.crust, pill_bg, SEP_RIGHT)
		seg(left, ctp.crust, ctp.crust, " ")
		left_w = left_w + SEP_W * 2 + column_width(text) + 1
	end

	-- Spacer to push the fixed-width tab strip to the horizontal centre.
	local atab = window:active_tab()
	local size = atab and atab:get_size()
	local cols = (size and size.cols) or 80
	local num_tabs = #window:mux_window():tabs()
	local pad = math.floor((cols - num_tabs * TAB_WIDTH) / 2) - left_w
	if pad > 0 then
		seg(left, ctp.crust, ctp.crust, string.rep(" ", pad))
	end
	window:set_left_status(wezterm.format(left))

	-- RIGHT: ip · cpu · mem · battery · prayer (mirrors tmux status-right)
	refresh_sysinfo()
	local g = wezterm.GLOBAL
	local right = {}

	if g.ip and g.ip ~= "" and g.ip ~= "—" then
		seg(right, ctp.crust, ctp.teal, "  󰩟 " .. g.ip)
	end
	if g.cpu then
		seg(right, ctp.crust, lvl_color(g.cpu, 30, 80), "  󰻠 " .. g.cpu .. "%")
	end
	if g.mem then
		seg(right, ctp.crust, lvl_color(g.mem, 70, 90), "  󰍛 " .. g.mem .. "%")
	end

	-- battery (tmux-battery, @catppuccin_battery_color '#d7875f')
	local b = wezterm.battery_info()[1]
	if b then
		local pct = math.floor((b.state_of_charge or 0) * 100 + 0.5)
		local icon = "󰁹"
		if b.state == "Charging" then
			icon = "󰂄"
		elseif pct <= 10 then
			icon = "󰁺"
		elseif pct <= 30 then
			icon = "󰁼"
		elseif pct <= 60 then
			icon = "󰁾"
		elseif pct <= 90 then
			icon = "󰂀"
		end
		seg(right, ctp.crust, "#d7875f", string.format("  %s %d%%", icon, pct))
	end

	-- prayer times (your YousefHadder/muslim-prayers calculator), rightmost as in tmux
	if g.prayer and g.prayer ~= "" then
		seg(right, ctp.crust, urgency_color(g.prayer_color), "  🕌 " .. g.prayer .. " ")
	end

	window:set_right_status(wezterm.format(right))
end)

-- =============================================================================
-- KEYBINDINGS
-- =============================================================================

-- vim-aware split navigation. smart-splits.nvim sets the IS_NVIM user var while
-- Neovim is focused, so we check that first (fast + reliable). Process-name
-- sniffing remains as a guarded fallback for plain vim without the plugin.
local VIM_PROCESSES = {
	nvim = true,
	vim = true,
	vi = true,
	view = true,
	vimdiff = true,
	nview = true,
}

local function is_vim(pane)
	-- Primary signal: set by smart-splits.nvim (unset on Neovim exit).
	local ok, vars = pcall(function()
		return pane:get_user_vars()
	end)
	if ok and type(vars) == "table" and vars.IS_NVIM == "true" then
		return true
	end
	-- Fallback: foreground process name, pcall-guarded so a failed lookup never
	-- swallows the keypress (we then default to moving WezTerm panes).
	local ok2, name = pcall(function()
		return pane:get_foreground_process_name()
	end)
	if ok2 and name and name ~= "" then
		name = name:gsub("%.exe$", ""):gsub(".*[/\\]", "")
		if VIM_PROCESSES[name] then
			return true
		end
	end
	return false
end

local nav_dirs = { h = "Left", j = "Down", k = "Up", l = "Right" }

local function smart_nav(key, dir)
	return wezterm.action_callback(function(win, pane)
		-- Debug: record what we detect so navigation issues can be diagnosed from
		-- the wezterm log (~/.local/share/wezterm or $WEZTERM_LOG). Remove later.
		local ok, vars = pcall(function()
			return pane:get_user_vars()
		end)
		local is_nvim_var = (ok and type(vars) == "table") and tostring(vars.IS_NVIM) or "ERR"
		local vim_detected = is_vim(pane)
		-- Pass through to nvim when it's focused, or when nvim is the only pane in
		-- the tab (its own splits fill the tab) -- matches the official plugin.
		local single_pane = (#win:active_tab():panes() == 1)
		wezterm.log_info(
			string.format(
				"smart_nav key=%s dir=%s IS_NVIM=%s is_vim=%s single_pane=%s",
				key,
				dir,
				is_nvim_var,
				tostring(vim_detected),
				tostring(single_pane)
			)
		)
		if vim_detected or single_pane then
			win:perform_action(act.SendKey({ key = key, mods = "CTRL" }), pane)
		else
			win:perform_action(act.ActivatePaneDirection(dir), pane)
		end
	end)
end

if MULTIPLEXING_MODE == "replace" then
	-- ---------------------------------------------------------------------------
	-- REPLACE: port the tmux workflow to native WezTerm multiplexing.
	-- ---------------------------------------------------------------------------
	config.enable_tab_bar = true

	-- Leader = tmux prefix (C-b). timeout_milliseconds is how long WezTerm waits
	-- for the next key after the leader before cancelling (tmux's prefix waits
	-- indefinitely; 3000ms here is a comfortable middle ground -- raise/lower it).
	config.leader = { key = "b", mods = "CTRL", timeout_milliseconds = 3000 }

	config.keys = {
		-- Splits (tmux: | = split -h side-by-side, - = split -v stacked)
		{ key = "|", mods = "LEADER", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
		{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

		-- New tab == tmux new-window (c)
		{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },

		-- Tab (window) navigation (tmux: h prev-window, l next-window)
		{ key = "h", mods = "LEADER", action = act.ActivateTabRelative(-1) },
		{ key = "l", mods = "LEADER", action = act.ActivateTabRelative(1) },

		-- Move tab left/right (tmux: H/L swap-window)
		{ key = "H", mods = "LEADER", action = act.MoveTabRelative(-1) },
		{ key = "L", mods = "LEADER", action = act.MoveTabRelative(1) },

		-- Pane resize, large steps of 5 (tmux: prefix M-h/j/k/l)
		{ key = "h", mods = "LEADER|ALT", action = act.AdjustPaneSize({ "Left", 5 }) },
		{ key = "j", mods = "LEADER|ALT", action = act.AdjustPaneSize({ "Down", 5 }) },
		{ key = "k", mods = "LEADER|ALT", action = act.AdjustPaneSize({ "Up", 5 }) },
		{ key = "l", mods = "LEADER|ALT", action = act.AdjustPaneSize({ "Right", 5 }) },

		-- Pane resize, small steps of 1 (tmux: prefix C-h/j/k/l)
		{ key = "h", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "j", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "k", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = "l", mods = "LEADER|CTRL", action = act.AdjustPaneSize({ "Right", 1 }) },

		-- Reload config (tmux: prefix r)
		{ key = "r", mods = "LEADER", action = act.ReloadConfiguration },

		-- Diagnose pane navigation: toast the detected foreground process name and
		-- the is_vim verdict for the active pane. (LEADER i -> "info"). Remove once
		-- you've confirmed detection is correct.
		{
			key = "i",
			mods = "LEADER",
			action = wezterm.action_callback(function(win, pane)
				local ok, name = pcall(function()
					return pane:get_foreground_process_name()
				end)
				win:toast_notification(
					"WezTerm pane-nav",
					"fg process: " .. tostring(name) .. "   |   is_vim = " .. tostring(is_vim(pane)),
					nil,
					4000
				)
			end),
		},

		-- Copy mode / paste (tmux: prefix [ and ])
		{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
		{ key = "]", mods = "LEADER", action = act.PasteFrom("Clipboard") },

		-- Zoom pane (tmux: prefix z)
		{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

		-- Rotate panes (tmux: prefix Space next-layout / C-o rotate)
		{ key = " ", mods = "LEADER", action = act.RotatePanes("Clockwise") },

		-- "Expose" / pick a pane visually (tmux: cesarferreira/tmux.expose, prefix o)
		{ key = "o", mods = "LEADER", action = act.PaneSelect({ alphabet = "asdfghjkl" }) },

		-- Repeatable resize mode (tmux: -r repeat). LEADER R, then h/j/k/l, Esc to exit.
		{
			key = "R",
			mods = "LEADER",
			action = act.ActivateKeyTable({ name = "resize_pane", one_shot = false, timeout_milliseconds = 1500 }),
		},

		-- Kill pane / tab / session (tmux: x kill-pane, & kill-window, X kill-session)
		{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
		{ key = "&", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },
		-- WezTerm has no kill-session; closing the tab empties the workspace (~session).
		{ key = "X", mods = "LEADER", action = act.CloseCurrentTab({ confirm = true }) },

		-- Detach from the mux server (tmux: prefix d). Needs a unix/ssh domain enabled.
		{ key = "d", mods = "LEADER", action = act.DetachDomain("CurrentPaneDomain") },

		-- Workspaces ~= tmux sessions ------------------------------------------------
		-- New named workspace (tmux: C new session)
		{
			key = "C",
			mods = "LEADER",
			action = act.PromptInputLine({
				description = "New workspace name:",
				action = wezterm.action_callback(function(window, pane, line)
					if line and line ~= "" then
						window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
					end
				end),
			}),
		},
		-- Next / previous workspace (session): n = next, p = previous
		{ key = "n", mods = "LEADER", action = act.SwitchWorkspaceRelative(1) },
		{ key = "p", mods = "LEADER", action = act.SwitchWorkspaceRelative(-1) },
		-- Fuzzy workspace switcher (tmux: T launcher / sessionx, prefix s choose-tree)
		{ key = "T", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
		{ key = "s", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
		-- Fuzzy tab (window) switcher (tmux: prefix w choose-window)
		{ key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|TABS" }) },

		-- Rename tab / workspace (tmux: prefix , rename-window, $ rename-session) -----
		{
			key = ",",
			mods = "LEADER",
			action = act.PromptInputLine({
				description = "Rename tab:",
				action = wezterm.action_callback(function(window, pane, line)
					if line then
						window:active_tab():set_title(line)
					end
				end),
			}),
		},
		{
			key = "$",
			mods = "LEADER",
			action = act.PromptInputLine({
				description = "Rename workspace:",
				action = wezterm.action_callback(function(window, pane, line)
					if line and line ~= "" then
						wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
					end
				end),
			}),
		},

		-- Send a literal C-b to the app when you really need it (e.g. tmux/readline)
		{ key = "b", mods = "LEADER|CTRL", action = act.SendKey({ key = "b", mods = "CTRL" }) },
	}

	-- vim-aware C-h/j/k/l pane navigation (no leader, like vim-tmux-navigator)
	for key, dir in pairs(nav_dirs) do
		table.insert(config.keys, { key = key, mods = "CTRL", action = smart_nav(key, dir) })
	end

	-- Jump to tab/window by number (tmux: prefix 1..9)
	for i = 1, 9 do
		table.insert(config.keys, { key = tostring(i), mods = "LEADER", action = act.ActivateTab(i - 1) })
	end

	-- Key table for the repeatable resize mode entered via LEADER R
	config.key_tables = {
		resize_pane = {
			{ key = "h", action = act.AdjustPaneSize({ "Left", 2 }) },
			{ key = "j", action = act.AdjustPaneSize({ "Down", 2 }) },
			{ key = "k", action = act.AdjustPaneSize({ "Up", 2 }) },
			{ key = "l", action = act.AdjustPaneSize({ "Right", 2 }) },
			{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 2 }) },
			{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 2 }) },
			{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 2 }) },
			{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 2 }) },
			{ key = "Escape", action = act.PopKeyTable },
			{ key = "Enter", action = act.PopKeyTable },
			{ key = "q", action = act.PopKeyTable },
		},
	}
else
	-- ---------------------------------------------------------------------------
	-- COMPLEMENT: tmux stays in charge of multiplexing.
	-- Match Ghostty's look, hide WezTerm's tab bar (tmux draws its own status),
	-- and DO NOT set a leader so every C-b reaches tmux untouched. WezTerm's
	-- default CMD-based shortcuts (CMD-n, CMD-t, CMD-w, ...) don't collide with
	-- tmux, so they're left enabled.
	-- ---------------------------------------------------------------------------
	config.enable_tab_bar = false
end

-- Shift+Enter sends a newline (ghostty: keybind = shift+enter=text:\n) ---------
config.keys = config.keys or {}
table.insert(config.keys, { key = "Enter", mods = "SHIFT", action = act.SendString("\n") })

-- macOS line-editing: translate Cmd/Opt combos into the control codes that line
-- editors (readline/zsh, Node readline, the Copilot CLI prompt) understand, so
-- they behave natively in the terminal.
--   Cmd+Backspace -> Ctrl+U  : delete from cursor to start of line
--   Opt+Backspace -> Ctrl+W  : delete the word before the cursor
table.insert(config.keys, { key = "Backspace", mods = "CMD", action = act.SendKey({ key = "u", mods = "CTRL" }) })
table.insert(config.keys, { key = "Backspace", mods = "OPT", action = act.SendKey({ key = "w", mods = "CTRL" }) })

-- Disable the default Alt+Enter -> ToggleFullScreen (Option+Enter on macOS).
table.insert(config.keys, { key = "Enter", mods = "ALT", action = act.DisableDefaultAssignment })

-- Mouse selection copies (tmux-yank: @yank_selection_mouse 'primary') ----------
config.mouse_bindings = {
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "NONE",
		action = act.CompleteSelection("PrimarySelection"),
	},
	-- Cmd+Click opens the link under the cursor (macOS-native).
	{
		event = { Up = { streak = 1, button = "Left" } },
		mods = "CMD",
		action = act.OpenLinkAtMouseCursor,
	},
	-- Don't send the Cmd+Down click to the running program, so a plain Cmd+Click
	-- only follows the link (and doesn't move the cursor / select).
	{
		event = { Down = { streak = 1, button = "Left" } },
		mods = "CMD",
		action = act.Nop,
	},
}

for _, layer in ipairs({ "dotfiles-work", "dotfiles-local" }) do
	local path = wezterm.home_dir .. "/.config/" .. layer .. "/wezterm.lua"
	local file, message, code = io.open(path, "r")
	if file then
		file:close()
		local configure = dofile(path)
		assert(type(configure) == "function", path .. " must return a configuration function")
		configure(config)
	elseif code ~= 2 then
		error(message)
	end
end

return config
