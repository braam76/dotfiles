{
  flake.nixosModules.vscode = { pkgs, ... }: {
    environment.systemPackages = [
      (pkgs.vscode-with-extensions.override {
        vscodeExtensions = [ pkgs.vscode-extensions.mkhl.direnv ];
      })
    ];
  };
}
