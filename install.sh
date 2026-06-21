#!/usr/bin/env bash
#
# dotfiles + one command setup for a fresh macOS machine
# Usage: bash install.sh
#
set -euo pipefail

# ANSI colours & helpers
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
B='\033[0;34m'
C='\033[0;36m'
NC='\033[0m'

info()  { echo -e "  ${Y}::${NC} $1"; }
ok()    { echo -e "  ${G}OK${NC}  $1"; }
warn()  { echo -e "  ${Y}!!${NC}  $1"; }
fail()  { echo -e "  ${Y}!!${NC}  $1"; }

section() {
  local label="$1"
  echo
  echo -e "${B}=>${NC} ${G}${label}${NC}"
}

# Spinner + prints an animated character while a command runs
# Usage:  spinner <title> <command>
spinner() {
  local title="$1"
  shift
  local pid=""
  local spin_chars='\/'
  local i=0

  # Run the command in the background
  "$@" >/dev/null 2>&1 &
  pid=$!

  # Show spinner while it runs
  while kill -0 "$pid" 2>/dev/null; do
    local ch="${spin_chars:$i:1}"
    printf "\r  ${Y}%s${NC} %s" "$ch" "$title"
    i=$(( (i + 1) % ${#spin_chars} ))
    sleep 0.1
  done

  # Wait for exit code
  wait "$pid"
  local rc=$?

  if [ $rc -eq 0 ]; then
    printf "\r  ${G}OK${NC}  %s\n" "$title"
  else
    printf "\r  ${Y}!!${NC}  %s\n" "$title"
    return $rc
  fi
}

# Idempotent helpers
dir_exists()  { [ -d "$1" ]; }
cmd_exists()  { command -v "$1" &>/dev/null; }

backup_link() {
  local src="$1" dst="$2"
  # If destination exists and is NOT a symlink, back it up
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "${dst}.bak"
    info "backed up ${dst} -> ${dst}.bak"
  fi
  ln -sf "$src" "$dst"
}

# 1. Xcode Command Line Tools
section "Xcode Command Line Tools"

if xcode-select -p &>/dev/null; then
  ok "already installed"
else
  info "installing (a dialog may appear + click Install)..."
  xcode-select --install 2>/dev/null || true
  info "please re-run install.sh after Xcode CLT finishes"
  exit 1
fi

# 2. Homebrew
section "Homebrew"

if cmd_exists brew; then
  ok "already installed"
else
  info "installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Put brew on PATH for the rest of the script
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
  fi
  ok "Homebrew installed"
fi

# 3. Brew bundle
section "Brew Bundle"

if [ -f "$HOME/.dotfiles/Brewfile" ]; then
  spinner "installing Homebrew packages..." \
    brew bundle --file="$HOME/.dotfiles/Brewfile" --no-lock
else
  warn "Brewfile not found, skipping"
fi

# 4. Oh My Zsh
section "Oh My Zsh"

if dir_exists "$HOME/.oh-my-zsh"; then
  ok "already installed"
else
  RUNZSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  ok "Oh My Zsh installed"
fi

# 5. Powerlevel10k (via git + the brew formula doesn't place it for OMZ)
section "Powerlevel10k"

P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if dir_exists "$P10K_DIR"; then
  ok "already installed"
else
  spinner "cloning Powerlevel10k..." \
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
fi

# 6. Zsh plugins
section "Zsh Plugins"

ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_omz_plugin() {
  local name="$1" repo="$2"
  local dir="$ZSH_CUSTOM/plugins/$name"
  if dir_exists "$dir"; then
    ok "$name already installed"
  else
    spinner "installing $name..." git clone --depth=1 "$repo" "$dir"
  fi
}

install_omz_plugin "zsh-autosuggestions" \
  "https://github.com/zsh-users/zsh-autosuggestions"

install_omz_plugin "zsh-syntax-highlighting" \
  "https://github.com/zsh-users/zsh-syntax-highlighting"

# 7. GNU Stow + symlink configs into $HOME
section "Symlink Configs"

# Stow handles zsh/ and git/ because they mirror $HOME structure
cd "$HOME/.dotfiles"

for pkg in zsh git; do
  if [ -d "$pkg" ]; then
    spinner "stow: $pkg" stow --adopt -t "$HOME" "$pkg"
    ok "linked $pkg"
  else
    warn "skipping $pkg (not found)"
  fi
done

# Ghostty + non standard path + manual symlink
GHOSTTY_DST="$HOME/Library/Application Support/com.mitchellh.ghostty"
if [ -f "$HOME/.dotfiles/ghostty/config" ]; then
  mkdir -p "$GHOSTTY_DST"
  backup_link "$HOME/.dotfiles/ghostty/config" "$GHOSTTY_DST/config"
  ok "linked ghostty/config"
fi

# VS Code
VSCODE_DST="$HOME/Library/Application Support/Code/User"
if [ -f "$HOME/.dotfiles/vscode/settings.json" ]; then
  mkdir -p "$VSCODE_DST"
  backup_link "$HOME/.dotfiles/vscode/settings.json" "$VSCODE_DST/settings.json"
  ok "linked vscode/settings.json"
fi

# 8. VS Code extensions
section "VS Code Extensions"

if cmd_exists code && [ -f "$HOME/.dotfiles/vscode/extensions.txt" ]; then
  info "installing extensions..."
  grep -v '^#' "$HOME/.dotfiles/vscode/extensions.txt" \
    | grep -v '^$' \
    | while IFS= read -r ext; do
        if [ -n "$ext" ]; then
          spinner "  installing $ext" code --install-extension "$ext" --force
        fi
      done
else
  warn "'code' CLI not found or extensions.txt missing; skipping VS Code extensions"
fi

# 9. macOS system defaults
section "macOS Defaults"

if [ -f "$HOME/.dotfiles/macos/defaults.sh" ]; then
  spinner "applying macOS defaults..." bash "$HOME/.dotfiles/macos/defaults.sh"
  ok "defaults applied"
else
  info "no macos/defaults.sh found; skipping"
fi

# Done
echo
echo -e "${Y}  All done.${NC}"
echo -e "  ${Y}::${NC} Start a new shell:  ${B}exec zsh${NC}"
echo
