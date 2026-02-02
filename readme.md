# Dotfiles

## Installation

Clone with submodules:
```zsh
git clone --recurse-submodules https://github.com/sidoshi/dotfiles.git
cd dotfiles
```

If you already cloned without submodules, initialize them:
```zsh
git submodule update --init --recursive
```

Apply the dotfiles:
```zsh
stow --adopt .
```
