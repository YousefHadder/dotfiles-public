# Oh My Zsh Configuration

zstyle ':omz:update' mode disabled
plugins=(git gitfast)
if [[ ! -r "$ZSH/oh-my-zsh.sh" ]]; then
  print -u2 'dotfiles: Oh My Zsh is missing; run the tools installation phase.'
  return 1
fi
source "$ZSH/oh-my-zsh.sh"