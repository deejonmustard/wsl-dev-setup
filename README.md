# WSL Development Environment Setup

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A simple script to set up a beginner-friendly development environment for WSL Debian with dotfile management.

## Features

- Neovim with Kickstart configuration
- Zsh with Oh My Zsh and plugins
- Tmux for terminal multiplexer
- Chezmoi for dotfile management across Windows and WSL
- Node.js via NVM
- Claude Code AI assistant
- Core development tools and utilities
- **Seamless GitHub integration** via GitHub CLI

## Quick Install

Uninstall previous WSL Debian installation (if needed)
 
```bash
wsl --unregister Debian

# List Local Distro Installs w Version:

wsl -l -v

# Install From Store (More Updates):
 
wsl.exe --install -d Debian

# Launch Debian:
 
wsl.exe -d Debian

```

From a fresh Debian WSL installation, run:

```bash
# Update system and install curl first
sudo apt update
sudo apt upgrade -y
sudo apt install curl -y

# Download and run the setup script
curl -o setup.sh https://raw.githubusercontent.com/deejonmustard/wsl-dev-setup/main/setup.sh && chmod +x setup.sh && ./setup.sh
```

## What's Included

- **Core Tools**: git, ripgrep, fd-find, fzf, tmux, zsh, and more
- **Neovim**: Modern text editor with Kickstart configuration
- **Zsh**: Enhanced shell with Oh My Zsh and plugins
- **Chezmoi**: Dotfile manager to sync configs between WSL and Windows
- **NVM**: Node Version Manager for JavaScript development
- **Claude Code**: AI assistant for coding
- **WSL Utilities**: Helper scripts for Windows integration
- **GitHub CLI**: Seamless dotfiles repository management

## GitHub Integration

The setup script now includes comprehensive GitHub integration using GitHub CLI:

1. **Automatic CLI Installation**: Installs GitHub CLI if needed
2. **Interactive Authentication**: Simple web-based or token auth flow
3. **Automatic Username Detection**: No need to manually enter your username
4. **One-Command Repository Creation**: Creates private or public repos with a single command
5. **Seamless Remote Setup**: Automatically configures your git remote

This makes it incredibly easy to get your dotfiles stored on GitHub with minimal effort.

## Neovim Setup

The setup script uses [kickstart.nvim](https://github.com/nvim-lua/kickstart.nvim) as the base Neovim configuration. During installation you'll be asked if you have a fork of kickstart.nvim:

- If you do: provide your GitHub username to clone your fork
- If not: the script will use the official repository

It's recommended to fork kickstart.nvim to your own GitHub account for easier customization:
1. Visit https://github.com/nvim-lua/kickstart.nvim and click "Fork"
2. Clone your fork during setup by answering "yes" when prompted

## Dotfile Management with Chezmoi

Chezmoi is installed to help you manage your configuration files (dotfiles) across both Windows and WSL. This ensures your development environment remains consistent:

### Basic Usage

```bash
# Add a configuration file to be managed by chezmoi
chezmoi add ~/.zshrc

# Edit a configuration file
chezmoi edit ~/.zshrc

# Apply changes to your dotfiles
chezmoi apply

# Push changes to your dotfiles repository
chezmoi git push
```

### Managing Machine-Specific Differences

Chezmoi allows you to handle differences between your Windows environment and WSL setup using templates and conditional logic.

For a full guide, see the documentation in `~/dev-env/docs/chezmoi-guide.md` after installation.

### Integrating Windows Dotfiles with WSL

You can use the same Chezmoi repository to manage both your Windows dotfiles and your WSL dotfiles. Here's how to set it up:

#### 1. Install Chezmoi on Windows

In PowerShell:

```powershell
# Using winget
winget install twpayne.chezmoi

# OR using Scoop
scoop install chezmoi

# OR using Chocolatey
choco install chezmoi
```

#### 2. Initialize with the Same Repository

```powershell
# Initialize Chezmoi with your GitHub repository
chezmoi init https://github.com/YOUR-USERNAME/dotfiles.git

# Apply configuration files
chezmoi apply
```

#### 3. Add Windows-Specific Files

```powershell
# Add PowerShell profile
chezmoi add $PROFILE

# Add other Windows config files
chezmoi add ~\AppData\Roaming\Windows Terminal\settings.json
chezmoi add ~\.gitconfig
```

#### 4. Handle OS-Specific Differences

Create template files that use Chezmoi's built-in templating to handle OS differences:

```
{{- if eq .chezmoi.os "windows" }}
# Windows-specific settings
{{- else }}
# Linux/WSL-specific settings
{{- end }}
```

#### 5. Synchronize Between Windows and WSL

Since both systems point to the same GitHub repository, you can keep them in sync:

```powershell
# In Windows PowerShell
chezmoi git pull
chezmoi apply
```

```bash
# In WSL
chezmoi git pull
chezmoi apply
```

This way, any changes you make to your configuration in either environment will be available in both!

## Updates

After installation, you can update your environment by running:

```bash
# Update system and tools
~/dev-env/update.sh

# Update dotfiles separately
chezmoi update
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 
