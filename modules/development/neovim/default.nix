{ inputs, ... }: {
  flake.nixosModules.neovim = {
    home-manager.users.braam = { config, lib, pkgs, ... }: {
      programs.neovim = {
        enable = true;
        package = inputs.neovim-nightly-overlay.packages.${pkgs.stdenv.hostPlatform.system}.default;
        defaultEditor = true;
        # Run the live config after Home Manager's plugin/runtime setup and
        # Stylix's colorscheme. The generated init.lua owns that ordering.
        initLua = lib.mkAfter ''
          dofile(vim.fn.stdpath("config") .. "/dotfiles.lua")
        '';
      };

      home.sessionVariables.VISUAL = "nvim";

      xdg.configFile."nvim/dotfiles.lua".source =
        config.lib.dotfiles.link "modules/development/neovim/init.lua";
    };
  };
}
