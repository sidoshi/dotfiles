export ZSH="$HOME/.oh-my-zsh"

# 1. PRE-LOAD SETTINGS
# Setting update mode to 'disabled' or 'reminder' helps, 
# but 'disabled' is fastest.
zstyle ':omz:update' mode reminder

# 2. PLUGINS
# Moved syntax-highlighting to the END of the plugin list (required for correctness)
plugins=(zsh-autosuggestions tmux zsh-syntax-highlighting)

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

. "$HOME/.atuin/bin/env"
# 4. TOOL INITIALIZATION (Optimized)
# Use --no-suggestions or similar flags if available to reduce compdef calls
source ~/.starship_init.zsh
source ~/.zoxide_init.zsh
source ~/.atuin_init.zsh

# Atuin setup - Ensure the path is set before eval

# 5. USER CONFIG & ALIASES
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="hx"
alias to='tmux new-session -A -s'
alias zz="zellij"
bindkey -v

# Your custom clear function
clear-scrollback() {
    printf '\033[H\033[2J\033[3J'
    [[ -n "$WIDGET" ]] && zle .reset-prompt && zle redisplay
}
zle -N clear-scrollback
alias c="clear-scrollback"

source $HOME/.local.zshrc

