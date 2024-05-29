alias ls='ls -Fa --color --show-control-chars'
alias less='less -r'

export CLICOLOR=1

# Use cheat.sh
cheat() {
  # Ask cheat.sh website for details about a Linux command.
  curl -m 10 "http://cheat.sh/${1}" 2>/dev/null || printf '%s\n' "[ERROR] Something broke"
}

alias c='cheat'
ls-tree() {
    local dir="${1:-.}"
    find "$dir" | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"
}
