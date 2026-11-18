# Shared palette → native themes

One JSON palette, semantic roles, and Jinja templates. No Stylix/Home Manager or
Omarchy runtime is involved. Python + Jinja are provided by the pinned Nix flake.

## Layout

```text
theme-generator/
  render.py              # Renderer, CLI and debounced polling watcher
  config.json            # Selected theme, template → output mapping, reload hooks
  themes/
    solarized-osaka.json # Your complete HSL palette, plus semantic role mappings
  templates/             # Native program configs with Jinja expressions
  test_render.py         # Unit and watcher integration tests
  pyproject.toml         # Python/Jinja dependency metadata
```

Outputs are written to `../home/`, NOT directly to `~/.config`. Stow links them
into place. Existing links survive atomic replacement of the source files.
Generated outputs are checked into Git so a fresh checkout works before starting
the service. **Edit the JSON/templates, not generated files**: the next render
will replace edits to generated outputs. Non-generated configs remain editable
normally. Some templates contain settings as well as colors (for example Mako);
edit those settings in the template.

## Python environment and manual use

From the repository root, track the new Nix module first (a commit is not required):

```sh
git add theme-generator.nix
nix develop .#theme-generator
python theme-generator/render.py --check   # preview; exit 1 means changes pending
python theme-generator/render.py           # render without reloading apps
python theme-generator/render.py --reload  # render and reload changed apps
python -m unittest discover -s theme-generator -p 'test_*.py'
```

The shell includes `jinja2`; no global pip install or mutable venv is needed.

For a scratch output tree without changing your dotfiles:

```sh
python theme-generator/render.py --output-root /tmp/theme-preview
```

Do not combine scratch output with `--reload`: hooks address your running apps.

## Service

The NixOS module is imported by the desktop module. Enable/install it with:

```sh
# Git-backed flakes need new files tracked before a normal .# rebuild.
git add theme-generator.nix theme-generator
sudo nixos-rebuild switch --flake . --impure
systemctl --user enable --now theme-generator.service
journalctl --user -u theme-generator.service -f
```

Use the Git-backed flake rather than a whole-directory `path:` input, so ignored
private/runtime files are not accidentally included in a Nix-store snapshot.
The service is restricted to user `braam` and uses the live checkout at
`/home/braam/dotfiles/theme-generator`; adjust `theme-generator.nix` if the
checkout moves. There is also an installed `theme-render` command.

The watcher polls input content every 0.5 seconds, waits for one stable interval,
and renders on changes to `config.json`, `themes/`, or `templates/`, including
nested files and atomic editor saves. It does not watch generated outputs, so
there is no render/reload loop. Invalid input is logged, leaves existing files
alone, and is retried after the next input edit. Restart the service after editing
`render.py` itself. Stop it temporarily with:

```sh
systemctl --user stop theme-generator
```

Render all templates and validate JSON/TOML before writing anything. Writes are
atomic per file, not a multi-file transaction; an I/O failure can still leave a
partially updated set. Unchanged outputs are not rewritten. Output paths cannot
escape `home/`, including through symlinks. Templates and reload commands are
trusted local code; do not install unreviewed templates from strangers.

## Palette format

```json
{
  "name": "Example",
  "palette": {
    "bg": [192, 100, 5],
    "fg": "#839495",
    "blue": [205, 69, 49],
    "none": "NONE"
  },
  "roles": {
    "background": "bg",
    "foreground": "fg",
    "accent": "blue"
  }
}
```

Colors accept `#rrggbb`, `NONE`, or `[hue_degrees, saturation_percent,
lightness_percent]`. Roles reference palette keys or contain literal colors.
Roles must resolve to real RGB colors, not `NONE`. There is no Lua evaluation.
The bundled JSON contains every shade from your supplied Lua table.

`palette` contains raw colors; `roles` gives them a shared meaning. Change
`roles.foreground` from `fg` to `base0`, for example, to brighten normal text
across applications without editing templates. The supplied palette's `fg`
(55% lightness) and `base0` (65%) are deliberately different, as in your Lua.

Select another palette by changing `theme` in `config.json` to a file under
`themes/`. To fully reuse the existing templates, keep the palette keys/roles they
reference. A missing key is an error, not an empty string or a silent fallback.

## Templates and adding an app

The same roles can be emitted in different syntaxes:

```jinja
background = "{{ roles.background }}"
@define-color foreground {{ roles.foreground }};
focus_color=0x{{ roles.accent|rgba("ff") }}
border={{ roles.border|rgba("ff") }}
BackgroundNormal={{ roles.background|rgb }}
```

- Default value: `#rrggbb`.
- `hex`: `rrggbb` without a prefix.
- `rgb`: decimal `r,g,b`.
- `rgba("ff")`: `rrggbbff` without a prefix; alpha is hexadecimal.
- Jinja's `tojson` filter: useful for quoting generated JSON/Lua strings.

Add a template under `templates/`, then an entry to `config.json`:

```json
{
  "template": "my-app.conf.j2",
  "target": ".config/my-app/theme.conf",
  "reload": [["my-app", "reload"]]
}
```

`reload` is optional: a list of argv arrays, NOT shell snippets. Only changed
outputs trigger their hooks, and identical commands are deduplicated. Failures
are logged without undoing the generated files. After adding a new target, run
Stow once to establish its link; the watcher does not manage deployment links.

## Coverage and reload behavior

Templates cover Alacritty, Neovim's palette, Emacs, btop, tmux, Yazi including its
TextMate preview theme, Mango, Fuzzel, Mako, Walker, Waybar, Starship, Fish/Zsh,
GTK 2/3/4, KDE and the saved KDE color scheme. Pi follows the terminal palette.

- **Neovim:** keeps Solarized Osaka's rich plugin highlights, but overwrites all
  supplied palette keys after the plugin's vivid calculation. Transparency is
  enabled so the terminal background shows through; completion menus and active
  status lines retain their surfaces. A timer checks the generated Lua file every
  second and reloads it.
- **Emacs:** watches the source theme directory and reloads on changes.
- **Mango / Mako / Waybar:** reload commands run after changed output is written.
- **Walker:** its service is stopped after CSS changes; next activation starts
  with the new style. An open picker may close.
- **Alacritty:** normally watches its imported config automatically.
- **Fish/Zsh:** reload generated colors at the next prompt; Starship reads its
  config for each prompt. Start a new shell once to install these hooks.
- **Fuzzel / Hyprlock:** read colors on the next launch.
- **GTK/KDE/Qt, btop, Yazi:** files update automatically, but existing instances
  may need a restart or a desktop relogin. There is no blanket kill/restart hook.
- **Pi:** its `system` theme follows the terminal, with contrast adjustments;
  restart Pi if terminal palette changes are not picked up.

Restart Neovim/Emacs once after installing their new watcher code. No rebuild is
needed for subsequent palette/template edits.

VS Code is deliberately untouched here: there were newer local edits to its
settings and Nix module. It can be added with a template for the complete settings
file, merging `workbench.colorCustomizations` and `editor.tokenColorCustomizations`
with your preferences; a separate arbitrary theme JSON is not loaded by VS Code
automatically. Browsers/document contents and fixed Plasma SVG assets still have
the limitations described in `../THEME.md`.

A shared palette removes independently maintained color values, not rendering
differences: fonts, transparency, color management and app-specific syntax groups
can still make the same RGB color appear different. Prefer semantic roles and
opaque surfaces when comparing apps.
