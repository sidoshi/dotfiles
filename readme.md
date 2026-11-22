# Dotfiles

## New machine setup

1. Install [Homebrew](https://brew.sh). The installer also installs Git.

2. Install mise. The setup command is a mise task, so mise must be there first.

   ```zsh
   brew install mise
   ```

3. Clone the repository to `~/dotfiles`. The tasks and `.zshrc` expect this path.

   ```zsh
   git clone https://git.lab.sidoshi.net/gh/dotfiles ~/dotfiles
   ```

4. Run the bootstrap task. `mise trust` lets mise read the config and tasks in the repository.

   ```zsh
   cd ~/dotfiles
   mise trust
   mise run bootstrap
   ```

   The task does these steps in sequence:

   - `mise install`: installs the tools in `.config/mise/config.toml`.
   - `brew bundle`: installs the packages in the `Brewfile`.
   - `stow .`: links the config files into the home directory. If a file already exists there, stow stops and does not overwrite it. Move the file away and run the task again.
   - `mise run macos`: applies the macOS settings.

   It is safe to run the task more than one time.

5. Open a new terminal, then do the manual steps:

   - `mise run fnox`: stores the age key. See [Secret Management](#secret-management).
   - Sign in to atuin and sync. Then run `atuin threads import` to index existing agent sessions (`atuin resume` to search and resume them).
   - `rex do apply_look` in a Rex terminal. See [Rex](#rex).

## macOS settings

`mise run macos` writes the macOS settings with `defaults`: Dock, Finder, trackpad, screenshots, window tiling, Caps Lock as Escape, and the Spotlight shortcuts (off, because Sol uses cmd+space). It also turns on Touch ID for sudo, and asks for the password one time to do that. The task is `.config/mise/tasks/macos`. To add a setting, add a `defaults write` line there.

Log out and log in again after the first run. The trackpad, Caps Lock and window tiling settings start only then.

## Upgrades

`mise run upgrade` upgrades the Homebrew packages, the mise tools and the nvim plugins, then removes the zsh cache. The task is `.config/mise/tasks/upgrade`.

`.config/mise/mise.lock` holds the exact version of each mise tool, so `mise install` on a new machine gives the same versions. Only `mise run upgrade` (or `mise upgrade`) moves the versions. Commit `mise.lock` and `lazy-lock.json` after each upgrade.

## Rex

- `Cmd+P`: open a project with nvim and Claude.
- `Cmd+Alt+P`: open a project with nvim and Pi. If the project is already open, this selects its Pi tab or creates one.

Pi reports working, blocked, done, and error states to Rex through the Program Status Protocol.

Rex keeps interface settings in the app preferences, not in `init.lua`. On a new machine, run this one time to set the pane border, padding, glass style, and fade:

```zsh
rex do apply_look
```

Keep Rex's appearance set to Dark and disable **Settings > Interface > Panes > Match program backgrounds**. Otherwise macOS appearance changes and Pi's fullscreen background can change Rex's colors.

Pi uses its fixed `dark` theme from `.pi/agent/settings.json` instead of deriving colors from the terminal.

## Secret Management

Secrets are managed with [fnox](https://github.com/fnox-dev/fnox), an age-based secret store. fnox is installed automatically via mise (declared in `.config/mise/config.toml`).

The `.zshrc` eval hook loads secrets into your shell environment:

```zsh
eval "$(fnox activate zsh)"
```

### New machine setup

On a new machine, run the fnox task to store your age private key (the key that decrypts your fnox secrets):

```zsh
mise run fnox
```

This will prompt you to paste your `AGE-SECRET-KEY-...` private key and store it at `~/.config/fnox/age.txt` (chmod 600). Keep a copy of this key somewhere safe (e.g. a password manager) — it cannot be recovered if lost.
