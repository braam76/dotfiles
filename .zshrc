typeset -U path fpath
path=("$HOME/.local/bin" $path)
export EDITOR=nvim
export VISUAL=nvim

for profile in ${(z)NIX_PROFILES}; do
  fpath+=($profile/share/zsh/site-functions $profile/share/zsh/$ZSH_VERSION/functions $profile/share/zsh/vendor-completions)
done
# NixOS may already have initialized completion in its system zshrc.
(( $+functions[compdef] )) || { autoload -Uz compinit; compinit; }

source /run/current-system/sw/share/zsh-autosuggestions/zsh-autosuggestions.zsh
ZSH_AUTOSUGGEST_STRATEGY=(history)

HISTSIZE=10000
SAVEHIST=10000
HISTFILE="$HOME/.zsh_history"
setopt HIST_FCNTL_LOCK HIST_IGNORE_ALL_DUPS HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY

function y() {
  local tmp="$(mktemp -t yazi-cwd.XXXXX)" cwd
  command yazi "$@" --cwd-file="$tmp"
  cwd="$(<"$tmp")"
  if [[ -n "$cwd" && "$cwd" != "$PWD" ]]; then
    builtin cd -- "$cwd"
  fi
  rm -f -- "$tmp"
}

eval "$(zoxide init zsh)"
eval "$(direnv hook zsh)"
if [[ "$TERM" != dumb ]]; then
  eval "$(starship init zsh)"
fi

alias ll='ls -l'
alias edit='sudo -e'
alias snr-switch='sudo nixos-rebuild switch --flake ~/dotfiles --impure'
alias snr-update='sudo nixos-rebuild switch --flake ~/dotfiles --impure --update'

source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
ZSH_HIGHLIGHT_HIGHLIGHTERS=(main)
source ~/.config/zsh/theme.zsh

# Re-read the small generated palette only when its content changes.
autoload -Uz add-zsh-hook
function _dotfiles_theme_reload() {
  local theme="$HOME/.config/zsh/theme.zsh"
  [[ -r "$theme" ]] || return 0
  local content="$(<"$theme")"
  if [[ "$content" != "${_dotfiles_theme_content-}" ]]; then
    source "$theme"
    typeset -g _dotfiles_theme_content="$content"
  fi
}
add-zsh-hook precmd _dotfiles_theme_reload
