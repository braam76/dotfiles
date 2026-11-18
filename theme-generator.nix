{
  perSystem = { pkgs, ... }: {
    devShells.theme-generator = pkgs.mkShell {
      packages = [ (pkgs.python3.withPackages (ps: [ ps.jinja2 ])) ];
    };
  };

  flake.nixosModules.theme-generator = { config, pkgs, ... }: let
    python = pkgs.python3.withPackages (ps: [ ps.jinja2 ]);
    root = "/home/braam/dotfiles/theme-generator";
  in {
    environment.systemPackages = [
      (pkgs.writeShellScriptBin "theme-render" ''
        exec ${python}/bin/python ${root}/render.py "$@"
      '')
    ];

    systemd.user.services.theme-generator = {
      description = "Render native themes from the shared JSON palette";
      wantedBy = [ "default.target" ];
      path = [ pkgs.procps pkgs.tmux pkgs.mako config.programs.mango.package ];
      serviceConfig = {
        Type = "simple";
        WorkingDirectory = root;
        ExecStart = "${python}/bin/python ${root}/render.py --watch";
        Restart = "on-failure";
        RestartSec = 2;
        UMask = "0022";
        NoNewPrivileges = true;
      };
      # This is a system-wide user unit; run it only for the dotfiles owner.
      unitConfig.ConditionUser = "braam";
    };
  };
}
