{
  flake.nixosModules.emacs = { pkgs, ... }: {
    environment.systemPackages = [ pkgs.emacs-pgtk ];
  };
}
