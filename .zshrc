# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(zsh-syntax-highlighting zsh-autosuggestions)

# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
zstyle ':omz:update' mode reminder  # just remind me to update when it's time
source $ZSH/oh-my-zsh.sh

ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"



# User configuration
if [[ ! -f "$HOME/.local.zshrc" ]]; then
    echo "# Private zsh config" > "$HOME/.local.zshrc"
fi
source $HOME/.local.zshrc

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
export LOCAL_HOME="$HOME/.local/bin"
export PATH="$LOCAL_HOME:$PATH"

eval "$(starship init zsh)"
