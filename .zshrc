# [ PROMPT ]
eval "$(starship init zsh)"

# [ DOTS COMMAND ]
dots() {
  case "$1" in
    ""|-h|help) echo "dots: status | list | add <file> | save [msg] | sync | pkg [--cask] <name> | <git cmd>" ;;
    list) dots ls-files --full-name :/ ;;
    save) shift; dots add -u && dots commit -m "${*:-update}" && dots push origin HEAD ;;
    sync) dots pull origin HEAD && brew bundle --global ;;
    pkg)  shift; brew install "$@" && brew bundle add --global "$@" ;;
    *) git --git-dir="$HOME/.dots" --work-tree="$HOME" "$@" ;;
  esac
}

# [ ALIASES ]
alias lazyvim='NVIM_APPNAME=lazyvim nvim'
alias minimax='NVIM_APPNAME=nvim-minimax nvim'
alias kickstart='NVIM_APPNAME=kickstart-nvim nvim'
alias old-nvim='NVIM_APPNAME=old-nvim nvim'
alias cmini='NVIM_APPNAME=minimax-custom nvim'
