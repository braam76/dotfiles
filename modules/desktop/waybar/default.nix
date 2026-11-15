{
  flake.nixosModules.waybar = { config, pkgs, ... }: let
    font = config.dotfiles.font;
    # networkmanager_dmenu 2.7 uses Walker's old -y password flag.
    # Keep its launcher basename for auto-detection, but adapt to Walker 2.x.
    networkWalker = pkgs.writeShellScriptBin "walker" ''
      args=()
      for arg in "$@"; do
        case "$arg" in
          -y) args+=(--password) ;;
          # Close after selection, including when Walker runs as a service.
          -k) ;;
          *) args+=("$arg") ;;
        esac
      done
      exec ${pkgs.walker}/bin/walker "''${args[@]}"
    '';
  in {
    programs.waybar.enable = true;

    # The systemd user service does not inherit the interactive shell PATH.
    # Include every external command used by config.jsonc and mango.py.
    systemd.user.services.waybar.path = [
      pkgs.python3
      pkgs.fuzzel
      pkgs.alacritty
      pkgs.btop
      pkgs.pavucontrol
      pkgs.networkmanager_dmenu
      pkgs.networkmanager
      pkgs.wireplumber
      pkgs.brightnessctl
      pkgs.systemd
      config.programs.mango.package
    ];

    home-manager.users.braam = { config, ... }: {
      home.packages = [
        pkgs.python3
        pkgs.brightnessctl
        pkgs.pavucontrol
        pkgs.networkmanager_dmenu
        pkgs.networkmanager
      ];

      # Use Walker's shared clipboard theme for network/password menus.
      # Keep advanced editing desktop-independent with nmtui.
      xdg.configFile."networkmanager-dmenu/config.ini".text = ''
        [dmenu]
        dmenu_command = ${networkWalker}/bin/walker
        prompt = Networks
        active_chars = ✓
        wifi_chars = ▂▄▆█

        [dmenu_passphrase]
        obscure = True

        [editor]
        terminal = ${pkgs.alacritty}/bin/alacritty
        gui_if_available = False
      '';

      xdg.configFile."waybar/mango.py".source =
        config.lib.dotfiles.link "modules/desktop/waybar/mango.py";

      xdg.configFile."waybar/config.jsonc".source = 
        config.lib.dotfiles.link "modules/desktop/waybar/config.jsonc";

      # Keep the upstream floating layout integrated with the shared palette.
      xdg.configFile."waybar/colors.css".text = let
        c = config.lib.stylix.colors.withHashtag;
      in ''
        @define-color foreground ${c.base05};
        @define-color foreground-inactive ${c.base04};
        @define-color background ${c.base00};
        @define-color surface ${c.base02};
        @define-color accent ${c.base0D};
        @define-color urgent ${c.base08};
      '';

      xdg.configFile."waybar/font.css".text = ''
        * {
          font-family: ${builtins.toJSON font.name}, "Font Awesome 7 Free", "Font Awesome 7 Brands", monospace;
          font-size: ${toString font.size}pt;
        }
      '';

      xdg.configFile."waybar/style.css".source =
        config.lib.dotfiles.link "modules/desktop/waybar/style.css";

      xdg.configFile."waybar/platform_profile.sh".source =
        config.lib.dotfiles.link "modules/desktop/waybar/platform_profile.sh";
    };


  };
}
