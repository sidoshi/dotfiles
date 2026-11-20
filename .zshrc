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

# Completion. This block is before mise activate: mise runs its own compinit
# on each start when compinit did not run before it.
completionFiles="$HOME/.cache/zsh/completions"
# The Homebrew directory holds the completions for git, mise, brew and podman.
fpath=("$completionFiles" /opt/homebrew/share/zsh/site-functions $fpath)

# The mise tools print their completion files. This costs about 2 seconds, so
# it runs only when the directory does not exist.
# To make the files again, for example after a tool upgrade: rm -rf ~/.cache/zsh
if [[ ! -d "$completionFiles" ]]; then
  mkdir -p "$completionFiles"
  # mise is not active at this point, thus the tools run through the mise shims.
  miseShims="$HOME/.local/share/mise/shims"
  "$miseShims/atuin" gen-completions --shell zsh > "$completionFiles/_atuin"
  "$miseShims/auth0" completion zsh > "$completionFiles/_auth0"
  "$miseShims/bat" --completion zsh > "$completionFiles/_bat"
  "$miseShims/copilot" completion zsh > "$completionFiles/_copilot"
  "$miseShims/delta" --generate-completion zsh > "$completionFiles/_delta"
  "$miseShims/deno" completions zsh > "$completionFiles/_deno"
  "$miseShims/fd" --gen-completions zsh > "$completionFiles/_fd"
  "$miseShims/gh" completion -s zsh > "$completionFiles/_gh"
  "$miseShims/gitleaks" completion zsh > "$completionFiles/_gitleaks"
  "$miseShims/jj" util completion zsh > "$completionFiles/_jj"
  "$miseShims/kubectl" completion zsh > "$completionFiles/_kubectl"
  "$miseShims/lazygit" completion zsh > "$completionFiles/_lazygit"
  "$miseShims/rg" --generate complete-zsh > "$completionFiles/_rg"
  "$miseShims/saml2aws" --completion-script-zsh > "$completionFiles/_saml2aws"
  "$miseShims/sops" completion zsh > "$completionFiles/_sops"
  "$miseShims/starship" completions zsh > "$completionFiles/_starship"
  "$miseShims/yq" completion zsh > "$completionFiles/_yq"
  # These tools cannot print a completion file, but their download has one.
  miseInstalls="$HOME/.local/share/mise/installs"
  cp "$miseInstalls/bottom/latest/completion/_btm" "$completionFiles/_btm"
  cp "$miseInstalls/lsd/latest/"*/autocomplete/_lsd "$completionFiles/_lsd"
  cp "$miseInstalls/yazi/latest/"*/completions/_yazi "$completionFiles/_yazi"
  cp "$miseInstalls/zoxide/latest/completions/_zoxide" "$completionFiles/_zoxide"
  unset miseShims miseInstalls
  # The new files need a full compinit scan.
  rm -f "$HOME/.zcompdump"
fi

# The full compinit scan costs about 300 ms, so it runs one time per 24 hours.
# All other starts load the saved dump with -C.
autoload -Uz compinit
completionDumpsFromLastDay=("$HOME/.zcompdump"(N.mh-24))
if (( ${#completionDumpsFromLastDay} > 0 )); then
  compinit -C
else
  compinit
  touch "$HOME/.zcompdump"
fi
unset completionFiles completionDumpsFromLastDay
# Tab shows a menu to move through. Lower case input also matches upper case.
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# mise activate prints the current PATH, so its output cannot be kept in a file.
# mise also supplies the completion for fnox.
eval "$(/opt/homebrew/bin/mise activate zsh)"

# The other tools print the same setup code on each start, and each run costs
# 10 to 20 ms. This function keeps the output in ~/.cache/zsh and makes it
# again only when the tool binary is newer than the file.
# To make the files again: rm -rf ~/.cache/zsh
source_tool_setup() {
  local toolName="$1"
  # mise put the real binaries on PATH, so this is the full path, not a shim.
  local toolBinary="$commands[$toolName]"
  local setupFile="$HOME/.cache/zsh/$toolName.zsh"
  if [[ -z "$toolBinary" ]]; then
    echo "zshrc: $toolName is not installed" >&2
    return
  fi
  if [[ ! -s "$setupFile" || "$toolBinary" -nt "$setupFile" ]]; then
    mkdir -p "$HOME/.cache/zsh"
    "$toolBinary" "${@:2}" > "$setupFile"
  fi
  source "$setupFile"
}

source_tool_setup fnox activate zsh
source_tool_setup starship init zsh --print-full-init
source_tool_setup atuin init zsh
source_tool_setup zoxide init zsh

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
