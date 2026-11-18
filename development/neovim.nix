{ inputs, ... }: {
  flake.nixosModules.neovim = { pkgs, ... }: {
    programs.neovim = {
      enable = true;
      package = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultEditor = true;
    };
    environment.sessionVariables.VISUAL = "nvim";
  };
}
