# dotfiles

Personal macOS configuration by [@raihanpka](https://github.com/raihanpka) Managed with **GNU Stow** + **Homebrew Bundle**.

## what's inside

Configs for the tools I use daily — Zsh with Powerlevel10k, Git, Ghostty,
and VS Code. A Brewfile that captures every CLI tool and GUI app manageable
via Homebrew. A one-command install script that wires everything up on a
fresh Mac.

Check the folders above and take what's useful.

## structure
```
.dotfiles/
├── Brewfile          # all brew-managed apps and tools
├── install.sh        # one-command setup script
├── git/
│   └── .gitconfig
├── ghostty/
│   └── .config/ghostty/config
├── macos/
│   └── defaults.sh
├── vscode/
│   ├── settings.json
│   └── extensions.txt
└── zsh/
    ├── .zshrc
    └── .p10k.zsh
```

## install
```bash
git clone https://github.com/raihanpka/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
bash install.sh
```

This installs Homebrew, Oh My Zsh, Powerlevel10k, symlinks all configs
into the right places, and installs VS Code extensions automatically.

## stow

GNU Stow handles symlinking. Each folder maps directly to your home directory.
```bash
# link a topic
cd ~/.dotfiles
stow zsh

# unlink a topic
stow -D zsh
```

## bugs

This is built for my own machine. If something does not work on yours,
open an issue and I will take a look.