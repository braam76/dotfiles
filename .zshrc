typeset -U path fpath
export PNPM_HOME="$HOME/.local/share/pnpm"
path=("$PNPM_HOME/bin" "$HOME/.local/bin" $path)
export EDITOR=nvim
export VISUAL=nvim

(( $+functions[compdef] )) || { autoload -Uz compinit; compinit; }

if [[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
  source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
  ZSH_AUTOSUGGEST_STRATEGY=(history)
fi

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
if [[ "$TERM" != dumb ]]; then
  eval "$(starship init zsh)"
fi

alias ll='ls -l'
alias edit='sudo -e'

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
