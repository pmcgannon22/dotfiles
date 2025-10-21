#!/usr/bin/env bash

set -euo pipefail
IFS=$'\n\t'

################################################################################
# ZSH Setup Installation Script
################################################################################
# This script automates the installation of Oh My Zsh and all related plugins
# and configurations for a productive development environment.
#
# Compatible with:
#   - macOS (Darwin)
#   - WSL2 Ubuntu (Linux)
#
# What this script does:
#   1. Checks if zsh is installed (required prerequisite)
#   2. Installs Oh My Zsh framework
#   3. Installs productivity-enhancing plugins:
#      - zsh-autosuggestions: Suggests commands as you type based on history
#      - zsh-history-substring-search: Search history with arrow keys
#      - zsh-syntax-highlighting: Highlights valid (green) vs invalid (red) commands
#      - you-should-use: Reminds you of aliases you forgot to use
#   4. Backs up your existing .zshrc (if present)
#   5. Copies the custom .zshrc configuration to your home directory
#
# Prerequisites:
#   - zsh must be installed
#   - git must be installed
#   - curl must be installed
#
# Usage:
#   chmod +x install-zsh-setup.sh
#   ./install-zsh-setup.sh
################################################################################

# Color codes for prettier output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

################################################################################
# Platform detection & package management helpers
################################################################################

OS_FAMILY=""
PACKAGE_MANAGER=""
APT_UPDATED="false"

detect_platform() {
    local uname_out
    uname_out="$(uname -s)"
    case "$uname_out" in
        Darwin)
            OS_FAMILY="macOS"
            if command -v brew >/dev/null 2>&1; then
                PACKAGE_MANAGER="brew"
            else
                print_warning "Homebrew is not installed. Automatic package installation will be skipped."
                print_warning "Install Homebrew from https://brew.sh to let this script manage dependencies."
            fi
            ;;
        Linux)
            if [ -r /etc/os-release ]; then
                # shellcheck disable=SC1091
                . /etc/os-release
                if [[ "${ID:-}" == "ubuntu" || "${ID_LIKE:-}" == *"ubuntu"* || "${ID_LIKE:-}" == *"debian"* ]]; then
                    OS_FAMILY="Ubuntu"
                    if command -v apt-get >/dev/null 2>&1; then
                        PACKAGE_MANAGER="apt"
                    else
                        print_warning "apt-get is not available. Automatic package installation will be skipped."
                    fi
                else
                    OS_FAMILY="${ID:-Linux}"
                    print_warning "This script is optimized for Ubuntu. Detected ID=${ID:-unknown}."
                    print_warning "Automatic package installation may not work; install prerequisites manually."
                fi
            else
                OS_FAMILY="Linux"
                print_warning "Unable to read /etc/os-release. Automatic package installation may not work."
            fi
            ;;
        *)
            OS_FAMILY="$uname_out"
            print_warning "Unsupported OS detected: $uname_out"
            print_warning "This script is tested on macOS and Ubuntu. Proceed with caution."
            ;;
    esac
}

ensure_command() {
    local cmd="$1"
    local brew_pkg="${2:-$1}"
    local apt_pkg="${3:-$2}"

    if command -v "$cmd" >/dev/null 2>&1; then
        print_success "$cmd is installed: $(command -v "$cmd")"
        return
    fi

    case "$PACKAGE_MANAGER" in
        brew)
            print_info "Installing ${brew_pkg} via Homebrew..."
            brew install "$brew_pkg"
            ;;
        apt)
            if [[ "$APT_UPDATED" == "false" ]]; then
                print_info "Updating apt package index (requires sudo)..."
                sudo apt-get update
                APT_UPDATED="true"
            fi
            print_info "Installing ${apt_pkg} via apt (requires sudo)..."
            sudo apt-get install -y "$apt_pkg"
            ;;
        *)
            print_error "$cmd is not installed and cannot be installed automatically."
            echo "Please install it manually and re-run this script."
            exit 1
            ;;
    esac

    if command -v "$cmd" >/dev/null 2>&1; then
        print_success "$cmd installed successfully: $(command -v "$cmd")"
    else
        print_error "Failed to install $cmd. Please install it manually and re-run this script."
        exit 1
    fi
}

################################################################################
# Step 0: Detect Platform
################################################################################

print_info "Detecting platform..."
detect_platform
if [[ -n "$OS_FAMILY" ]]; then
    print_success "Detected platform: $OS_FAMILY"
else
    print_warning "Unable to determine platform automatically."
fi

################################################################################
# Step 1: Check Prerequisites
################################################################################

print_info "Checking prerequisites..."

# Check if zsh is installed
ensure_command "zsh"

# Check if git is installed
ensure_command "git"

# Check if curl is installed
ensure_command "curl"

################################################################################
# Step 2: Install Oh My Zsh
################################################################################

print_info "Checking for existing Oh My Zsh installation..."

if [ -d "$HOME/.oh-my-zsh" ]; then
    print_warning "Oh My Zsh is already installed at $HOME/.oh-my-zsh"
    reinstall_response=""
    read -r -n 1 -p "Do you want to reinstall Oh My Zsh? This will backup the existing installation. (y/N): " reinstall_response
    echo
    if [[ "$reinstall_response" =~ ^[Yy]$ ]]; then
        print_info "Backing up existing Oh My Zsh installation..."
        mv "$HOME/.oh-my-zsh" "$HOME/.oh-my-zsh.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "Backup created"
    else
        print_info "Skipping Oh My Zsh installation"
    fi
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
    print_info "Installing Oh My Zsh..."
    # Oh My Zsh is a framework for managing zsh configuration
    # It provides themes, plugins, and helpful defaults
    # --unattended flag prevents it from changing your shell automatically
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    print_success "Oh My Zsh installed successfully"
fi

################################################################################
# Step 3: Install Plugins
################################################################################

print_info "Installing Oh My Zsh plugins..."

# Define the custom plugins directory
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

# Plugin 1: zsh-autosuggestions
# This plugin suggests commands as you type based on your command history
# Press the right arrow key to accept the suggestion
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    print_info "Installing zsh-autosuggestions..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
    print_success "zsh-autosuggestions installed"
else
    print_warning "zsh-autosuggestions already installed, skipping"
fi

# Plugin 2: zsh-history-substring-search
# This plugin allows you to search through your command history by typing
# a substring and using the up/down arrow keys to navigate matches
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-history-substring-search" ]; then
    print_info "Installing zsh-history-substring-search..."
    git clone https://github.com/zsh-users/zsh-history-substring-search "$ZSH_CUSTOM/plugins/zsh-history-substring-search"
    print_success "zsh-history-substring-search installed"
else
    print_warning "zsh-history-substring-search already installed, skipping"
fi

# Plugin 3: zsh-syntax-highlighting
# This plugin highlights commands in real-time:
#   - Green = valid command
#   - Red = invalid command or typo
# This helps catch errors before you press Enter
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    print_info "Installing zsh-syntax-highlighting..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
    print_success "zsh-syntax-highlighting installed"
else
    print_warning "zsh-syntax-highlighting already installed, skipping"
fi

# Plugin 4: you-should-use
# This plugin reminds you when you type a full command but have an alias for it
# Helps you build muscle memory for your aliases and shortcuts
if [ ! -d "$ZSH_CUSTOM/plugins/you-should-use" ]; then
    print_info "Installing you-should-use..."
    git clone https://github.com/MichaelAquilina/zsh-you-should-use.git "$ZSH_CUSTOM/plugins/you-should-use"
    print_success "you-should-use installed"
else
    print_warning "you-should-use already installed, skipping"
fi

################################################################################
# Step 3.5: Ensure supporting tools
################################################################################

print_info "Ensuring fzf (fuzzy finder) is installed..."
if command -v fzf >/dev/null 2>&1; then
    print_success "fzf is already installed: $(command -v fzf)"
else
    if [[ "$PACKAGE_MANAGER" == "brew" || "$PACKAGE_MANAGER" == "apt" ]]; then
        ensure_command "fzf"
    else
        print_warning "fzf is not installed and cannot be installed automatically."
        print_warning "Install fzf manually to enable fuzzy finder shortcuts used in .zshrc."
    fi
fi

if [[ "$PACKAGE_MANAGER" == "brew" ]]; then
    FZF_PREFIX="$(brew --prefix 2>/dev/null)/opt/fzf"
    if [ -x "$FZF_PREFIX/install" ]; then
        print_info "Running fzf install script to set up key bindings and completion..."
        "$FZF_PREFIX/install" --key-bindings --completion --no-update-rc >/dev/null
        print_success "fzf shell integrations installed"
    fi
fi

################################################################################
# Step 4: Install .zshrc Configuration
################################################################################

print_info "Setting up .zshrc configuration..."

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if .zshrc exists in the dotfiles directory
if [ ! -f "$SCRIPT_DIR/.zshrc" ]; then
    print_error "Cannot find .zshrc in $SCRIPT_DIR"
    print_error "Please ensure .zshrc is in the same directory as this script"
    exit 1
fi

# Backup existing .zshrc if it exists
if [ -f "$HOME/.zshrc" ] || [ -L "$HOME/.zshrc" ]; then
    BACKUP_FILE="$HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    print_warning "Backing up existing .zshrc to $BACKUP_FILE"
    cp "$HOME/.zshrc" "$BACKUP_FILE"
fi

# Copy the custom .zshrc reference to home directory
print_info "Linking custom .zshrc from repository"
cat > "$HOME/.zshrc" <<EOF
# Managed by install-zsh-setup.sh on $(date)
# Keep this file lightweight so the repository version stays the single source of truth.
source "$SCRIPT_DIR/.zshrc"
EOF
print_success "Created $HOME/.zshrc that sources $SCRIPT_DIR/.zshrc"

################################################################################
# Step 5: Optional - Change Default Shell to Zsh
################################################################################

print_info "Checking current shell..."
CURRENT_SHELL=$(basename "$SHELL")

if [ "$CURRENT_SHELL" != "zsh" ]; then
    print_warning "Your current shell is $CURRENT_SHELL, not zsh"
    echo ""
    change_shell_response=""
    read -r -n 1 -p "Would you like to change your default shell to zsh? (y/N): " change_shell_response
    echo
    if [[ "$change_shell_response" =~ ^[Yy]$ ]]; then
        # Get the path to zsh
        ZSH_PATH=$(command -v zsh)

        # Check if zsh is in /etc/shells (required on macOS)
        if ! grep -q "$ZSH_PATH" /etc/shells; then
            print_info "Adding $ZSH_PATH to /etc/shells (requires sudo)..."
            echo "$ZSH_PATH" | sudo tee -a /etc/shells
        fi

        print_info "Changing default shell to zsh (requires password)..."
        chsh -s "$ZSH_PATH"
        print_success "Default shell changed to zsh"
        print_warning "You'll need to log out and log back in for the change to take effect"
    else
        print_info "Keeping current shell: $CURRENT_SHELL"
        print_info "You can manually change your shell later by running: chsh -s \$(which zsh)"
    fi
else
    print_success "Your default shell is already zsh"
fi

################################################################################
# Step 6: Summary and Next Steps
################################################################################

echo ""
echo "================================================================================"
print_success "Installation complete!"
echo "================================================================================"
echo ""
echo "What was installed:"
echo "  ✓ Oh My Zsh framework with the robbyrussell theme"
echo "  ✓ zsh-autosuggestions plugin (command suggestions as you type)"
echo "  ✓ zsh-history-substring-search plugin (search history with arrow keys)"
echo "  ✓ zsh-syntax-highlighting plugin (green=valid, red=invalid commands)"
echo "  ✓ you-should-use plugin (reminds you of available aliases)"
echo "  ✓ fzf fuzzy finder (plus shell key bindings/completion when supported)"
echo "  ✓ ~/.zshrc that sources the repository version, keeping config centralized"
echo "  ✓ Custom configuration highlights:"
echo "      - git, z, navigation, safety, and listing aliases"
echo "      - Utility functions (mkcd, extract, cheat, ls-tree)"
echo "      - System helpers (myip, ports, psg)"
echo "      - macOS/Linux aware ls color settings"
echo ""
echo "Next steps:"
echo "  1. Start a new terminal session or run: source ~/.zshrc"
echo "  2. Try typing a command - you'll see syntax highlighting!"
echo "  3. Try 'z' to jump to frequently visited directories"
echo "  4. Use 'mkcd test' to create and enter a directory"
echo "  5. Type 'extract file.zip' to extract any archive type"
echo "  6. Run 'cheat ls' to get a quick cheatsheet for any command"
echo ""
if [ "$CURRENT_SHELL" != "zsh" ] && [[ ! ${change_shell_response:-} =~ ^[Yy]$ ]]; then
    print_warning "Remember to change your default shell to zsh for the best experience"
    echo "  Run: chsh -s \$(which zsh)"
fi
echo ""
echo "================================================================================"
