{
  flake.nixosModules.networking = {
    networking.networkmanager.enable = true;
    networking.hosts."192.168.1.210" = [ 
      "git.river.local" 
      "vaultwarden.river.local"
    ];
  };
}
