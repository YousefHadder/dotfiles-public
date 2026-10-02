# Establish Homebrew before any dependent path or plugin configuration.
if (( ! $+commands[brew] )); then
  for brew_bin in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
    if [[ -x "$brew_bin" ]]; then
      export PATH="${brew_bin:h}:$PATH"
      break
    fi
  done
  unset brew_bin
fi
if (( ! $+commands[brew] )); then
  print -u2 'dotfiles: Homebrew is missing; run the tools installation phase.'
  return 1
fi
BREW_HOME=$(command brew --prefix) || return
_eval_cached brew-shellenv brew shellenv