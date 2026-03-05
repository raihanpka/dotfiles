# dotfiles

Personal macOS configuration by [@raihanpka](https://github.com/raihanpka)  
Managed with **GNU Stow** + **Homebrew Bundle**.

## Quick Start (New Mac)
```bash
git clone https://github.com/raihanpka/dotfiles.git ~/.dotfiles
bash ~/.dotfiles/install.sh
```

## What's Managed

| Folder | Config | Target |
|--------|--------|--------|
| `zsh/` | `.zshrc`, `.p10k.zsh` | `~/` |
| `git/` | `.gitconfig` | `~/` |
| `ghostty/` | `config` | `~/Library/Application Support/com.mitchellh.ghostty/` |
| `vscode/` | `settings.json`, `extensions.txt` | `~/Library/Application Support/Code/User/` |

## Apps

### Auto-install via Brewfile
Run `brew bundle` to restore all CLI tools and GUI apps.

### Manual Install Required
| App | Where |
|-----|-------|
| LINE | App Store |
| Microsoft 365 | office.com |
| Cisco Packet Tracer | netacad.com |
| DaVinci Resolve | blackmagicdesign.com |
| DataGrip | jetbrains.com |
| Minecraft | minecraft.net |
| Stockbit | App Store |
| Termius | App Store |
| Trae | trae.ai |
| Xcode | App Store |

## Stow Usage
```bash
# Link semua config
cd ~/.dotfiles
stow zsh git ghostty

# Unlink
stow -D zsh
```
