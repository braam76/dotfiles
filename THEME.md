# Shared theme

The source of truth is now **`theme-generator/themes/solarized-osaka.json`**, not
independent per-program Solarized Osaka ports. It contains the complete HSL
palette supplied from Solarized Osaka's Lua table, plus shared semantic roles.

Read **[theme-generator/README.md](theme-generator/README.md)** for the Python/Jinja
environment, service setup, template syntax, app coverage and reload limitations.

## How it works

```text
JSON palette + semantic roles
            ↓
      Jinja templates
            ↓
   native files in home/
            ↓ Stow links
      applications
```

The user service watches JSON/templates and renders changed files. Supported
apps reload automatically. Apps without a safe live reload read the new colors
on restart; the generator never kills your editors or desktop applications.
Edit templates rather than generated files. Layout/config files not owned by a
template remain directly editable.

Neovim still uses the Solarized Osaka plugin for highlight coverage, but the
shared JSON overrides its palette after vivid processing. This prevents the
plugin and terminal from independently choosing different RGB values.

VS Code remains excluded to preserve its newer local configuration. Pi uses its
terminal-adaptive `system` theme, including Pi's own contrast adjustments.

## Scope

Generated themes cover Alacritty, Neovim, Emacs, btop, tmux, Yazi and file previews,
Mango, Fuzzel, Mako, Walker, Waybar, Starship, Fish/Zsh, GTK 2/3/4 and KDE/Qt.

Firefox, Helium and LibreOffice inherit system colors where their selected UI
backend supports them. Browser profiles, webpages, documents, icons, fixed
Plasma SVG assets, the bootloader and SDDM are not forcibly recolored. Shared
system decorations may also affect VS Code even though its settings are untouched.
Fonts, color management and app-specific shading can still affect perception;
sharing a palette does not make different rendering engines pixel-identical.

## Earlier theme source

The initial static adaptations used
https://github.com/motorsss/omarchy-solarizedosaka-theme at revision
`4cb12e9d4321f76dd7b7fdbb22c93a4d5633be95`. Layout and role mappings were retained
as the basis for the templates, but the original port's independent RGB values
are no longer authoritative. Its wallpaper was not installed.
