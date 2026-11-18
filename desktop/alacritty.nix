{
  flake.nixosModules.alacritty = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.alacritty ];
  };
}
