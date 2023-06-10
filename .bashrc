#ensure hidden files shown
alias ls='ls -a'

# Use cheat.sh
cheat() {
  # Ask cheat.sh website for details about a Linux command.
  curl -m 10 "http://cheat.sh/${1}" 2>/dev/null || printf '%s\n' "[ERROR] Something broke"
}

ls-tree() {
    local dir="${1:-.}"
    find "$dir" | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"
}
