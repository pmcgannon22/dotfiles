alias ls='ls -F --color --show-control-chars'
alias less='less -r'

# CHEAT looks up help doc for command
cheat() {
  # Ask cheat.sh website for details about a Linux command.
  curl -m 10 "http://cheat.sh/${1}" 2>/dev/null || printf '%s\n' "[ERROR] Something broke"
}

alias c='cheat'