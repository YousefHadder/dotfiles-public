# Environment Variables

export ZSH="$HOME/.oh-my-zsh"
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export GHOSTTY_HOME="$XDG_CONFIG_HOME/ghostty"

# Preserve the locale provisioned by the OS/container.
export STARSHIP_CONFIG=$HOME/.config/starship.toml
export NVM_DIR="$HOME/.nvm"
export EZA_CONFIG_DIR="$XDG_CONFIG_HOME/eza"

# herdr panes inherit $TMUX/$TMUX_PANE from the herdr *server*, which is a
# long-lived daemon that keeps whatever tmux context it happened to be launched
# from. They are stale by construction: they describe a tmux pane, not the herdr
# pane we're actually in, and they never update when the herdr client reattaches
# elsewhere. Anything that honors them (fzf --tmux, tmux popup/display-message,
# tmux-based clipboard) targets an invisible or nonexistent tmux client and
# hangs or silently does nothing. herdr disables nesting, so being in a herdr
# pane means we are definitively not in tmux — drop the vars and let those tools
# take their normal non-tmux path.
if [[ -n $HERDR_PANE_ID ]]; then
  unset TMUX TMUX_PANE
fi
true
