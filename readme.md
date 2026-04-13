# Dotfiles

Install Homebrew.

Install Git (if for some reason the macOS default isn't firing):
brew install git

Clone your dotfiles:
git clone https://github.com/your-username/dotfiles.git ~/dotfiles

Run Brew Bundle from the repo:
brew bundle --file ~/dotfiles/Brewfile

Install Mise & Runtimes:
mise install

Stow your configs:

```zsh
cd ~/dotfiles
stow --adopt .
```

Install Oh My Zsh (with the KEEP_ZSHRC=yes flag).

Sign in to atuin and sync

## Secret Management

Secrets are managed with [fnox](https://github.com/fnox-dev/fnox), an age-based secret store. fnox is installed automatically via mise (declared in `.config/mise/config.toml`).

The `.zshrc` eval hook loads secrets into your shell environment:

```zsh
eval "$(fnox activate zsh)"
```

### New machine setup

On a new machine, run the bootstrap task to store your age private key (the key that decrypts your fnox secrets):

```zsh
mise run bootstrap:fnox
```

This will prompt you to paste your `AGE-SECRET-KEY-...` private key and store it at `~/.config/fnox/age.txt` (chmod 600). Keep a copy of this key somewhere safe (e.g. a password manager) — it cannot be recovered if lost.
