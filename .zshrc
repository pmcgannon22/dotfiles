# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Skip compaudit prompts that would otherwise disable completions
export ZSH_DISABLE_COMPFIX="true"

# Set name of the theme to load
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="robbyrussell"

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Add wisely, as too many plugins slow down shell startup.
plugins=(git z zsh-autosuggestions zsh-history-substring-search zsh-syntax-highlighting you-should-use)

source $ZSH/oh-my-zsh.sh

# User configuration

# history setup
setopt APPEND_HISTORY
setopt SHARE_HISTORY
HISTFILE=$HOME/.zhistory
SAVEHIST=1000
HISTSIZE=999
setopt HIST_EXPIRE_DUPS_FIRST
setopt EXTENDED_HISTORY

# PROMPT
autoload -Uz colors && colors
PROMPT='%F{yellow}➜%f  %{$fg[cyan]%}%~%{$reset_color%} $(git_prompt_info)'

# Bind arrow keys for auto-completion menu navigation
if (( $+functions[history-substring-search-up] )); then
  bindkey '^[[A' history-substring-search-up
  bindkey '^[[B' history-substring-search-down
else
  bindkey '^[[A' up-line-or-history
  bindkey '^[[B' down-line-or-history
fi
bindkey '^[[C' forward-char
bindkey '^[[D' backward-char

# Completion configuration
zstyle ':completion:*' completer _complete _ignored
zstyle ':completion:*' list-colors ''
zstyle ':completion:*' matcher-list 'm:{[:lower:]}={[:upper:]}' '' '' '+'
zstyle ':completion:*' menu select=1
zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s

# Initialize autocompletion (skip secure-dir checks so completion never aborts)
if ! typeset -p _comps > /dev/null 2>&1; then
  autoload -Uz compinit
  compinit -u
fi

# Set the suggestion color to a more visible option (e.g., light gray)
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=#808080'

# fzf integration
if [ -f "$HOME/.fzf.zsh" ]; then
  source "$HOME/.fzf.zsh"
else
  if command -v brew > /dev/null 2>&1; then
    _dotfiles_fzf_dir="$(brew --prefix 2>/dev/null)/opt/fzf"
    [ -r "${_dotfiles_fzf_dir}/shell/key-bindings.zsh" ] && source "${_dotfiles_fzf_dir}/shell/key-bindings.zsh"
    [ -r "${_dotfiles_fzf_dir}/shell/completion.zsh" ] && source "${_dotfiles_fzf_dir}/shell/completion.zsh"
  fi
  for _fzf_binding in /usr/share/fzf/key-bindings.zsh /usr/local/share/fzf/key-bindings.zsh; do
    [ -r "$_fzf_binding" ] && source "$_fzf_binding"
  done
  for _fzf_completion in /usr/share/fzf/completion.zsh /usr/local/share/fzf/completion.zsh; do
    [ -r "$_fzf_completion" ] && source "$_fzf_completion"
  done
  unset _dotfiles_fzf_dir _fzf_binding _fzf_completion
  if command -v fzf > /dev/null 2>&1; then
    source <(fzf --zsh) 2>/dev/null || true
  fi
fi

# Note: ls aliases are defined at the end of this file
# to override oh-my-zsh plugin behavior

# Retain colors with less
alias less='less -r'

# Enable colored output in general
export CLICOLOR=1

# Pretty tree alias using find and sed
alias tree="find . -print | sed -e 's;[^/]*/;|____;g;s;____|; |;g'"

# Use cheat.sh
# Usage: cheat <command>
function cheat() {
  curl -m 10 "http://cheat.sh/${1}" 2>/dev/null || printf '%s\n' "[ERROR] Something broke"
}

# Short alias for cheat
alias c='cheat'

# Pretty tree-like directory listing using find and sed
# Usage: ls-tree [directory]
function ls-tree() {
  local dir="${1:-.}"
  find "$dir" | sed -e "s/[^-][^\/]*\//  |/g" -e "s/|\([^ ]\)/|-\1/"
}

# kubectl autocomplete (only if kubectl is installed)
if [[ $commands[kubectl] ]]; then
  source <(kubectl completion zsh)
fi

# ============================================================
# NAVIGATION ALIASES
# ============================================================
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'

# ============================================================
# SAFETY NET ALIASES
# ============================================================
alias rm='rm -i'    # Confirm before deleting
alias cp='cp -i'    # Confirm before overwriting
alias mv='mv -i'    # Confirm before overwriting

# ============================================================
# ENHANCED LISTING ALIASES
# ============================================================
# Note: ll, la, lt aliases are defined at the end of this file
# to override oh-my-zsh plugin behavior

# ============================================================
# SYSTEM SHORTCUTS
# ============================================================
alias myip='curl http://ipecho.net/plain; echo'
alias ports='netstat -tulanp'
alias psg='ps aux | grep -v grep | grep -i -e VSZ -e'  # Quick process search

# ============================================================
# QUICK EDITS
# ============================================================
alias zshconfig='vim ~/.zshrc'
reload() {
  source "$HOME/.zshrc"
}

# ============================================================
# UTILITY FUNCTIONS
# ============================================================

# Create directory and cd into it
# Usage: mkcd directory_name
function mkcd() {
  mkdir -p "$1" && cd "$1"
}

# Extract any archive type
# Usage: extract archive_file
function extract() {
  if [ -f "$1" ]; then
    case "$1" in
      *.tar.gz)  tar xzf "$1"   ;;
      *.tar.bz2) tar xjf "$1"   ;;
      *.tar)     tar xf "$1"    ;;
      *.tbz2)    tar xjf "$1"   ;;
      *.tgz)     tar xzf "$1"   ;;
      *.zip)     unzip "$1"     ;;
      *.rar)     unrar x "$1"   ;;
      *.7z)      7z x "$1"      ;;
      *.gz)      gunzip "$1"    ;;
      *.bz2)     bunzip2 "$1"   ;;
      *.Z)       uncompress "$1";;
      *)         echo "Error: '$1' - unknown archive type" ;;
    esac
  else
    echo "Error: '$1' is not a valid file"
  fi
}

# ============================================================
# RE-APPLY CUSTOM ALIASES
# ============================================================
# zsh-syntax-highlighting captures aliases when oh-my-zsh loads,
# then restores them, which can override our custom aliases.
# Re-define them here to ensure they take precedence.

# Detect macOS vs. other (e.g., Linux/Ubuntu) and set ls aliases
if [[ "$OSTYPE" == "darwin"* ]]; then
  # macOS uses BSD ls, which needs -G for color
  alias ls='command ls -FG'
  alias ll='command ls -lhFG'
  alias la='command ls -lAhFG'
  alias lt='command ls -lhtrFG'
else
  # Linux (GNU ls) commonly uses --color=auto
  alias ls='command ls -F --color=auto'
  alias ll='command ls -lhF --color=auto'
  alias la='command ls -lAhF --color=auto'
  alias lt='command ls -lhtrF --color=auto'
fi
