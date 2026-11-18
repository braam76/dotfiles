{ self, ... }: {
  flake.nixosModules.desktop = { pkgs, ... }: {
    imports = with self.nixosModules; [
      audio
      printing
      theme-generator
      plasma
      mango
      waybar
      alacritty
      firefox
      helium
      libreoffice
      flatpak
    ];

    # Native GTK/KDE settings live in home/.config.
    environment.systemPackages = [ pkgs.adw-gtk3 pkgs.mupdf ];
    xdg.mime.defaultApplications."application/pdf" = "mupdf.desktop";

    qt = {
      enable = true;
      platformTheme = "kde";
    };
  };
}
