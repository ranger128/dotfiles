# [ PROMPT ]
eval "$(starship init zsh)"

# [ DOTS COMMAND ]
dots() {
  case "$1" in
    ""|-h|help) echo "dots: status | list | add <file> | save [msg] | sync | pkg [--cask] <name> | <git cmd>" ;;
    list) dots ls-files --full-name :/ ;;
    save) shift; dots add -u && dots commit -m "${*:-update}" && dots push origin HEAD ;;
    sync) dots pull origin HEAD && { brew bundle check --global --no-upgrade --quiet || brew bundle --global --no-upgrade; } ;;
    pkg)  shift; brew install "$@" && brew bundle add --global "$@" ;;
    *) git --git-dir="$HOME/.dots" --work-tree="$HOME" "$@" ;;
  esac
}

# [ ALIASES ]
alias cmini='NVIM_APPNAME=minimax-custom nvim'
alias ls='eza --color always'

# test
