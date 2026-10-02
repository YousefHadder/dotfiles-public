# Tool Initializations

# NVM (lazy-loaded to avoid ~500ms startup cost)
if [[ -s "$BREW_HOME/opt/nvm/nvm.sh" ]]; then
  nvm() {
    unset -f nvm
    source "$BREW_HOME/opt/nvm/nvm.sh" || return
    nvm "$@"
  }
fi

# Starship Prompt
_eval_cached starship starship init zsh

# Zoxide — initialized at the end of ~/.zshrc (its doctor warns otherwise)

# rbenv — initialized in ~/.zshrc with --no-rehash (faster)