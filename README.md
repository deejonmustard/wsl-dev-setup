# WSL Development Environment Setup

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-v0.0.1-blue.svg)](https://github.com/deejonmustard/wsl-dev-setup/releases/tag/v0.0.1)

Automated setup script for WSL Arch Linux development environment.

## Components

- **Neovim** with Kickstart configuration (single-file or modular)
- **Zsh** with Oh My Zsh and plugins
- **Tmux** terminal multiplexer
- **Node.js** via NVM
- **Modern CLI tools**: `eza`, `bat`, `ripgrep`, `fzf`, `zoxide`, `lazygit`, `starship`
- **Dotfiles management**: chezmoi or manual sync
- **Music system**: MPD + rmpc with Windows music access
- **GitHub CLI** integration
- **Claude Code** AI assistant (optional)

## Installation

### WSL Arch Linux Setup

```bash
# Remove Previous Arch Installation (If Needed)
wsl.exe --unregister archlinux

# Install Arch Linux from the Microsoft Store or via:
wsl.exe --install -d archlinux

# List Local Distro Installs w Version:
wsl.exe -l -v

# Launch Arch Linux:
wsl.exe -d archlinux
```

### Run Setup Script

```bash
# Download the setup script
curl -o setup.sh https://raw.githubusercontent.com/deejonmustard/wsl-dev-setup/main/setup.sh

# Make it executable and run
chmod +x setup.sh
./setup.sh
```

Interactive mode: `./setup.sh --interactive`

## Configuration

### Dotfiles Management
- Creates `~/dotfiles` directory containing all configuration files
- Symlinks configurations to appropriate locations in `$HOME`
- Git repository for version control
- Optional Windows sync scripts

### Neovim Options
- **Single-file**: One `init.lua` file
- **Modular**: Multi-file structure in `lua/` directory

### Dotfiles Sync Options
- **Chezmoi**: Template-based management with cross-platform support
- **Manual**: Bash scripts for Windows ↔ WSL synchronization

## Directory Structure

```
~/
├── dev/
│   ├── docs/              # Documentation
│   ├── bin/               # Custom scripts
│   ├── projects/          # Development projects
│   └── update.sh          # Environment updater
├── dotfiles/              # Configuration files
└── bin/                   # User executables
    ├── cursor-wrapper.sh  # Cursor IDE integration
    ├── winopen            # Windows Explorer launcher
    └── clip-copy          # Clipboard utilities
```

## Usage

```bash
# Update environment
~/dev/update.sh

# Sync dotfiles (manual mode)
~/dotfiles/sync-to-windows.sh
~/dotfiles/sync-from-windows.sh

# Music system
music-start
rmpc

# Modern CLI tools
ll                # eza with icons
bat file.txt      # syntax highlighting
z projects        # zoxide cd
```

## Documentation

After installation:
- Quick reference: `cat ~/dev/docs/quick-reference.md`
- Workflow guide: `cat ~/dev/docs/workflow-guide.md`
- All docs: `ls ~/dev/docs/`

## Requirements

- WSL 2 with Arch Linux
- Internet connection for package downloads
- Windows 10/11

## Optional Components

- **Claude Code**: Requires Anthropic account with billing
- **Cursor IDE**: Windows installation for full integration

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 
