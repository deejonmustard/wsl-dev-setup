# WSL Development Environment Setup

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-v0.0.1-blue.svg)](https://github.com/deejonmustard/wsl-dev-setup/releases/tag/v0.0.1)

A comprehensive development environment setup script for WSL Arch Linux with unified cross-platform dotfile management, modern CLI tools, and beautiful theming.

## ⚠️ Known Issues

### Rust Installation May Hang
The script may hang during Rust installation via rustup in WSL environments. If this happens:
1. Press `Ctrl+C` to cancel the script
2. Run the provided fix script: `chmod +x fix-hanging-rust.sh && ./fix-hanging-rust.sh`
3. Follow the instructions to continue setup

The latest version of the script has been updated to handle this more gracefully by:
- Installing Rust via pacman first (more reliable in WSL)
- Adding a timeout to rustup installation
- Making Rust-based tools optional

## Features

### Core Development Environment
- **Neovim** with choice of Regular or Modular Kickstart configuration and optional theming
- **Zsh** with Oh My Zsh, autosuggestions, and syntax highlighting
- **Tmux** for terminal multiplexing with vim-like navigation
- **Chezmoi** for intelligent dotfile management across Windows and WSL
- **Node.js** via NVM for flexible version management
- **Claude Code** AI assistant (optional - requires Anthropic account)
- **GitHub CLI** for seamless repository management

### Modern CLI Tools
- **exa** - Modern replacement for ls with icons
- **bat** - Cat clone with syntax highlighting
- **fd** - User-friendly find alternative
- **ripgrep** - Lightning-fast grep replacement
- **fzf** - Fuzzy finder for files and commands
- **delta** - Beautiful git diff viewer
- **zoxide** - Smarter cd command
- **lazygit** - Terminal UI for git
- **btop** - Modern system monitor
- **starship** - Cross-shell prompt with custom theming

### Enhanced Features
- **Theme Selection** - Choose between Rose Pine, Catppuccin, Tokyo Night, Nord, or Dracula
- **Nerd Fonts** - JetBrains Mono with icon support
- **Terminal Configs** - Pre-configured WezTerm and Alacritty with transparency
- **WSL Optimizations** - Performance tweaks and clipboard integration
- **Cursor IDE Support** - Seamless integration with Windows installation
- **Cross-Platform Dotfiles** - Edit from Windows or WSL with automatic syncing

## Quick Install

Install WSL Arch Linux:
 
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

From a fresh Arch Linux WSL installation:

```bash
# Download the setup script
curl -o setup.sh https://raw.githubusercontent.com/deejonmustard/wsl-dev-setup/main/setup.sh

# Make it executable and run
chmod +x setup.sh
./setup.sh
```

#### _Optional:_ Run in interactive mode (prompts for each package)
```bash
./setup.sh --interactive
```

The script will:
1. Initialize the pacman keyring if needed
2. Install sudo and base packages
3. Offer to create a new user (recommended)
4. Set up the complete development environment with your theme choice

If you create a new user, you'll need to:
1. Restart WSL: `wsl.exe --terminate archlinux` (in PowerShell)
2. Launch Arch Linux again: `wsl.exe -d archlinux`
3. Run the setup script again as your new user

## Intelligent Dotfile Management

### Automatic Windows Dotfiles Detection
The setup script intelligently detects existing Windows dotfiles at `C:\Users\username\dotfiles`. If found, it:
- Uses your existing dotfiles directory without creating duplicates
- Preserves Windows symlinks and configurations
- Enables seamless cross-platform editing
- Maintains a single source of truth for all dotfiles

### Two Approaches Available:

1. **Unified Windows + WSL (Recommended)**:
   - Dotfiles stored in Windows-accessible location
   - Edit from both Windows and WSL seamlessly
   - Single git repository for all dotfiles
   - Chezmoi templates handle OS differences automatically

2. **WSL-Only (Traditional)**:
   - Dotfiles stored in WSL home directory
   - Separate from Windows dotfiles
   - Traditional Linux approach

## Neovim Configuration Options

The setup offers two Kickstart.nvim variants:

### Regular Kickstart (Default)
- **Single File**: Everything in one `init.lua`
- **Best For**: Beginners, simple setups
- **Pros**: Easy to understand, self-contained
- **Source**: Official nvim-lua/kickstart.nvim

### Modular Kickstart
- **Multi-File**: Configuration split into logical modules
- **Best For**: Advanced users, extensive customization
- **Pros**: Better organization, easier to extend
- **Source**: dam9000/kickstart-modular.nvim fork

Both versions include the same features - the only difference is file organization. During setup, you can:
- Use your existing GitHub fork of either version
- Use a local clone you already have
- Clone from the official repositories

## What's Included

### Development Tools
- **Core Tools**: git, ripgrep, fd, fzf, tmux, zsh, jq, bat, htop
- **Modern CLI**: exa, zoxide, delta, lazygit, ranger, ncdu, duf
- **System Monitoring**: htop, btop, iotop, nethogs
- **Build Tools**: base-devel, cmake, python, rust (via rustup)

### Terminal & Shell
- **Neovim**: Latest version with Kickstart.nvim configuration
- **Zsh**: Enhanced with Oh My Zsh and plugins
- **Starship**: Customizable prompt with theme support
- **Tmux**: Multiplexer with intuitive keybindings

### Integration & Utilities
- **WSL Utilities**: Windows path integration, clipboard sync
- **Cursor/VS Code**: Automatic detection and wrapper scripts
- **GitHub CLI**: Repository management and authentication
- **Fastfetch**: System information display

## Directory Structure

The setup creates an organized structure:
```
~/
├── dev/                   # Main development environment
│   ├── docs/              # Documentation and guides
│   ├── bin/               # Custom scripts
│   ├── projects/          # Your projects
│   └── update.sh          # Environment updater
├── dotfiles/              # Chezmoi source directory
└── bin/                   # User executables
    ├── cursor-wrapper.sh  # Cursor IDE integration
    ├── winopen            # Windows Explorer opener
    └── clip-copy          # Clipboard utilities
```

## Theme Customization

The setup includes a theme selector with popular options:
- **Rose Pine** - Soho vibes with transparency
- **Catppuccin** - Soothing pastel theme
- **Tokyo Night** - Clean and modern
- **Nord** - Arctic, north-bluish theme
- **Dracula** - Dark theme with vibrant colors

All themes are configured with 0.9 transparency for a modern look.

## Cross-Platform Workflows

### Unified Dotfiles
With the unified approach, your dotfiles live in `C:\Users\username\dotfiles`:

1. **Single Source of Truth**: One git repository for all platforms
2. **Edit Anywhere**: Use your favorite Windows editor or WSL tools
3. **Automatic Templating**: Chezmoi handles OS-specific differences
4. **Instant Sync**: Changes are immediately available across platforms

### Example Workflow
```bash
# Edit in Windows (e.g., with Cursor/VS Code)
# Open C:\Users\username\dotfiles in your editor

# Apply changes in WSL
chezmoi apply

# Or edit in WSL
chezmoi edit ~/.zshrc
chezmoi apply
```

## GitHub Integration

The setup includes comprehensive GitHub integration:
- **Automatic Authentication**: Web-based or token auth
- **Repository Creation**: One-command private/public repo setup
- **Seamless Syncing**: Push/pull dotfiles with ease

## Cursor IDE Support

Full integration with Cursor IDE for Windows:
- **Automatic Detection**: Scans common installation paths
- **PATH Integration**: Adds Cursor to PATH if found
- **WSL Wrapper**: Handles path conversion seamlessly
- **Command Aliases**: Both `cursor .` and `code .` work

## WSL-Specific Optimizations

Performance and integration enhancements:
- **Systemd Support**: Modern init system for WSL2
- **File System**: Cross-filesystem Git support
- **Clipboard**: Bidirectional clipboard sync
- **Path Handling**: Intelligent Windows path conversion
- **Performance**: Optimized Node.js and file watching

## Maintenance

Keep your environment current:
```bash
# Update everything
~/dev/update.sh

# Update dotfiles only
chezmoi update

# Update specific tools
cargo install-update -a  # Rust tools
nvm install --lts       # Node.js
```

## Claude Code Setup

The script includes optional Claude Code installation:
1. Requires an Anthropic account with billing
2. Minimum $5 credits needed
3. Install with: `npm install -g claude-ai-cli`
4. Authenticate with: `claude login`

## Script Options

### Non-Interactive Mode (Default)
Auto-confirms all prompts for unattended installation:
```bash
./setup.sh
```

### Interactive Mode
Manual control over each package installation:
```bash
./setup.sh --interactive
```

## Troubleshooting

### Common Issues
- **Existing Dotfiles**: Script automatically detects Windows dotfiles at `C:\Users\username\dotfiles`
- **Terminal Width**: Pacman warnings about columns are cosmetic
- **Node.js Not Found**: Run `source ~/.nvm/nvm.sh`
- **Cursor Not Working**: Install from https://cursor.sh then run `~/bin/cursor-path.sh`

### Getting Help
After installation, comprehensive documentation is available:
- Workflow guide: `cat ~/dev/docs/workflow-guide.md`
- Quick reference: `cat ~/dev/docs/quick-reference.md`
- Chezmoi guide: `cat ~/dev/docs/chezmoi/getting-started.md`

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 
