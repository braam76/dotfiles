{
  flake.nixosModules.alacritty = {
    home-manager.users.braam = {
      # Stylix supplies colors and the shared dotfiles.font settings.
      programs.alacritty = {
        enable = true;
        # Send Shift+Enter distinctly, including through tmux, for Pi's newline.
        settings.keyboard.bindings = [
          {
            key = "Return";
            mods = "Shift";
            chars = builtins.fromJSON ''"\u001b[13;2u"'';
          }
        ];
      };
      stylix.targets.alacritty.enable = true;
    };
  };
}
