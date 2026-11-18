{
  flake.nixosModules.mango = { pkgs, ... }: let
    elephant = pkgs.elephant.override { enabledProviders = [ "clipboard" ]; };
  in {
    programs.mango.enable = true;
    security.pam.services.hyprlock = {};

    # These are packaged utilities, not generated application configuration.
    environment.systemPackages = with pkgs; [
      awww swayidle walker elephant fuzzel hyprlock mako waybar
      xwayland-satellite wl-clipboard
      (writeShellApplication {
        name = "clipboard-daemon";
        runtimeInputs = [ elephant coreutils wl-clipboard imagemagick ];
        text = ''
          export XDG_CACHE_HOME="''${XDG_RUNTIME_DIR:?}/clipboard-cache"
          export TMPDIR="$XDG_RUNTIME_DIR/clipboard-tmp"
          umask 077
          mkdir -p "$XDG_CACHE_HOME/elephant" "$TMPDIR"
          exec elephant
        '';
      })
      (writeShellApplication {
        name = "clipboard-history";
        runtimeInputs = [ elephant walker ];
        text = ''
          exec walker -m clipboard
        '';
      })
      (writeShellApplication {
        name = "screenshot";
        runtimeInputs = [ coreutils grim slurp wl-clipboard xdg-user-dirs libnotify zenity ];
        text = ''
          case "''${1:-region}" in
            region)
              geometry=$(slurp) || exit 0
              args=(-g "$geometry")
              ;;
            full) args=() ;;
            *) echo "Usage: screenshot [region|full]" >&2; exit 1 ;;
          esac

          file=$(mktemp --tmpdir="''${XDG_RUNTIME_DIR:?}" screenshot-XXXXXXXX.png)
          trap 'rm -f -- "$file"' EXIT
          grim "''${args[@]}" "$file"
          wl-copy --type image/png < "$file"

          action=$(notify-send --app-name=Screenshot --icon="$file" \
            --wait --expire-time=15000 --action=default="Save…" \
            "Screenshot copied" "Click to choose where to save it.") || exit 0
          [ "$action" = default ] || exit 0

          pictures=$(xdg-user-dir PICTURES)
          destination=$(zenity --file-selection --save --confirm-overwrite \
            --title="Save screenshot" \
            --filename="$pictures/Screenshot-$(date +%Y-%m-%d_%H-%M-%S).png") || exit 0
          [ -n "$destination" ] || exit 0
          cp -- "$file" "$destination"
          notify-send --app-name=Screenshot "Screenshot saved" "$destination"
        '';
      })
    ];
  };
}
