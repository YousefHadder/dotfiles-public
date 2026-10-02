# Modular Zsh Configuration Loader
# This file sources all configuration files from conf.d/ directory

# Get the directory where this .zshrc file is located
ZSHRC_DIR="${${(%):-%x}:A:h}"

# Cache successful initialization only; a failed command must not poison startup.
_eval_cached() {
  emulate -L zsh
  local key=$1
  shift
  local cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh-init/${key}.zsh"
  local bin=$1
  [[ $bin == */* ]] || bin=${commands[$bin]}
  if [[ -z $bin || ! -x $bin ]]; then
    print -u2 "dotfiles: missing initialization command: $1"
    return 1
  fi
  if [[ ! -s $cache || (-n $bin && $bin -nt $cache) ]]; then
    mkdir -p "${cache:h}" || return
    local temporary
    temporary=$(mktemp "${cache}.XXXXXX") || return
    if ! "$@" >|"$temporary"; then
      rm -f "$temporary"
      print -u2 "dotfiles: initialization failed: $1"
      return 1
    fi
    mv -f "$temporary" "$cache" || return
  fi
  source "$cache"
}
zsh-cache-clear() {
  local file
  for file in "${XDG_CACHE_HOME:-$HOME/.cache}"/zsh-init/*.zsh(N); do
    rm -f "$file" || return
  done
  print 'zsh init cache cleared; restart your shell'
}

# Dedupe PATH/fpath so repeated prepends don't accumulate across re-sources and
# so $fpath stays stable (which keeps compinit's cached dump valid).
typeset -gU PATH path FPATH fpath

# Source all configuration files in order
for config_file in "$ZSHRC_DIR"/conf.d/*.zsh; do
  source "$config_file" || {
    print -u2 "dotfiles: failed to load $config_file"
    return 1
  }
done

unset config_file ZSHRC_DIR

if (( $+commands[rbenv] )); then
  export PATH="$HOME/.rbenv/shims:$PATH"
  rbenv() {
    unset -f rbenv
    eval "$(command rbenv init - --no-rehash zsh)" || return
    rbenv "$@"
  }
fi
if [[ -d "$HOME/.bun/bin" ]]; then
  export BUN_INSTALL="$HOME/.bun"
  export PATH="$BUN_INSTALL/bin:$PATH"
  if [[ -r "$BUN_INSTALL/_bun" ]]; then
    source "$BUN_INSTALL/_bun" || return
  fi
fi

# Work and local extensions are optional; present but broken files are errors.
for extension_dir in "$HOME/.config/dotfiles-work/zsh" "$HOME/.config/dotfiles-local/zsh"; do
  for config_file in "$extension_dir"/*.zsh(N); do
    source "$config_file" || {
      print -u2 "dotfiles: failed to load $config_file"
      return 1
    }
  done
done
unset extension_dir config_file

# Zoxide must initialize last so nothing overwrites its hooks (zoxide doctor)
_eval_cached zoxide zoxide init zsh
