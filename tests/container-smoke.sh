#!/usr/bin/env bash
set -euo pipefail

if [ ! -f /.dockerenv ]; then
  printf 'Run this smoke check only inside a disposable Docker container.\n' >&2
  exit 1
fi

phase="${1:-tools}"
public_root="${2:-$HOME/dotfiles-public}"
work_root="${3:-}"
export PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:$PATH"

for command in git stow zsh nvim tmux fzf fd rg starship zoxide eza bat lazygit yazi delta cargo gh copilot; do
  command -v "$command" >/dev/null || {
    printf 'FAIL: missing command: %s\n' "$command" >&2
    exit 1
  }
done
copilot_version="$(copilot --version)"
case "$copilot_version" in
  *"GitHub Copilot"*) ;;
  *) printf 'FAIL: copilot is not the GitHub CLI: %s\n' "$copilot_version" >&2; exit 1 ;;
esac
printf 'PASS: required tools and GitHub Copilot identity\n'
if [ "$phase" = tools ]; then
  exit 0
fi
if [ "$phase" != config ]; then
  printf 'Usage: %s tools|config [public-root] [work-root]\n' "$0" >&2
  exit 1
fi
if [ ! -t 0 ]; then
  printf 'Configuration smoke checks need a terminal; invoke with docker exec -t.\n' >&2
  exit 2
fi

test "$(readlink -f "$HOME/.zshrc")" = "$public_root/zsh/.zshrc"
test "$(git config --get core.pager)" = delta
test ! -e "$HOME/tests/test_customization_check.py"
if [ -n "$work_root" ]; then
  test "$(readlink -f "$HOME/.config/dotfiles-work/zsh/10-work.zsh")" = "$work_root/work/.config/dotfiles-work/zsh/10-work.zsh"
else
  test ! -e "$HOME/.config/dotfiles-work"
  test ! -e /input/work
fi

local_override="$HOME/.config/dotfiles-local/zsh/99-container-smoke.zsh"
if [ -e "$local_override" ] || [ -L "$local_override" ]; then
  printf 'Refusing to overwrite an existing test override: %s\n' "$local_override" >&2
  exit 1
fi
temporary="$(mktemp -d)"
trap 'rm -f "$temporary/stdout" "$temporary/stderr" "$local_override"; rmdir "$temporary"' EXIT
zsh -lic 'for name in nvim tmux gh copilot; do command -v "$name" || exit 1; done; whence -w z' \
  >"$temporary/stdout" 2>"$temporary/stderr"
if [ -s "$temporary/stderr" ]; then
  printf 'FAIL: shell startup wrote diagnostics:\n' >&2
  cat "$temporary/stderr" >&2
  exit 1
fi
printf 'PASS: configuration ownership, isolation, and clean login shell startup\n'

mkdir -p "$(dirname "$local_override")"
printf '%s\n' 'export DOTFILES_TEST_MARKER=local' > "$local_override"
zsh -lic 'test "$DOTFILES_TEST_MARKER" = local' >"$temporary/stdout" 2>"$temporary/stderr"
test ! -s "$temporary/stderr"
printf 'PASS: machine-local override is effective in the running shell\n'

if [ -n "$work_root" ]; then
  if zsh -lic 'load-secrets' >"$temporary/stdout" 2>"$temporary/stderr"; then
    printf 'FAIL: Linux keychain helper unexpectedly succeeded\n' >&2
    exit 1
  fi
  grep -q 'no macOS keychain' "$temporary/stderr"
  printf 'PASS: work startup is credential-free and explicit keychain use fails clearly on Linux\n'
else
  if zsh -lic 'whence -w load-secrets' >"$temporary/stdout" 2>"$temporary/stderr"; then
    printf 'FAIL: work credential helper leaked into public-only setup\n' >&2
    exit 1
  fi
  printf 'PASS: public-only shell has no work credential helper\n'
fi
