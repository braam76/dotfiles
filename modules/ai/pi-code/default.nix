{
  flake.nixosModules.pi-code = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.pi-coding-agent ];

  };
}
