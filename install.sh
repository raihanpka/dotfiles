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

# 6. Zsh plugins
step "Checking Zsh plugins"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
else
  echo "zsh-autosuggestions already installed"
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
else
  echo "zsh-syntax-highlighting already installed"
fi

# 7. Stow
step "Symlinking dotfiles"
cd "$HOME/.dotfiles"

# backup if file exists and is not already a symlink
backup_if_exists() {
  if [ -f "$1" ] && [ ! -L "$1" ]; then
    mv "$1" "$1.bak"
    echo "Backed up $1 -> $1.bak"
  fi
}

backup_if_exists "$HOME/.zshrc"
backup_if_exists "$HOME/.p10k.zsh"
backup_if_exists "$HOME/.gitconfig"

stow zsh
stow git
# ghostty — manual link (non-standard path)
  GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
  mkdir -p "$GHOSTTY_DIR"
  [ -f "$GHOSTTY_DIR/config" ] && [ ! -L "$GHOSTTY_DIR/config" ] && mv "$GHOSTTY_DIR/config" "$GHOSTTY_DIR/config.bak"
  ln -sf "$HOME/.dotfiles/ghostty/config" "$GHOSTTY_DIR/config"
  echo "Ghostty config linked"
echo "Symlinks created"

# 8. VS Code
step "Setting up VS Code"
VSCODE_DIR="$HOME/Library/Application Support/Code/User"
mkdir -p "$VSCODE_DIR"
if command -v code &>/dev/null; then
  [ -f "$VSCODE_DIR/settings.json" ] && [ ! -L "$VSCODE_DIR/settings.json" ] && mv "$VSCODE_DIR/settings.json" "$VSCODE_DIR/settings.json.bak"
  ln -sf "$HOME/.dotfiles/vscode/settings.json" "$VSCODE_DIR/settings.json"
  echo "Installing VS Code extensions..."
  grep -v "^#" "$HOME/.dotfiles/vscode/extensions.txt" | grep -v "^$" | xargs -L 1 code --install-extension
else
  warn "VS Code 'code' CLI not found. Open VS Code -> Cmd+Shift+P -> 'Shell Command: Install code in PATH'"
fi

# 9. macOS defaults
step "Applying macOS defaults"
if [ -f "$HOME/.dotfiles/macos/defaults.sh" ]; then
  bash "$HOME/.dotfiles/macos/defaults.sh"
else
  warn "macos/defaults.sh not found, skipping"
fi

echo -e "\n${GREEN}Done. Run: exec zsh${NC}"