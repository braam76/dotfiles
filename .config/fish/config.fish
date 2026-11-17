set -gx EDITOR nvim
set -gx VISUAL nvim
fish_add_path "$HOME/.local/bin"

if status is-interactive
    set -g fish_greeting

    alias ll 'ls -l'
    alias edit 'sudo -e'
    alias snr-switch 'sudo nixos-rebuild switch --flake ~/dotfiles --impure'
    alias snr-update 'sudo nixos-rebuild switch --flake ~/dotfiles --impure --update'

    zoxide init fish | source
    direnv hook fish | source
    if test "$TERM" != dumb
        starship init fish | source
    end
end
