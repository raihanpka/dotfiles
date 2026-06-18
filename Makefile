# dotfiles + Makefile
#
# Common tasks:
#   make install       Full bootstrap (same as running install.sh)
#   make sync          Sync EVERY local config into this repo
#   make brew dump     Capture current Homebrew state into Brewfile
#   make brew sync     brew dump + brew bundle cleanup
#   make stow          Resymlink all stow packages
#   make doctor        Check that symlinks and key tools are healthy

SHELL := /bin/bash
DOTFILES := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
HOME_DIR := $(HOME)

# Colours (used in @printf statements)
G := \033[0;32m
C := \033[0;36m
Y := \033[1;33m
R := \033[0;31m
B := \033[0;34m
NC := \033[0m

.PHONY: help install sync brew-dump brew-sync stow doctor \
        sync-zsh sync-git sync-ghostty sync-vscode sync-brewfile \
        clean

help:
	@printf "\n"
	@printf "${B}dotfiles + available targets${NC}\n"
	@printf "\n"
	@printf "  ${G}install${NC}       Full bootstrap (runs install.sh)\n"
	@printf "  ${G}sync${NC}          Sync EVERY local config into this repo\n"
	@printf "  ${G}brew-dump${NC}     Write current brew state into Brewfile\n"
	@printf "  ${G}brew-sync${NC}     brew-dump + remove packages not in Brewfile\n"
	@printf "  ${G}stow${NC}          Resymlink all stow managed packages\n"
	@printf "  ${G}doctor${NC}        Health check symlinks and tools\n"
	@printf "  ${G}clean${NC}         Remove broken symlinks pointing to this repo\n"
	@printf "\n"
	@printf "  ${C}sync-zsh${NC}       Copy .zshrc and .p10k.zsh into repo\n"
	@printf "  ${C}sync-git${NC}       Copy .gitconfig into repo\n"
	@printf "  ${C}sync-ghostty${NC}   Copy ghostty config into repo\n"
	@printf "  ${C}sync-vscode${NC}    Copy VS Code settings + extensions into repo\n"
	@printf "  ${C}sync-brewfile${NC}  Alias for brew-dump\n"
	@printf "\n"

# Install
install:
	@printf "\n  ${C}::${NC} Running install.sh...\n\n"
	@bash "$(DOTFILES)/install.sh"

# Sync: copy live configs from $HOME into the repo
sync-zsh: SYNC_FILES += zsh/.zshrc zsh/.p10k.zsh
sync-zsh:
	@printf "  ${C}::${NC} Syncing Zsh configs...\n"
	@mkdir -p "$(DOTFILES)/zsh"
	@cp "$(HOME_DIR)/.zshrc" "$(DOTFILES)/zsh/.zshrc" 2>/dev/null && \
	  printf "  ${G}OK${NC}  .zshrc\n" || \
	  printf "  ${Y}!!${NC}  .zshrc not found, skipping\n"
	@cp "$(HOME_DIR)/.p10k.zsh" "$(DOTFILES)/zsh/.p10k.zsh" 2>/dev/null && \
	  printf "  ${G}OK${NC}  .p10k.zsh\n" || \
	  printf "  ${Y}!!${NC}  .p10k.zsh not found, skipping\n"

sync-git:
	@printf "  ${C}::${NC} Syncing Git config...\n"
	@mkdir -p "$(DOTFILES)/git"
	@cp "$(HOME_DIR)/.gitconfig" "$(DOTFILES)/git/.gitconfig" && \
	  printf "  ${G}OK${NC}  .gitconfig\n"

sync-ghostty:
	@printf "  ${C}::${NC} Syncing Ghostty config...\n"
	@mkdir -p "$(DOTFILES)/ghostty"
	@cp "$(HOME_DIR)/Library/Application Support/com.mitchellh.ghostty/config" \
	  "$(DOTFILES)/ghostty/config" && \
	  printf "  ${G}OK${NC}  ghostty/config\n" || \
	  printf "  ${Y}!!${NC}  ghostty config not found, skipping\n"

sync-vscode:
	@printf "  ${C}::${NC} Syncing VS Code configs...\n"
	@mkdir -p "$(DOTFILES)/vscode"
	@cp "$(HOME_DIR)/Library/Application Support/Code/User/settings.json" \
	  "$(DOTFILES)/vscode/settings.json" 2>/dev/null && \
	  printf "  ${G}OK${NC}  settings.json\n" || \
	  printf "  ${Y}!!${NC}  settings.json not found, skipping\n"
	@which code &>/dev/null && \
	  code --list-extensions > "$(DOTFILES)/vscode/extensions.txt" && \
	  printf "  ${G}OK${NC}  extensions.txt\n" || \
	  printf "  ${Y}!!${NC}  code CLI not found, skipping extensions\n"

sync-brewfile: brew-dump

sync: sync-zsh sync-git sync-ghostty sync-vscode brew-dump
	@printf "\n  ${G}All configs synced.${NC}\n"

# Brew
brew-dump:
	@printf "  ${C}::${NC} Dumping brew state into Brewfile...\n"
	@brew bundle dump --force --file="$(DOTFILES)/Brewfile" 2>/dev/null && \
	  printf "  ${G}OK${NC}  Brewfile updated\n" || \
	  printf "  ${Y}!!${NC}  brew not available, skipping\n"

brew-sync: brew-dump
	@printf "  ${C}::${NC} Removing packages not in Brewfile...\n"
	@brew bundle cleanup --force --file="$(DOTFILES)/Brewfile" && \
	  printf "  ${G}OK${NC}  cleaned up\n" || true

# Stow
STOW_PACKAGES := zsh git

stow:
	@printf "  ${C}::${NC} Re-stowing packages: $(STOW_PACKAGES)...\n"
	@cd "$(DOTFILES)" && \
	  for pkg in $(STOW_PACKAGES); do \
	    if [ -d "$$pkg" ]; then \
	      stow --adopt -t "$(HOME_DIR)" "$$pkg" 2>/dev/null; \
	      printf "  ${G}OK${NC}  stowed $$pkg\n"; \
	    fi; \
	  done; \
	  printf "  ${G}Done${NC}\n"

# Doctor
doctor:
	@printf "\n  ${C}::${NC} Checking symlink health...\n"
	@for f in \
	    "$(HOME_DIR)/.zshrc" \
	    "$(HOME_DIR)/.p10k.zsh" \
	    "$(HOME_DIR)/.gitconfig"; do \
	  if [ -L "$$f" ]; then \
	    printf "  ${G}OK${NC}  symlink: $$f\n"; \
	  elif [ -f "$$f" ]; then \
	    printf "  ${Y}!!${NC}  regular file (not symlink): $$f\n"; \
	  else \
	    printf "  ${R}!!${NC}  missing: $$f\n"; \
	  fi; \
	done
	@for d in \
	    "$(HOME_DIR)/Library/Application Support/com.mitchellh.ghostty/config" \
	    "$(HOME_DIR)/Library/Application Support/Code/User/settings.json"; do \
	  if [ -L "$$d" ]; then \
	    printf "  ${G}OK${NC}  symlink: $$d\n"; \
	  elif [ -f "$$d" ]; then \
	    printf "  ${Y}!!${NC}  regular file (not symlink): $$d\n"; \
	  else \
	    printf "  ${R}!!${NC}  missing: $$d\n"; \
	  fi; \
	done
	@printf "\n  ${C}::${NC} Checking key tools...\n"
	@for cmd in brew stow zsh git code; do \
	  if command -v "$$cmd" &>/dev/null; then \
	    printf "  ${G}OK${NC}  $$cmd\n"; \
	  else \
	    printf "  ${R}!!${NC}  $$cmd not found\n"; \
	  fi; \
	done
	@printf "\n  ${G}Doctor check complete.${NC}\n"

# Clean
clean:
	@printf "  ${C}::${NC} Finding broken symlinks pointing to this repo...\n"
	@find "$(HOME_DIR)" -type l -lname "$(DOTFILES)*" ! -exec test -e {} \; -print \
	  -exec printf "  ${Y}!!${NC}  broken: {}" \; -exec rm {} \; \
	  -exec printf " -> removed\n" \; 2>/dev/null || true
	@printf "  ${G}Done.${NC}\n"
