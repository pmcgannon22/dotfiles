if command -v fzf > /dev/null 2>&1; then
  source <(fzf --zsh)
fi

alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"

