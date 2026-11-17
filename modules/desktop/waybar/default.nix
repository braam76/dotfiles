{
  flake.nixosModules.waybar = { config, pkgs, ... }: {
    programs.waybar.enable = true;

    # The user service does not inherit the interactive shell PATH.
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
      pkgs.walker
      pkgs.bash
      config.programs.mango.package
    ];

    environment.systemPackages = with pkgs; [
      python3 brightnessctl pavucontrol networkmanager_dmenu networkmanager
    ];
  };
}
