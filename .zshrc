export ZSH="$HOME/.oh-my-zsh"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

zstyle ':omz:update' mode reminder
plugins=(git zoxide)

# 3. FAST COMPINIT (The Big Winner)
# This replaces the internal OMZ compinit call with a cached version
autoload -Uz compinit
for dump in "${ZDOTDIR:-$HOME}/.zcompdump"(N.m1); do
  compinit -C
done
if [[ ! -f "${ZDOTDIR:-$HOME}/.zcompdump" ]]; then
  compinit
fi

source $ZSH/oh-my-zsh.sh

# USER CONFIG & ALIASES
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"
bindkey -v
alias ls='lsd'
alias la='ls -A1 --blocks permission,date,git,size,name'
alias cat='bat'
alias cd='z'
alias top='btm'
alias du='dust'

eval "$(atuin init zsh --disable-up-arrow)"
eval "$(mise activate zsh)"

# TOOL INITIALIZATION (Optimized)
source <(/opt/homebrew/bin/starship init zsh --print-full-init)
source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

[[ -f ~/.local.zshrc ]] && source ~/.local.zshrc

# This is a dirty hack to cd into the directory when ghostty is launched from GJump raycast extension
# (https://github.com/sidoshi/GJump)
if [[ -n "$GHOSTTY_LAUNCH_DIR" ]]; then
  cd "$GHOSTTY_LAUNCH_DIR"

  if [[ -n "$GHOSTTY_LAUNCH_NVIM" && -n "$GHOSTTY_LAUNCH_ID" && ! -f "/tmp/ghostty-launch-$GHOSTTY_LAUNCH_ID" ]]; then
    touch "/tmp/ghostty-launch-$GHOSTTY_LAUNCH_ID"
    zoxide add $GHOSTTY_LAUNCH_DIR 
    nvim .
  fi
fi

# Define where your source-of-truth Brewfile lives
export DOTFILES_BREWFILE="$HOME/dotfiles/Brewfile"
# The "Auto-Sync" Wrapper
brew() {
  # Call the real homebrew binary 
  command brew "$@"
  # Check if the command was an installation or removal
  case "$1" in install|uninstall|tap|untap|cask)
    echo "--- 🔄 Auto-syncing Brewfile to dotfiles ---"
    # Update the Brewfile automatically
    command brew bundle dump --force --file="$DOTFILES_BREWFILE" ;;
  esac
}


