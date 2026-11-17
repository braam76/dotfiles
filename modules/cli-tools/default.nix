{ self, ... }: {
  flake.nixosModules.cli-tools = { pkgs, ... }: {
    imports = with self.nixosModules; [
      zsh
      fish
      git
      yazi
      tmux
    ];

    environment.systemPackages = with pkgs; [ wget curl btop stow starship ];
  };
}
