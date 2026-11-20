# Flow: environment, key bindings, history, completion, tools (mise, fnox,
# prompt, atuin, zoxide), machine-local overrides, zsh plugins.

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export XDG_CONFIG_HOME="$HOME/.config"
export PATH="$HOME/.local/bin:$PATH"
export EDITOR="nvim"

# Vi mode. KEYTIMEOUT=1 makes Escape switch to normal mode without a delay.
bindkey -v
KEYTIMEOUT=1
# The vi defaults cannot delete text typed before the last switch to insert mode.
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line
# ctrl+e opens the current command line in $EDITOR.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M viins '^E' edit-command-line
bindkey -M vicmd '^E' edit-command-line

# atuin holds the searchable history. This is the plain zsh history behind it.
HISTSIZE=50000
SAVEHIST=50000
setopt share_history hist_ignore_all_dups hist_ignore_space

# Cached compinit: full audit/rebuild once a day, fast `-C` otherwise.
autoload -Uz compinit
local zd="${ZDOTDIR:-$HOME}/.zcompdump"
if [[ -n $zd(#qN.m-1) ]]; then
  compinit -C -d "$zd"
else
  compinit -d "$zd"
  touch "$zd"
fi
# Tab shows a menu to move through. Lower case input also matches upper case.
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

eval "$(mise activate zsh)"
eval "$(mise completion zsh)"
eval "$(fnox activate zsh)"
source <(/opt/homebrew/bin/starship init zsh --print-full-init)
# atuin's shell hooks run on every command, so put the real binary on PATH
# and skip the slower mise shim.
export PATH="$HOME/.local/share/mise/installs/atuin/latest/atuin-aarch64-apple-darwin:$PATH"
eval "$(atuin init zsh)"
eval "$(zoxide init zsh)"

# Brewfile auto-sync (function — zero startup cost)
export DOTFILES_BREWFILE="$HOME/dotfiles/Brewfile"
brew() {
  command brew "$@"
  case "$1" in install|uninstall|tap|untap|cask)
    echo "--- 🔄 Auto-syncing Brewfile to dotfiles ---"
    command brew bundle dump --force --file="$DOTFILES_BREWFILE" ;;
  esac
}

[[ -f ~/.local.zshrc ]] && source ~/.local.zshrc

# zsh-syntax-highlighting must load last, after all key bindings and widgets.
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
