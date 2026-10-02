#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if ! command -v python3 >/dev/null 2>&1; then
  printf 'dotfiles: Python 3.9+ is required; install it before running this installer.\n' >&2
  exit 1
fi
exec python3 -B "$SCRIPT_DIR/install/installer.py" "$@"
