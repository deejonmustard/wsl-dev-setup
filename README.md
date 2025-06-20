# WSL Development Environment Setup

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Version](https://img.shields.io/badge/Version-v0.0.1-blue.svg)](https://github.com/deejonmustard/wsl-dev-setup/releases/tag/v0.0.1)

A comprehensive development environment setup script for WSL Arch Linux that gets you from **0→1** with modern tools while making the **1→100** customization path effortless.

## Philosophy: 0→1, Then You Take Over

This script follows a **0→1 philosophy** - it provides you with a rock-solid foundation of modern development tools and infrastructure, then gets out of your way so you can customize from 1→100 however you want.

**What we provide (0→1):**
- Essential modern CLI tools and development environment
- Cross-platform dotfile management infrastructure
- Flexible configuration system
- Comprehensive documentation
- Clean, unopinionated foundation

**What we don't impose (1→100 is yours):**
- ~~Specific themes or color schemes~~ 
- ~~Forced configuration choices~~
- ~~Opinionated workflow decisions~~

The result: You get a powerful, modern development environment in minutes, with complete freedom to theme and customize it exactly how you want.

## Features

### Core Development Environment
- **Neovim** with choice of Regular or Modular Kickstart configuration
- **Zsh** with Oh My Zsh, autosuggestions, and syntax highlighting  
- **Tmux** for terminal multiplexing with vim-like navigation
- **Node.js** via NVM for flexible version management
- **Claude Code** AI assistant (optional - requires Anthropic account)
- **GitHub CLI** for seamless repository management

### Modern CLI Tools Foundation
- **exa** - Modern replacement for ls with icons
- **bat** - Cat clone with syntax highlighting  
- **fd** - User-friendly find alternative
- **ripgrep** - Lightning-fast grep replacement
- **fzf** - Fuzzy finder for files and commands
- **zoxide** - Smarter cd command
- **lazygit** - Terminal UI for git
- **starship** - Cross-shell prompt
- **fastfetch** - System information display

### Intelligent Dotfile Management
- **Optional Chezmoi** - Advanced dotfile management for power users
- **Manual Management** - Simple directory-based approach for those who prefer control
- **Cross-Platform Support** - Edit from Windows or WSL with automatic syncing
- **Unified Approach** - Single source of truth for all your configurations

### WSL Integration & Modern Tooling
- **Cursor IDE Support** - Seamless integration with Windows installation
- **Ghostty Terminal** - Linux-native terminal with clean configuration
- **GitHub Integration** - Authentication and repository management
- **Cross-Platform Utilities** - Windows Explorer integration, clipboard sync
- **Performance Optimizations** - WSL-specific tweaks and enhancements

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
4. Set up the complete development environment with your choices

If you create a new user, you'll need to:
1. Restart WSL: `wsl.exe --terminate archlinux` (in PowerShell)
2. Launch Arch Linux again: `wsl.exe -d archlinux`
3. Run the setup script again as your new user

## Flexible Dotfile Management

The setup intelligently adapts to your preferences:

### Automatic Detection
- Detects existing Windows dotfiles at `C:\Users\username\dotfiles`
- Preserves existing configurations and workflows
- No duplication or conflicts with your current setup

### Two Management Approaches

**Option 1: Chezmoi (Advanced Users)**
- Template-based configuration with OS-specific handling
- Git integration with automatic syncing
- Powerful for managing multiple machines
- Handles complex cross-platform scenarios

**Option 2: Manual Management (Simple & Direct)**
- Direct file editing in organized dotfiles directory
- Simple symlink-based system
- Full control over every configuration
- Traditional Unix approach with modern tooling

### Cross-Platform Workflows

**Unified Windows + WSL (Recommended):**
- Dotfiles stored in Windows-accessible location
- Edit from both Windows and WSL seamlessly  
- Single git repository for all dotfiles
- Automatic OS difference handling

**WSL-Only (Traditional):**
- Dotfiles stored in WSL home directory
- Separate from Windows configurations
- Standard Linux dotfile approach

## Neovim Configuration Options

Choose the Kickstart.nvim variant that fits your needs:

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

Both provide the same powerful features - only the file organization differs. You can also:
- Use your existing GitHub fork of either version
- Use a local clone you already have
- Start from the official repositories

## What's Included

### Development Tools
- **Core Tools**: git, ripgrep, fd, fzf, tmux, zsh, jq, bat, htop
- **Modern CLI**: exa, zoxide, lazygit, ranger, ncdu, duf
- **System Monitoring**: fastfetch, btop
- **Build Tools**: base-devel, cmake, python, rust (via rustup)

### Terminal & Shell
- **Neovim**: Latest version with Kickstart.nvim configuration
- **Zsh**: Enhanced with Oh My Zsh and productivity plugins
- **Starship**: Customizable cross-shell prompt
- **Tmux**: Multiplexer with intuitive keybindings

### Integration & Utilities  
- **WSL Utilities**: Windows path integration, clipboard sync
- **Cursor/VS Code**: Automatic detection and wrapper scripts
- **GitHub CLI**: Repository management and authentication
- **Cross-Platform**: Seamless Windows-WSL workflow integration

## Directory Structure

The setup creates a clean, organized structure:
```
~/
├── dev/                   # Main development environment  
│   ├── docs/              # Documentation and guides
│   ├── bin/               # Custom scripts
│   ├── projects/          # Your projects (recommended)
│   └── update.sh          # Environment updater
├── dotfiles/              # Your dotfiles (location varies)
└── bin/                   # User executables
    ├── cursor-wrapper.sh  # Cursor IDE integration
    ├── winopen            # Windows Explorer opener
    └── clip-copy          # Clipboard utilities
```

## Customization Made Easy (1→100)

The environment provides excellent tools for customization:

### Modern CLI Foundation
All the tools you need for efficient customization:
- **ripgrep & fd**: Lightning-fast searching through configs
- **fzf**: Fuzzy finding for quick navigation  
- **bat**: Syntax-highlighted file viewing
- **exa**: Beautiful directory listings
- **lazygit**: Visual git interface for managing dotfiles

### Theming Freedom
No imposed themes - start with a clean foundation:
- **Neovim**: Kickstart provides LSP, completion, and modern features
- **Terminal**: Clean base configurations ready for your themes
- **Shell**: Oh My Zsh with sensible defaults, easily customizable
- **Tmux**: Vim-like navigation with clean status line

### Documentation & Guides
Comprehensive documentation for your customization journey:
- Workflow guides and best practices
- Tool-specific configuration examples  
- Cross-platform development tips
- Troubleshooting and maintenance guides

## Cross-Platform Workflows

### Unified Dotfiles Example
```bash
# Edit in Windows (e.g., with Cursor/VS Code)
# Open C:\Users\username\dotfiles in your editor

# Apply changes in WSL (if using Chezmoi)
chezmoi apply

# Or with manual management - changes are immediate
# since files are symlinked
```

### Development Workflow
```bash
# Start your day
fastfetch                 # Check system status
tmux new -s work         # Create development session
cursor ~/dev/projects    # Open your IDE

# Manage configurations
nvim ~/.zshrc            # Edit configs directly
# or
chezmoi edit ~/.zshrc    # Edit via Chezmoi (if enabled)
```

## GitHub Integration

Seamless GitHub integration for your dotfiles:
- **Automatic Authentication**: Web-based or token auth
- **Repository Management**: Easy private/public repo creation
- **Dotfile Syncing**: Push/pull configurations across machines
- **GitHub CLI**: Full command-line repository management

## WSL-Specific Optimizations

Performance and integration enhancements:
- **File System**: Optimized cross-filesystem operations
- **Clipboard**: Bidirectional Windows-WSL clipboard sync
- **Path Handling**: Intelligent Windows path conversion
- **Performance**: Optimized package mirrors and file watching
- **Integration**: Windows Explorer and application launching

## Maintenance

Keep your environment current:
```bash
# Update everything  
~/dev/update.sh

# Update dotfiles (if using Chezmoi)
chezmoi update

# Update specific tools
nvm install --lts       # Node.js
cargo install-update -a # Rust tools (if installed)
```

## Optional Enhancements

### Claude Code AI Assistant
The script includes optional Claude Code installation:
1. Requires Anthropic account with billing setup
2. Minimum $5 credits needed for usage
3. Install: Automatically handled during setup
4. Authenticate: `claude login` after installation

### Cursor IDE Integration
Full integration with Cursor IDE for Windows:
- **Automatic Detection**: Scans common installation paths
- **PATH Integration**: Adds Cursor to PATH when found
- **WSL Wrapper**: Handles path conversion seamlessly  
- **Command Aliases**: Both `cursor .` and `code .` work

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
- **Existing Dotfiles**: Script automatically detects and preserves existing configurations
- **Terminal Width**: Pacman column warnings are cosmetic and can be ignored
- **Node.js Not Found**: Run `source ~/.nvm/nvm.sh` to initialize NVM
- **Cursor Integration**: Install from https://cursor.sh then run `~/bin/cursor-path.sh`
- **Network Timeouts**: Script includes retry logic and fallback mirrors

### Getting Help
Comprehensive documentation is created during installation:
- **Workflow guide**: `cat ~/dev/docs/workflow-guide.md`
- **Quick reference**: `cat ~/dev/docs/quick-reference.md`
- **Dotfile guides**: `ls ~/dev/docs/` for all available documentation

## Philosophy in Practice

### 0→1: What We Handle
✅ **Essential Tools**: All modern CLI tools and development infrastructure  
✅ **Cross-Platform Setup**: Windows-WSL integration that just works  
✅ **Solid Foundation**: Neovim, tmux, zsh configured and ready  
✅ **Documentation**: Comprehensive guides for further customization  
✅ **Flexibility**: Optional vs required components clearly separated

### 1→100: What's Up to You  
🎨 **Themes & Colors**: Start with clean base, theme however you want  
⚙️ **Advanced Configs**: Powerful tools provided, configurations are yours  
🔧 **Workflow Choices**: Infrastructure supports any workflow you prefer  
🎯 **Specialization**: Foundation supports any development focus  

This approach means you get a **production-ready development environment in minutes**, with complete freedom to make it uniquely yours.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 
