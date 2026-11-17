{
  flake.nixosModules.zsh = { pkgs, ... }: {
    programs.zsh.enable = true;
    environment.pathsToLink = [
      "/share/zsh-autosuggestions"
      "/share/zsh-syntax-highlighting"
    ];
    environment.systemPackages = with pkgs; [
      zsh-autosuggestions
      zsh-syntax-highlighting
    ];
  };
}
