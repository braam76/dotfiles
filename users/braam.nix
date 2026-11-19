{
  flake.nixosModules.braam = { pkgs, ... }: {
    users.users.braam = {
      isNormalUser = true;
      description = "Ilgar Gamidov";
      extraGroups = [ "networkmanager" "wheel" "libvirtd" ];
      shell = pkgs.zsh;
      packages = with pkgs; [ codex ];
    };
  };
}
