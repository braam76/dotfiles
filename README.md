# Dotfiles

NixOS manages packages, drivers, services and desktop integration. GNU Stow
manages native application configs under `home/`. There is no Home Manager or
Stylix configuration layer; the exported palettes are ordinary editable files.

## Install / update

From this checkout:

```sh
sudo nixos-rebuild switch --flake . --impure
stow --no-folding --target="$HOME" home
```

Edit files in `home/` or through their links in your home directory, then reload
the application. No rebuild is needed for application settings. Commit the
changes with Git; NixOS rollbacks do not roll back these files.

Shell aliases:

```sh
snr-switch  # sudo nixos-rebuild switch --flake ~/dotfiles --impure
snr-update  # sudo nixos-rebuild switch --flake ~/dotfiles --impure --update
```

### One-time migration from Home Manager

Removing Home Manager from NixOS does not remove its previously deployed links.
After rebuilding, preview the handoff and then apply it:

```sh
python3 scripts/migrate-to-stow.py
python3 scripts/migrate-to-stow.py --apply
```

The helper backs up old Home Manager links and files conflicting with Stow into
`~/.local/state/dotfiles-backups/<timestamp>/`, then runs Stow. It does not use
`stow --adopt`, overwrite the repository from your home directory, or import
secrets/caches/history. Close configuration editors and KDE System Settings
before migrating. Log out and back in afterwards to refresh shell/session state.

For a fresh machine, use the normal Stow command instead. If it reports conflicts,
back up the existing files before retrying. GTK/KDE apps may rewrite some settings;
review `git diff` before committing.

## Configuration map

```text
flake.nix / flake.lock       # Nix inputs and pinned versions
parts.nix                   # Supported systems
hosts/                      # Hardware import, bootloader and host assembly
users/                      # User account and login shell
system/                     # Audio, fonts, networking, locale, printing, Nix
desktop/                    # Desktop/session packages and service integration
cli-tools/                  # Shells and CLI packages
development/                # Editors, languages, containers and virtual machines
vpn/                        # VPN integration
ai/                         # AI packages
home/
  .config/
    alacritty/              # Terminal settings, font and colors
    Code/User/              # VS Code settings
    direnv/                 # nix-direnv loading
    elephant/               # Clipboard history provider
    emacs/                  # Native Elisp configuration
    fish/                   # Shell initialization and y function
    fontconfig/             # User font preferences
    fuzzel/                 # Application launcher
    git/                    # User identity
    gtk-3.0/ / gtk-4.0/      # GTK appearance
    hypr/                   # Hyprlock
    kdeglobals              # KDE colors and fonts
    mako/                   # Notifications
    mango/                  # Window manager and static palette
    nvim/                   # Native Lua configuration
    tmux/                   # Multiplexer
    networkmanager-dmenu/   # Network menu
    walker/                 # Clipboard picker and styling
    waybar/                 # Bar, scripts, font and static palette
    yazi/                   # File manager theme
  .local/libexec/            # Network menu compatibility helper
  .pi/agent/settings.json   # Pi settings only, no credentials or sessions
  .gtkrc-2.0                # GTK2 font settings
  .zshrc                    # Zsh initialization, aliases and integrations
scripts/migrate-to-stow.py  # One-time, backed-up handoff from Home Manager
```

Nix still packages `screenshot`, `clipboard-daemon` and `clipboard-history` with
their runtime dependencies. Mako's D-Bus activation comes from its installed
package. VS Code's direnv extension is bundled with its Nix package.

## Mango

Reload configuration with `Super+Shift+R` or:

```sh
mmsg dispatch reload_config
```

### Screen lock

- `Super+L`: lock immediately (`Super+Shift+L` switches layouts).
- Terminal: `hyprlock --grace 0` or `loginctl lock-session`.
- Automatically locks after 10 minutes idle and before suspend.

The idle watcher starts with Mango; Plasma keeps its own screen locker. Edit the
background path in `home/.config/hypr/hyprlock.conf` to change the wallpaper.

### Screenshots

- `Print` or `Super+Shift+S`: select a region (`Escape` cancels).
- `Shift+Print`: capture the full screen.
- Terminal: `screenshot region` or `screenshot full`.

Screenshots are copied to the clipboard first. Click the notification's Save
button to choose a permanent destination; otherwise the temporary image is
removed after the notification closes.

### Clipboard history

`Super+V` opens Walker's Elephant-backed picker; `Super+D` opens Fuzzel.
`Escape` closes the picker; `Alt+J` shows available actions.

Clipboard data and previews stay under `$XDG_RUNTIME_DIR/clipboard-cache`, with
temporary images under `$XDG_RUNTIME_DIR/clipboard-tmp`. History clears on reboot
and may clear after your last logout. No clipboard database is version-controlled.
