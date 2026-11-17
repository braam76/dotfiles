{ self, ... }: {
  flake.nixosModules.development = { pkgs, ... }: {
    imports = with self.nixosModules; [
      neovim
      emacs
      vscode
      languages
      docker
      qemu
    ];

    environment.systemPackages = with pkgs; [ devenv direnv nix-direnv ];
    environment.pathsToLink = [ "/share/nix-direnv" ];
  };
}
