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
