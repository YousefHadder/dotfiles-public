#!/usr/bin/env bash
# Fast system stats for the WezTerm right status bar.
# Emits exactly 5 lines: cpu% / mem% / ip / prayer-text / prayer-color.
# Deliberately avoids `top -l2` (~1s) so it can be called on a short throttle.
# No `set -e`: every metric degrades to a sane default rather than aborting.
set -uo pipefail

# GUI apps launched from Finder/Dock inherit a minimal PATH that omits
# /opt/homebrew/bin, so Homebrew tools (lua) wouldn't be found. Add them back.
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:$PATH"

# --- CPU: sum of per-process %cpu / core count (~30ms, decayed average) -------
ncpu=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
cpu=$(ps -A -o %cpu= 2>/dev/null | awk -v n="$ncpu" '{s += $1} END {printf "%.0f", (n > 0) ? s / n : s}')
[ -z "$cpu" ] && cpu="0"

# --- MEM: (active + wired + compressed) pages * page size / total physical ----
mem=$(vm_stat 2>/dev/null | awk -v total="$(sysctl -n hw.memsize 2>/dev/null)" '
  /page size of/                  { ps = $8 }
  /Pages active/                  { a = $3 }
  /Pages wired down/              { w = $4 }
  /Pages occupied by compressor/  { c = $5 }
  END {
    gsub(/\./, "", a); gsub(/\./, "", w); gsub(/\./, "", c)
    if (ps == "") ps = 16384
    if (total > 0) printf "%.0f", (a + w + c) * ps / total * 100; else printf "0"
  }')
[ -z "$mem" ] && mem="0"

# --- IP: address of the default-route interface -------------------------------
iface=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')
ip=$(ipconfig getifaddr "${iface:-en0}" 2>/dev/null)
[ -z "$ip" ] && ip="—"

# --- Prayer: self-contained calculator, one "cache" call = status + color -----
# Coordinates/method mirror ~/.tmux.conf (@prayer-times-* options).
prayer_lua="$HOME/.tmux/plugins/muslim-prayers/scripts/prayer_calc.lua"
lat="${PRAYER_LATITUDE:-}"; lon="${PRAYER_LONGITUDE:-}"; tzname="${PRAYER_TIMEZONE:-}"
ptext=""; pcolor=""

# Resolve a lua interpreter by absolute path first (PATH may be minimal).
lua_bin=""
for cand in /opt/homebrew/bin/lua /usr/local/bin/lua /opt/homebrew/bin/luajit /usr/local/bin/luajit lua luajit; do
  if command -v "$cand" >/dev/null 2>&1; then lua_bin="$cand"; break; fi
done

if [ -n "$lat" ] && [ -n "$lon" ] && [ -n "$tzname" ] && [ -n "$lua_bin" ] && [ -f "$prayer_lua" ]; then
  payload=$(TZ="$tzname" "$lua_bin" "$prayer_lua" "$lat" "$lon" auto ISNA standard 12H cache "$tzname" 2>/dev/null)
  ptext=$(printf '%s\n' "$payload" | sed -n '1p')
  pcolor=$(printf '%s\n' "$payload" | sed -n '2p')
fi
[ -z "$ptext" ] && ptext="Prayer: n/a"
[ -z "$pcolor" ] && pcolor="#a6e3a1"

printf '%s\n%s\n%s\n%s\n%s\n' "$cpu" "$mem" "$ip" "$ptext" "$pcolor"
