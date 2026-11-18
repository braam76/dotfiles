{
  flake.nixosModules.tmux = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.tmux ];
  };
}
