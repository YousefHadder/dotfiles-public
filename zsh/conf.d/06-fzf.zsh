# FZF Configuration

_eval_cached fzf fzf --zsh

# Explicit key bindings for Warp compatibility
bindkey '^R' fzf-history-widget
bindkey '^T' fzf-file-widget
bindkey '^[c' fzf-cd-widget

export FZF_DEFAULT_COMMAND="fd --hidden --strip-cwd-prefix --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_CTRL_R_OPTS="
  --bind 'ctrl-y:execute-silent(echo -n {2..} | pbcopy)+abort'
  --color header:italic
  --header 'Press CTRL-Y to copy command into clipboard'"
export FZF_ALT_C_COMMAND="fd --type=d --hidden --strip-cwd-prefix --exclude .git"
# Use fzf's native --tmux popup (fzf 0.53+), not FZF_TMUX_OPTS. Setting
# FZF_TMUX_OPTS makes __fzf_comprun route through the deprecated `fzf-tmux`
# script, which runs `tmux popup ... >/dev/null 2>&1` and then blocks forever on
# a FIFO whenever the popup can't open (no attached client, nested session,
# stale inherited $TMUX_PANE) — the shell hangs with no window and no error.
export FZF_DEFAULT_OPTS="--style full --preview 'fzf-preview.sh {}' --bind 'focus:transform-header:file --brief {}' --height 50% --layout=default --border --color=hl:#87d7ff --tmux center,90%,70%"
export FZF_DEFAULT_OPTS=$FZF_DEFAULT_OPTS'
  --color=fg:#ffffff,fg+:#ffffff,bg:#262626,bg+:#333333
  --color=hl:#87d7ff,hl+:#87d7ff,info:#d7875f,marker:#d7d787
  --color=prompt:#ff8787,spinner:#87d7ff,pointer:#d7875f,header:#666666
  --color=border:#666666,separator:#666666,label:#ffffff,query:#ffffff
  --border="rounded" --border-label="" --preview-window="border-rounded" --prompt="> "
  --marker=">" --pointer="◆" --separator="─" --scrollbar="│"'
export FZF_CTRL_T_OPTS="--preview 'bat --color=always -n --line-range :500 {}'"
export FZF_ALT_C_OPTS="--preview 'eza --icons=always --tree --color=always {} | head -200'"

# `**<TAB>` completion ignores FZF_DEFAULT_COMMAND and falls back to fzf's
# built-in walker (`--walker file,dir,follow,hidden`), which has no ignore rules
# and follows symlinks — ~3.8M entries under $HOME, so completion appears to
# hang. These hooks are the documented override; fd covers the same ground in
# well under a second.
_fzf_compgen_path() {
  fd --hidden --exclude .git . "$1" | sed 's|^\./||'
}
_fzf_compgen_dir() {
  fd --type=d --hidden --exclude .git . "$1" | sed 's|^\./||'
}

source ~/scripts/fzf-git.sh