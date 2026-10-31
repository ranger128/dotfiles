# [ PROMPT ]
eval "$(starship init zsh)"

# [ DOTS COMMAND ]
dots() {
  case "$1" in
    ""|-h|help) echo "dots: status | add <file> | save [msg] | sync | pkg [--cask] <name> | <git cmd>" ;;
    save) shift; dots add -u && dots commit -m "${*:-update}" && dots push origin HEAD ;;
    sync) dots pull origin HEAD && brew bundle --global ;;
    pkg)  shift; brew install "$@" && brew bundle add --global "$@" ;;
    *) git --git-dir="$HOME/.dots" --work-tree="$HOME" "$@" ;;
  esac
}
