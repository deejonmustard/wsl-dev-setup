# WSL Development Environment Setup

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A simple script to set up a beginner-friendly development environment for WSL Arch Linux with dotfile management.

## Features

- Neovim with Kickstart configuration (latest version from Arch repos)
- Zsh with Oh My Zsh and plugins
- Tmux for terminal multiplexer
- Chezmoi for dotfile management across Windows and WSL
- Node.js via NVM
- Claude Code AI assistant (optional)
- Core development tools and utilities
- **Seamless GitHub integration** via GitHub CLI
- **Organized directory structure** with configuration in ~/dev and dotfiles in ~/dotfiles
- **Fastfetch** for system information display (modern neofetch alternative)
- **Interactive and non-interactive modes** for flexible installation control

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

From a fresh Arch Linux WSL installation (you'll start as root, create a new user, do `wsl --terminate archlinux` , open Arch Linux again, and run the script a second time):

```bash
# Download the setup script
curl -o setup.sh https://raw.githubusercontent.com/deejonmustard/wsl-dev-setup/main/setup.sh

# Make it executable and run
chmod +x setup.sh
./setup.sh
```

Optional: Run in interactive mode (prompts for each package)
`./setup.sh --interactive`


The script will:
1. Initialize the pacman keyring if needed
2. Install sudo and base packages
3. Offer to create a new user (recommended)
4. Set up the complete development environment

If you create a new user, you'll need to:
1. Restart WSL: `wsl.exe --terminate archlinux` (in PowerShell)
2. Launch Arch Linux again: `wsl.exe -d archlinux`
3. Run the setup script again as your new user

## What's Included

- **Core Tools**: git, ripgrep, fd, fzf, tmux, zsh, and more
- **Neovim**: Latest version from Arch repositories with Kickstart configuration
- **Zsh**: Enhanced shell with Oh My Zsh and plugins
- **Chezmoi**: Dotfile manager to sync configs between WSL and Windows
- **NVM**: Node Version Manager for JavaScript development
- **Claude Code**: AI assistant for coding (optional - may require manual installation)
- **WSL Utilities**: Helper scripts for Windows integration
- **GitHub CLI**: Seamless dotfiles repository management
- **Fastfetch**: Modern system information tool (replaces the discontinued neofetch)

## Directory Structure

The setup creates an organized structure:
- `~/dev`: Main development environment directory
  - `/docs`: Documentation for installed tools
  - `/bin`: Custom scripts and utilities
  - `/projects`: Recommended location for your projects
  - `/configs`: Various configuration backups
- `~/dotfiles`: Chezmoi source directory for all your dotfiles

## GitHub Integration

The setup script now includes comprehensive GitHub integration using GitHub CLI:

1. **Automatic CLI Installation**: Installs GitHub CLI from Arch repos
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

Chezmoi is installed to help you manage your configuration files (dotfiles) across both Windows and WSL. This ensures your development environment remains consistent.

### Organized Directory Structure

This setup uses a custom source directory for Chezmoi at `~/dotfiles` instead of the default location. This keeps your dotfiles separate from your development environment.

### Basic Usage

The setup configures chezmoi to use `~/dotfiles` as the source directory via a config file, so you don't need to specify it each time:

```bash
# Add a configuration file to be managed by chezmoi
chezmoi add ~/.zshrc

# Edit a configuration file
chezmoi edit ~/.zshrc

# Apply changes to your dotfiles
chezmoi apply

# Push changes to your dotfiles repository
cd ~/dotfiles && git push
```

### Managing Machine-Specific Differences

Chezmoi allows you to handle differences between your Windows environment and WSL setup using templates and conditional logic.

For a full guide, see the documentation in `~/dev/docs/chezmoi-guide.md` after installation.

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
chezmoi update
```

```bash
# In WSL
chezmoi update
```

This way, any changes you make to your configuration in either environment will be available in both!

## Updates

After installation, you can update your environment by running:

```bash
# Update system and tools
~/dev/update.sh

# Update dotfiles separately
chezmoi update
```

## Arch Linux Specific Notes

This setup is optimized for Arch Linux on WSL and uses:
- `pacman` for package management
- Latest Neovim from official Arch repositories
- Arch-specific package names (e.g., `fd` instead of `fd-find`)
- Base development tools from `base-devel` package group
- Automatic bootstrap process for fresh installations

## Script Options

### Non-Interactive Mode (Default)
By default, the script runs in non-interactive mode where all package installations are automatically approved. You'll see `[Y/n]` prompts from pacman, but they will be auto-answered with 'yes'.

### Interactive Mode
If you prefer to manually approve each package installation:
```bash
./setup.sh --interactive
```

This allows you to review and approve/reject each package installation individually.

## Known Issues

- **Claude Code Installation**: The npm package `@anthropic-ai/claude-code` might not be available in the public npm registry or may require authentication. The script will skip this installation if it fails. You can try installing it manually later if needed.
- **Terminal Width Warnings**: You might see "insufficient columns available for table display" warnings from pacman. These are cosmetic and don't affect functionality.
- **Auto-answered Prompts**: In non-interactive mode (default), you'll see `[Y/n]` prompts that are automatically answered. This is expected behavior.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 
