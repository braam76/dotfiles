{
  flake.nixosModules.emacs = { config, ... }: {
    environment.systemPackages = [
      config.home-manager.users.braam.programs.emacs.finalPackage
    ];

    home-manager.users.braam = { config, pkgs, ... }: {
      programs.emacs = {
        enable = true;
        package = pkgs.emacs-pgtk;
      };

      stylix.targets.emacs.enable = true;

      xdg.configFile."emacs/early-init.el".source =
        config.lib.dotfiles.link "modules/development/emacs/early-init.el";

      xdg.configFile."emacs/init.el".source =
        config.lib.dotfiles.link "modules/development/emacs/init.el";
    };
  };
}
