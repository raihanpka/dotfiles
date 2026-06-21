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
SPINNER := $(DOTFILES)/scripts/spinner.sh

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
	@printf "  ${G}install${NC}        Full bootstrap (runs install.sh)\n"
	@printf "  ${G}brew-dump${NC}      Write current brew state into Brewfile\n"
	@printf "  ${G}brew-sync${NC}      brew-dump + remove packages not in Brewfile\n"
	@printf "  ${G}stow${NC}           Resymlink all stow managed packages\n"
	@printf "  ${G}doctor${NC}         Health check symlinks and tools\n"
	@printf "  ${G}clean${NC}          Remove broken symlinks pointing to this repo\n"
	@printf "\n"
	@printf "  ${Y}sync${NC}           Sync EVERY local config into this repo\n"
	@printf "  ${Y}sync-zsh${NC}       Copy .zshrc and .p10k.zsh into repo\n"
	@printf "  ${Y}sync-git${NC}       Copy .gitconfig into repo\n"
	@printf "  ${Y}sync-ghostty${NC}   Copy ghostty config into repo\n"
	@printf "  ${Y}sync-vscode${NC}    Copy VS Code settings + extensions into repo\n"
	@printf "  ${Y}sync-brewfile${NC}  Alias for brew-dump\n"
	@printf "\n"

# Install
install:
	@printf "\n  ${Y}::${NC} Running install.sh...\n\n"
	@bash "$(DOTFILES)/install.sh"

# Sync: copy live configs from $HOME into the repo
sync-zsh:
	@mkdir -p "$(DOTFILES)/zsh"
	@$(SPINNER) "Syncing .zshrc" cp "$(HOME_DIR)/.zshrc" "$(DOTFILES)/zsh/.zshrc"
	@$(SPINNER) "Syncing .p10k.zsh" cp "$(HOME_DIR)/.p10k.zsh" "$(DOTFILES)/zsh/.p10k.zsh"

sync-git:
	@mkdir -p "$(DOTFILES)/git"
	@$(SPINNER) "Syncing .gitconfig" cp "$(HOME_DIR)/.gitconfig" "$(DOTFILES)/git/.gitconfig"

sync-ghostty:
	@mkdir -p "$(DOTFILES)/ghostty"
	@$(SPINNER) "Syncing ghostty/config" cp "$(HOME_DIR)/Library/Application Support/com.mitchellh.ghostty/config" "$(DOTFILES)/ghostty/config"

sync-vscode:
	@mkdir -p "$(DOTFILES)/vscode"
	@$(SPINNER) "Syncing settings.json" cp "$(HOME_DIR)/Library/Application Support/Code/User/settings.json" "$(DOTFILES)/vscode/settings.json"
	@$(SPINNER) "Syncing extensions.txt" sh -c "code --list-extensions > $(DOTFILES)/vscode/extensions.txt"

sync-brewfile: brew-dump

sync: sync-zsh sync-git sync-ghostty sync-vscode brew-dump
	@printf "\n  ${Y}All configs synced.${NC}\n"

# Brew
brew-dump:
	@$(SPINNER) "Dumping brew state into Brewfile" brew bundle dump --force --file="$(DOTFILES)/Brewfile"

brew-sync: brew-dump
	@$(SPINNER) "Removing packages not in Brewfile" brew bundle cleanup --force --file="$(DOTFILES)/Brewfile"

# Stow
STOW_PACKAGES := zsh git

stow:
	@cd "$(DOTFILES)" && \
	  for pkg in $(STOW_PACKAGES); do \
	    if [ -d "$$pkg" ]; then \
	      $(SPINNER) "Stowing $$pkg" stow --adopt -t "$(HOME_DIR)" "$$pkg"; \
	    fi; \
	  done

# Doctor
doctor:
	@printf "\n  ${Y}::${NC} Checking symlink health...\n"
	@for f in \
	    "$(HOME_DIR)/.zshrc" \
	    "$(HOME_DIR)/.p10k.zsh" \
	    "$(HOME_DIR)/.gitconfig"; do \
	  if [ -L "$$f" ]; then \
	    printf "  ${G}OK${NC}  symlink: $$f\n"; \
	  elif [ -f "$$f" ]; then \
	    printf "  ${Y}!!${NC}  regular file (not symlink): $$f\n"; \
	  else \
	    printf "  ${Y}!!${NC}  missing: $$f\n"; \
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
	    printf "  ${Y}!!${NC}  missing: $$d\n"; \
	  fi; \
	done
	@printf "\n  ${Y}::${NC} Checking key tools...\n"
	@for cmd in brew stow zsh git code; do \
	  if command -v "$$cmd" &>/dev/null; then \
	    printf "  ${G}OK${NC}  $$cmd\n"; \
	  else \
	    printf "  ${Y}!!${NC}  $$cmd not found\n"; \
	  fi; \
	done
	@printf "\n  ${Y}Doctor check complete.${NC}\n"

# Clean
clean:
	@printf "  ${Y}::${NC} Finding broken symlinks pointing to this repo...\n"
	@find "$(HOME_DIR)" -type l -lname "$(DOTFILES)*" ! -exec test -e {} \; -print \
	  -exec printf "  ${Y}!!${NC}  broken: {}" \; -exec rm {} \; \
	  -exec printf " -> removed\n" \; 2>/dev/null || true
	@printf "  ${Y}Done.${NC}\n"
