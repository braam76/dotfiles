{
  flake.nixosModules.yazi = { pkgs, ... }: {
    # The nixpkgs wrapper supplies Yazi's preview dependencies.
    environment.systemPackages = with pkgs; [ yazi zoxide wl-clipboard ];
  };
}
