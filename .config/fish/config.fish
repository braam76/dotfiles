set -gx EDITOR nvim
set -gx VISUAL nvim
fish_add_path "$HOME/.local/bin"

if status is-interactive
    set -g fish_greeting

    # Refresh generated colors on the next prompt, without restarting the shell.
    function __dotfiles_theme_reload --on-event fish_prompt
        set -l theme "$HOME/.config/fish/conf.d/vague.fish"
        set -l stamp (stat -c %y -- "$theme" 2>/dev/null)
        if test -n "$stamp"; and test "$stamp" != "$__dotfiles_theme_stamp"
            source "$theme"
            set -g __dotfiles_theme_stamp "$stamp"
        end
    end

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
