# Complete Guide: Syncing Windows and WSL Dotfiles with Chezmoi

## Table of Contents
1. [Introduction](#introduction)
2. [Understanding the Goal](#understanding-the-goal)
3. [Prerequisites](#prerequisites)
4. [Step-by-Step Setup Guide](#step-by-step-setup-guide)
5. [Managing Cross-Platform Differences](#managing-cross-platform-differences)
6. [Common Dotfiles Examples](#common-dotfiles-examples)
7. [Script Analysis and Improvements](#script-analysis-and-improvements)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

## Introduction

This guide explains how to create a unified dotfile management system that works seamlessly between Windows and WSL2 using Chezmoi, Git, and GitHub. The goal is to have all your configuration files (both Windows and WSL) in one place, allowing you to edit from either environment with automatic synchronization.

## Understanding the Goal

What we're building:
- **One Source of Truth**: A single GitHub repository containing ALL dotfiles
- **Bidirectional Sync**: Edit in Windows OR WSL, changes sync everywhere
- **Smart Templates**: Different configs for different environments automatically
- **Version Control**: Full history of all changes across both systems

## Prerequisites

- Windows 11 with WSL2 installed
- Git installed on both Windows and WSL
- GitHub account
- Basic understanding of terminal commands

## Step-by-Step Setup Guide

### Phase 1: Windows Setup

#### 1. Install Chezmoi on Windows

```powershell
# Using winget (recommended)
winget install twpayne.chezmoi

# OR using Scoop
scoop install chezmoi

# OR using Chocolatey
choco install chezmoi
```

#### 2. Initialize Chezmoi on Windows

```powershell
# Create the source directory structure
chezmoi init

# This creates:
# C:\Users\%USERNAME%\.local\share\chezmoi (source directory)
# C:\Users\%USERNAME%\.config\chezmoi\chezmoi.toml (config file)
```

#### 3. Configure Chezmoi for Cross-Platform Use

Create/edit `C:\Users\%USERNAME%\.config\chezmoi\chezmoi.toml`:

```toml
# Chezmoi configuration for Windows
[data]
    # Custom variables for templates
    name = "Your Name"
    email = "your.email@example.com"
    
[edit]
    # Use your preferred editor
    command = "code"
    args = ["--wait"]
    
[merge]
    # Three-way merge configuration
    command = "code"
    args = ["--wait", "--diff"]
```

### Phase 2: WSL Setup

#### 1. Install Chezmoi in WSL

Your script already does this, but for manual installation:

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin

# Add to PATH if needed
export PATH="$HOME/.local/bin:$PATH"
```

#### 2. Configure Chezmoi to Use Windows Source Directory

This is the KEY to unified management. We'll make WSL's chezmoi use the SAME source directory as Windows:

```bash
# Create chezmoi config directory
mkdir -p ~/.config/chezmoi

# Create config pointing to Windows chezmoi source
cat > ~/.config/chezmoi/chezmoi.toml << 'EOF'
[data]
    # Same data as Windows config
    name = "Your Name"
    email = "your.email@example.com"
    
# Point to Windows chezmoi source directory
sourceDir = "/mnt/c/Users/YOUR_WINDOWS_USERNAME/.local/share/chezmoi"

[edit]
    command = "nvim"
EOF

# Replace YOUR_WINDOWS_USERNAME with your actual Windows username
```

### Phase 3: GitHub Repository Setup

#### 1. Create Repository (Windows PowerShell)

```powershell
# Navigate to chezmoi source directory
cd C:\Users\%USERNAME%\.local\share\chezmoi

# Initialize git
git init
git branch -M main

# Create initial commit
git add .
git commit -m "Initial commit: Unified dotfiles for Windows and WSL"

# Create GitHub repo using GitHub CLI
gh repo create dotfiles --private --source=. --remote=origin --push
```

#### 2. Verify in WSL

```bash
# Navigate to the shared source directory
cd /mnt/c/Users/YOUR_WINDOWS_USERNAME/.local/share/chezmoi

# Check git status
git status

# You should see the same repository!
```

### Phase 4: Adding Dotfiles

#### Adding Windows Dotfiles

```powershell
# Add PowerShell profile
chezmoi add $PROFILE

# Add Windows Terminal settings
chezmoi add "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

# Add git config
chezmoi add ~/.gitconfig

# Add VS Code settings
chezmoi add "$env:APPDATA\Code\User\settings.json"
```

#### Adding WSL Dotfiles

```bash
# From WSL, add Linux configs
chezmoi add ~/.bashrc
chezmoi add ~/.zshrc
chezmoi add ~/.config/nvim
chezmoi add ~/.tmux.conf
```

## Managing Cross-Platform Differences

### Using Templates

Chezmoi uses Go templates to handle platform differences. Create template files with `.tmpl` extension:

#### Example: `.gitconfig.tmpl`

```ini
[user]
    name = {{ .name }}
    email = {{ .email }}

[core]
{{- if eq .chezmoi.os "windows" }}
    autocrlf = true
    editor = "code --wait"
{{- else }}
    autocrlf = input
    editor = nvim
{{- end }}

[credential]
{{- if eq .chezmoi.os "windows" }}
    helper = manager
{{- else if (.chezmoi.kernel.osrelease | lower | contains "microsoft") }}
    helper = /mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe
{{- else }}
    helper = store
{{- end }}
```

#### Example: Shell Configuration Template

Create `dot_bashrc.tmpl` or `dot_zshrc.tmpl`:

```bash
# Common aliases for all platforms
alias ll='ls -la'
alias gs='git status'

{{- if eq .chezmoi.os "windows" }}
# Windows-specific (Git Bash)
alias python='python.exe'
alias pip='pip.exe'
{{- else if (.chezmoi.kernel.osrelease | lower | contains "microsoft") }}
# WSL-specific
export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
export BROWSER='/mnt/c/Program Files/Mozilla Firefox/firefox.exe'

# Use Windows binaries
alias explorer='/mnt/c/Windows/explorer.exe'
alias code='/mnt/c/Program Files/Microsoft VS Code/bin/code'
{{- else }}
# Native Linux
export EDITOR=nvim
{{- end }}
```

### Directory Structure Best Practices

```
~/.local/share/chezmoi/        # Windows: C:\Users\USERNAME\.local\share\chezmoi
├── .git/                      # Git repository
├── .gitignore                 # Ignore patterns
├── README.md                  # Documentation
├── executable_install.sh.tmpl # Installation scripts
├── private_dot_ssh/           # SSH configs (encrypted)
├── dot_gitconfig.tmpl         # Git config template
├── dot_bashrc.tmpl            # Bash config template
├── dot_zshrc.tmpl             # Zsh config template
├── dot_config/                # .config directory
│   ├── nvim/                  # Neovim config
│   ├── alacritty/             # Terminal configs
│   └── starship.toml.tmpl    # Prompt config
├── AppData/                   # Windows AppData
│   ├── Roaming/               
│   │   └── Code/              # VS Code settings
│   └── Local/                 
│       └── Packages/          # Windows Terminal
└── Documents/                 # Windows documents
    └── PowerShell/            # PowerShell profiles
```

## Common Dotfiles Examples

### Windows Terminal Settings Integration

Create `AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json.tmpl`:

```json
{
    "defaultProfile": "{{ .defaultTerminalProfile }}",
    "profiles": {
        "list": [
            {
                "guid": "{574e775e-4f2a-5b96-ac1e-a2962a402336}",
                "name": "PowerShell",
                "source": "Windows.Terminal.PowershellCore",
                {{- if .useAcrylic }}
                "useAcrylic": true,
                "acrylicOpacity": 0.9,
                {{- end }}
                "colorScheme": "{{ .colorScheme }}"
            },
            {
                "guid": "{2c4de342-38b7-51cf-b940-2309a097f518}",
                "name": "Arch Linux",
                "source": "Windows.Terminal.Wsl",
                "startingDirectory": "~",
                "colorScheme": "{{ .colorScheme }}",
                "fontFace": "JetBrains Mono"
            }
        ]
    }
}
```

### PowerShell Profile Template

Create `Documents/PowerShell/Microsoft.PowerShell_profile.ps1.tmpl`:

```powershell
# PowerShell Profile
{{ if .starship -}}
# Initialize Starship
Invoke-Expression (&starship init powershell)
{{- end }}

# Aliases
Set-Alias g git
Set-Alias vim nvim

# Functions
function dots { chezmoi edit --apply }
function refresh { chezmoi update }

# WSL interop
function wsl-home { wsl ~ }
function arch { wsl -d archlinux }
```

## Script Analysis and Improvements

### Current Script Assessment

Your current script handles the WSL side well but needs enhancements for unified Windows/WSL management:

**What's Working:**
- ✅ Chezmoi installation in WSL
- ✅ Custom source directory (`~/dotfiles`)
- ✅ GitHub integration
- ✅ Basic dotfile management

**What's Missing:**
- ❌ Windows/WSL source directory sharing
- ❌ Cross-platform templates
- ❌ Windows-side setup automation

### Recommended Script Improvements

Add this function to your `setup.sh`:

```bash
setup_unified_chezmoi() {
    print_header "Setting up Unified Chezmoi for Windows/WSL"
    
    # Detect Windows username
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
    if [ -z "$WIN_USER" ]; then
        print_step "Enter your Windows username:"
        read -r WIN_USER
    fi
    
    # Check if Windows has chezmoi setup
    WIN_CHEZMOI_SOURCE="/mnt/c/Users/$WIN_USER/.local/share/chezmoi"
    
    if [ -d "$WIN_CHEZMOI_SOURCE" ]; then
        print_step "Found existing Windows chezmoi source directory"
        
        # Update WSL chezmoi config to use Windows source
        mkdir -p "$HOME/.config/chezmoi"
        cat > "$HOME/.config/chezmoi/chezmoi.toml" << EOF
# Unified chezmoi configuration
[data]
    name = "$GIT_NAME"
    email = "$GIT_EMAIL"
    
# Use Windows chezmoi source directory
sourceDir = "$WIN_CHEZMOI_SOURCE"

[edit]
    command = "nvim"
EOF
        
        print_success "Configured chezmoi to use Windows source directory"
        
        # Create convenient symlink
        if [ ! -L "$HOME/dotfiles" ]; then
            ln -s "$WIN_CHEZMOI_SOURCE" "$HOME/dotfiles"
            print_success "Created symlink: ~/dotfiles -> Windows chezmoi source"
        fi
    else
        print_warning "No Windows chezmoi found. Setting up WSL-first approach..."
        
        # Continue with existing setup but add Windows interop
        mkdir -p "$HOME/.config/chezmoi"
        cat > "$HOME/.config/chezmoi/chezmoi.toml" << EOF
[data]
    name = "$GIT_NAME"
    email = "$GIT_EMAIL"
    
sourceDir = "$HOME/dotfiles"

[edit]
    command = "nvim"
    
# Add Windows mount info for templates
[data.windows]
    username = "$WIN_USER"
    home = "/mnt/c/Users/$WIN_USER"
EOF
    fi
    
    # Add helper scripts
    create_chezmoi_helpers
}

create_chezmoi_helpers() {
    print_step "Creating chezmoi helper scripts..."
    
    # Create unified update script
    cat > "$HOME/bin/dots-sync" << 'EOF'
#!/bin/bash
# Sync dotfiles across Windows and WSL

echo "Syncing dotfiles..."

# Ensure we're in the source directory
cd $(chezmoi source-path)

# Pull latest changes
git pull

# Apply to current system
chezmoi apply

# Show status
echo "Current status:"
git status --short

echo "Sync complete!"
EOF
    
    chmod +x "$HOME/bin/dots-sync"
    
    # Create edit helper
    cat > "$HOME/bin/dots-edit" << 'EOF'
#!/bin/bash
# Edit dotfiles with automatic templating

if [ -z "$1" ]; then
    chezmoi edit
else
    chezmoi edit --apply "$@"
fi
EOF
    
    chmod +x "$HOME/bin/dots-edit"
    
    print_success "Helper scripts created"
}
```

### Integration with Existing Script

Add to your main execution flow:

```bash
# After setup_chezmoi, add:
setup_unified_chezmoi || print_warning "Unified chezmoi setup failed, continuing..."
```

## Troubleshooting

### Common Issues and Solutions

**1. Permission Issues with Windows Files**
```bash
# Fix in WSL
sudo mount -t drvfs C: /mnt/c -o metadata,uid=1000,gid=1000,umask=002
```

**2. Line Ending Problems**
```bash
# Configure git globally
git config --global core.autocrlf input  # In WSL
git config --global core.autocrlf true   # In Windows
```

**3. Symlink Issues**
- Windows requires admin rights for symlinks
- Use templates instead of symlinks when possible

**4. Editor Conflicts**
```bash
# Set editor per environment in templates
{{- if eq .chezmoi.os "windows" }}
export EDITOR="code --wait"
{{- else }}
export EDITOR="nvim"
{{- end }}
```

## Best Practices

### 1. Commit Messages
```bash
# Be specific about platform
git commit -m "feat(windows): Add PowerShell aliases"
git commit -m "fix(wsl): Update nvim config path"
git commit -m "feat(cross-platform): Add unified git config"
```

### 2. Testing Changes
```bash
# Always test with --dry-run first
chezmoi apply --dry-run --verbose

# Test on both platforms before committing
```

### 3. Sensitive Data
```bash
# Use templates for secrets
# .env.tmpl
API_KEY={{ .apiKey }}

# Store in chezmoi config, not in git
chezmoi edit-config
```

### 4. Regular Backups
```bash
# Backup script
#!/bin/bash
backup_dir="$HOME/dotfiles-backup-$(date +%Y%m%d)"
chezmoi archive --output="$backup_dir.tar.gz"
```

### 5. Documentation
Always document platform-specific configurations:

```bash
# In your dotfiles README.md
## Platform-Specific Files

- Windows only: `Documents/PowerShell/*`
- WSL only: `.config/systemd/*`
- Both: `.gitconfig.tmpl` (uses templates)
```

## Conclusion

With this setup, you have:
- ✅ One dotfiles repository for both Windows and WSL
- ✅ Automatic synchronization via Git
- ✅ Smart templates handling platform differences
- ✅ Version control for all configurations
- ✅ Easy editing from either environment

The key insight is using Chezmoi's source directory as the bridge between Windows and WSL, combined with templates to handle platform-specific differences elegantly.