# Custom Functions

function y() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXXX")" cwd
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(command cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		builtin cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

function gpp() {
  if [ -z "$1" ]; then echo "usage: gpp file.cpp"; return 1; fi
  local src="$1"
  local out="${src%.*}"
  local CXX=""
  for c in g++-15 g++-13 g++-12 g++; do
    if command -v "$c" >/dev/null 2>&1; then CXX="$c"; break; fi
  done
  if [ -z "$CXX" ]; then echo "No g++ found (brew install gcc)"; return 1; fi
  "$CXX" -std=gnu++17 -O2 -Wall -Wextra "$src" -o "$out"
}

function grun() { gpp "$1" && "./${1%.*}"; }

function gsw() {
  local branch
  branch=$(
    git branch -a --format='%(refname:short)' \
      | sed 's|^origin/||' \
      | sort -u \
      | fzf --tmux center,60%,50% --border --reverse \
          --header "Switch branch" \
          --preview 'git log --oneline --graph --color=always {} | head -20'
  )
  [[ -n "$branch" ]] && git switch "$branch"
}

function ndiff() {
  local base_branch="${1:-}"
  local remote="${NDIFF_REMOTE:-${NCHANGED_REMOTE:-origin}}"
  local current_branch base_ref comparison_base tmp exit_status

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ndiff: not inside a git repository" >&2
    return 1
  fi

  if ! command -v nvim >/dev/null 2>&1; then
    echo "ndiff: nvim not found" >&2
    return 1
  fi

  current_branch=$(git branch --show-current 2>/dev/null)

  if [[ -z "$base_branch" && -n "$current_branch" ]] && command -v gh >/dev/null 2>&1; then
    base_branch=$(gh pr view --json baseRefName --jq .baseRefName 2>/dev/null)
  fi

  if [[ -z "$base_branch" ]]; then
    base_ref=$(git symbolic-ref --quiet --short "refs/remotes/$remote/HEAD" 2>/dev/null)
    base_branch="${base_ref#$remote/}"
  fi

  if [[ -z "$base_branch" ]]; then
    echo "ndiff: could not detect a base branch; pass one explicitly, e.g. ndiff main" >&2
    return 1
  fi

  if [[ "$base_branch" == */* ]]; then
    base_ref="$base_branch"
  else
    base_ref="$remote/$base_branch"
    git fetch --quiet "$remote" "$base_branch" 2>/dev/null || \
      echo "ndiff: warning: could not fetch $base_ref; using local ref if available" >&2
  fi

  if ! git rev-parse --verify --quiet "$base_ref" >/dev/null; then
    echo "ndiff: base ref '$base_ref' not found; pass one explicitly, e.g. ndiff main" >&2
    return 1
  fi

  comparison_base=$(git merge-base "$base_ref" HEAD 2>/dev/null)
  if [[ -z "$comparison_base" ]]; then
    echo "ndiff: could not find a merge base between $base_ref and HEAD" >&2
    return 1
  fi

  tmp=$(mktemp -t ndiff.XXXXXX) || return 1
  git diff --name-only -z --diff-filter=ACMRTUXB "$comparison_base" HEAD > "$tmp" || {
    exit_status=$?
    rm -f -- "$tmp"
    return "$exit_status"
  }

  if [[ ! -s "$tmp" ]]; then
    echo "ndiff: no changed files relative to $base_ref"
    rm -f -- "$tmp"
    return 0
  fi

  echo "ndiff: opening files changed relative to $base_ref"
  GITSIGNS_BASE="$comparison_base" xargs -0 nvim -- < "$tmp"
  exit_status=$?
  rm -f -- "$tmp"
  return "$exit_status"
}

function help-me() {
  local conf_dirs=("$HOME/conf.d" "$HOME/.oh-my-zsh/custom")
  local entries=()

  # Collect aliases from the zsh aliases hash
  local name expansion
  for name expansion in "${(@kv)aliases}"; do
    entries+=("[alias] $name :: $expansion")
  done

  # Collect user-defined functions (filter by source path)
  local fname src
  for fname in ${(k)functions}; do
    src="${functions_source[$fname]}"
    [[ -z "$src" ]] && continue
    local match=0
    for d in "${conf_dirs[@]}"; do
      [[ "$src" == "$d"/* ]] && { match=1; break; }
    done
    (( match )) || continue
    entries+=("[func] $fname :: $(basename "$src")")
  done

  local entry
  entry=$(
    printf '%s\n' "${entries[@]}" \
      | sort \
      | fzf --tmux center,80%,60% --border --reverse \
          --header "Aliases & Functions (Enter to put on prompt)" \
          --preview '
            name=$(echo {} | sed "s/^\[[a-z]*\] //; s/ :: .*//")
            type=$(echo {} | grep -o "^\[[a-z]*\]")
            if [[ "$type" == "[alias]" ]]; then
              echo "Alias: $name"
              echo "Expands to: $(echo {} | sed "s/.* :: //")"
            else
              echo "Function: $name"
              echo "Source: $(echo {} | sed "s/.* :: //")"
              echo "─────────────────────"
              which "$name" 2>/dev/null
            fi
          '
  ) || return 0

  [[ -z "$entry" ]] && return 0
  local cmd="${entry#\[*\] }"
  cmd="${cmd%% :: *}"
  print -z "$cmd"
}

# ggv - git grep + fzy + vim
# Usage: ggv <pattern> [max-count-per-file]
function ggv() {
  local ggv_dir="./"
  local maxc="${2:--1}"
  local gres=""

  if [[ $maxc -ge 1 ]] 2>/dev/null; then
    gres=$(git grep -rnE --max-count="$maxc" "$1" "$ggv_dir" | fzy)
  else
    gres=$(git grep -rnE "$1" "$ggv_dir" | fzy)
  fi

  local ggv_file=$(echo "$gres" | awk -F: '{print $1}')
  local ggv_ln=$(echo "$gres" | awk -F: '{print "+" $2}')

  if [[ -n $ggv_file ]]; then
    echo "reading file $ggv_file"
    local cmd="vim $ggv_file $ggv_ln"
    eval "$cmd"
    print -s "$cmd"
  fi
}

# torrra — make sure the Jackett indexer is up before launching the TUI

export JACKETT_DIR="${JACKETT_DIR:-$HOME/Downloads/Jackett-fresh/Jackett}"
export JACKETT_URL="${JACKETT_URL:-http://localhost:9117}"

function jackett-up() {
  curl -s -o /dev/null --max-time 2 "$JACKETT_URL"
}

function jackett-start() {
  if jackett-up; then
    return 0
  fi

  if [[ ! -x "$JACKETT_DIR/jackett" ]]; then
    echo "jackett: executable not found at $JACKETT_DIR/jackett" >&2
    echo "jackett: set JACKETT_DIR to your install path" >&2
    return 1
  fi

  echo "Starting Jackett..."
  # Keep the child PID while loading Definitions/ from Jackett's own directory.
  (cd "$JACKETT_DIR" && exec nohup "$JACKETT_DIR/jackett" --NoRestart) \
    >>"$JACKETT_DIR/jackett-stdout.log" 2>&1 </dev/null &
  local jackett_pid=$! exit_status

  # Jackett loads ~600 indexer definitions, so cold start takes ~10-15s
  local waited=0
  while (( waited < 60 )); do
    if jackett-up; then
      echo "Jackett ready at $JACKETT_URL (${waited}s)"
      return 0
    fi
    if ! kill -0 "$jackett_pid" 2>/dev/null; then
      exit_status=0
      wait "$jackett_pid" || exit_status=$?
      echo "jackett: exited during startup (exit $exit_status)" >&2
      echo "jackett: check $JACKETT_DIR/jackett-stdout.log" >&2
      return 1
    fi
    sleep 1
    (( waited++ ))
  done

  echo "jackett: timed out after ${waited}s waiting for $JACKETT_URL" >&2
  echo "jackett: check $JACKETT_DIR/jackett-stdout.log" >&2
  return 1
}

function jackett-stop() {
  local pids
  # -x matches the executable name, so this finds Jackett whether it was
  # started by this function, by ./jackett, or by the launchd agent
  pids=$(pgrep -x jackett 2>/dev/null)
  if [[ -z "$pids" ]]; then
    echo "Jackett is not running"
    return 0
  fi
  echo "$pids" | while read -r pid; do kill "$pid"; done
  echo "Jackett stopped"
}

function torrra() {
  jackett-start || return 1
  command torrra "$@"
}

# If you use envman, add the following to your shell configuration:
# [ -s "$HOME/.config/envman/load.sh" ] && source "$HOME/.config/envman/load.sh"
