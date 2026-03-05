#!/bin/bash
set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

step() { echo -e "\n${GREEN}[$1]${NC}"; }
warn() { echo -e "${YELLOW}WARNING: $1${NC}"; }

# 1. Xcode CLT
step "Checking Xcode Command Line Tools"
if ! xcode-select -p &>/dev/null; then
  xcode-select --install
  echo "Please install Xcode CLT first, then re-run this script."
  exit 1
fi
echo "Already installed"

# 2. Homebrew
step "Checking Homebrew"
if ! command -v brew &>/dev/null; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
else
  echo "Already installed"
fi

# 3. Brew Bundle
step "Installing from Brewfile"
brew bundle --file="$HOME/.dotfiles/Brewfile"

# 4. Oh My Zsh
step "Checking Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
else
  echo "Already installed"
fi

# 5. Powerlevel10k
step "Checking Powerlevel10k"
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  echo "Already installed"
fi

# 6. Stow
step "Symlinking dotfiles"
cd "$HOME/.dotfiles"
stow zsh
stow git
stow ghostty

# 7. VS Code
step "Setting up VS Code"
VSCODE_DIR="$HOME/Library/Application Support/Code/User"
if command -v code &>/dev/null; then
  ln -sf "$HOME/.dotfiles/vscode/settings.json" "$VSCODE_DIR/settings.json"
  grep -v "^#" "$HOME/.dotfiles/vscode/extensions.txt" | grep -v "^$" | xargs -L 1 code --install-extension
else
  warn "VS Code 'code' CLI not found. Open VS Code -> Cmd+Shift+P -> 'Shell Command: Install code in PATH'"
fi

echo -e "\n${GREEN}Done. Run: exec zsh${NC}"
