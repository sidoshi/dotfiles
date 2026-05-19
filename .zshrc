export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export XDG_CONFIG_HOME="$HOME/.config"
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"
bindkey -v

# `up` — promote bare-bones shell into a smarter shell.
# `up <cmd> [args...]` — ensure smart-mode is loaded, then run the command.
up() {
  if [[ -z $UP_LOADED ]]; then
    UP_LOADED=1
    eval "$(mise activate zsh)"
    eval "$(mise completion zsh)"
    eval "$(fnox activate zsh)"
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
  elif (( $# == 0 )); then
    print -u2 "up: already loaded"
    return
  fi

  (( $# > 0 )) && "$@"
}

# Ghostty launched from GJump raycast extension (https://github.com/sidoshi/GJump)
if [[ -n "$GHOSTTY_LAUNCH_DIR" ]]; then
  cd "$GHOSTTY_LAUNCH_DIR"
  if [[ -n "$GHOSTTY_LAUNCH_NVIM" && -n "$GHOSTTY_LAUNCH_ID" && ! -f "/tmp/ghostty-launch-$GHOSTTY_LAUNCH_ID" ]]; then
    touch "/tmp/ghostty-launch-$GHOSTTY_LAUNCH_ID"
    command zoxide add "$GHOSTTY_LAUNCH_DIR"
    up
    nvim .
  fi
fi

# Brewfile auto-sync (function — zero startup cost)
export DOTFILES_BREWFILE="$HOME/dotfiles/Brewfile"
brew() {
  command brew "$@"
  case "$1" in install|uninstall|tap|untap|cask)
    echo "--- 🔄 Auto-syncing Brewfile to dotfiles ---"
    command brew bundle dump --force --file="$DOTFILES_BREWFILE" ;;
  esac
}

# Always-on essentials: prompt + directory jumping
eval "$(zoxide init zsh)"
source <(/opt/homebrew/bin/starship init zsh --print-full-init)
eval "$(atuin init zsh --disable-up-arrow)"

# Cached compinit: full audit/rebuild once a day, fast `-C` otherwise.
autoload -Uz compinit
local zd="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n $zd(#qN.m-1) ]]; then
  compinit -C -d "$zd"
else
  compinit -d "$zd"
  touch "$zd"
fi


[[ -f ~/.local.zshrc ]] && source ~/.local.zshrc
