export ZSH="$HOME/.oh-my-zsh"
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# 1. PRE-LOAD SETTINGS
# Setting update mode to 'disabled' or 'reminder' helps, 
# but 'disabled' is fastest.
zstyle ':omz:update' mode reminder

# 2. PLUGINS
# Moved syntax-highlighting to the END of the plugin list (required for correctness)
plugins=(zsh-autosuggestions zsh-syntax-highlighting)

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

# Atuin setup - Ensure the path is set before eval
. "$HOME/.atuin/bin/env"

# 4. TOOL INITIALIZATION (Optimized)
# Use --no-suggestions or similar flags if available to reduce compdef calls
source ~/.starship_init.zsh
source ~/.zoxide_init.zsh
source ~/.atuin_init.zsh


# 5. USER CONFIG & ALIASES
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"
bindkey -v


source $HOME/.local.zshrc


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


