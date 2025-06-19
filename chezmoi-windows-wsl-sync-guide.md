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

### Your Current Setup vs. Best Practices

You currently use **symlinks** for your Windows dotfiles (as seen in your [dotfiles repo](https://github.com/deejonmustard/dotfiles)). While symlinks work well for Windows-only configs, they have limitations when working across Windows and WSL:

**Why Chezmoi is Recommended Over Symlinks for WSL/Cross-Platform:**
1. **Cross-boundary issues**: Symlinks between Windows and WSL filesystems can cause permission problems
2. **Performance**: Accessing Windows files from WSL through `/mnt/c` is slower than native WSL filesystem
3. **Line endings**: Automatic CRLF/LF conversion can break configs
4. **Templates**: Chezmoi can handle platform-specific differences elegantly
5. **Encryption**: Sensitive data (API keys, passwords) can be encrypted

**You Have Three Options:**
1. **Keep Windows symlinks, use Chezmoi for WSL only** (Simple but two systems)
2. **Migrate everything to Chezmoi** (Recommended - one system for all)
3. **Hybrid approach** (Complex - not recommended)

This guide will show you Option 2, but I'll note where you can stick with Option 1 if preferred.

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
- Your existing Windows dotfiles repo (we'll migrate or integrate it)
- Basic understanding of terminal commands

## Step-by-Step Setup Guide

### Phase 0: Deciding Your Approach

#### Option 1: Keep Windows Symlinks, Chezmoi for WSL Only
**Pros:**
- No changes to your existing Windows setup
- Can start using immediately in WSL
- Simple mental model

**Cons:**
- Two different systems to maintain
- No shared configs (like Git) between Windows/WSL
- Manual sync for common tools

**If choosing this option:** Skip to [Phase 2: WSL Setup](#phase-2-wsl-setup) and use your script as-is.

#### Option 2: Migrate Everything to Chezmoi (Recommended)
**Pros:**
- One system for everything
- Automatic handling of platform differences
- Shared configs work seamlessly
- Better security for sensitive data

**Cons:**
- Initial migration effort
- Need to learn Chezmoi templates

**Continue with the full guide for this approach.**

### Phase 1: Windows Setup

#### 1. Backup Your Current Dotfiles

Since you have an existing symlink setup, let's safely back it up first:

```powershell
# Create a backup
cd ~
Copy-Item -Path "dotfiles" -Destination "dotfiles-backup-$(Get-Date -Format 'yyyyMMdd')" -Recurse

# Also create a git bundle for safety
cd ~/dotfiles
git bundle create ../dotfiles-backup.bundle --all
```

#### 2. Install Chezmoi on Windows

```powershell
# Using winget (recommended)
winget install twpayne.chezmoi

# OR using Scoop
scoop install chezmoi

# OR using Chocolatey
choco install chezmoi
```

#### 3. Initialize Chezmoi with Your Existing Repo

We'll import your existing dotfiles into Chezmoi's structure:

```powershell
# Initialize chezmoi
chezmoi init

# Import your existing repo structure
cd C:\Users\%USERNAME%\.local\share\chezmoi
git remote add origin https://github.com/deejonmustard/dotfiles.git
```

#### 4. Migrate Your Symlinked Files to Chezmoi

For each symlinked file in your current setup, we'll add it to Chezmoi:

```powershell
# Example for your .gitconfig
chezmoi add ~/.gitconfig

# For your PowerShell profile
chezmoi add $PROFILE

# For VS Code settings (if you have them)
chezmoi add "$env:APPDATA\Code\User\settings.json"

# For Windows Terminal
chezmoi add "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
```

**Important**: After adding each file, Chezmoi manages it directly (no symlinks needed). You can remove the old symlinks:

```powershell
# Remove old symlink (example)
Remove-Item ~/.gitconfig -Force
# Apply from Chezmoi
chezmoi apply
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
- ❌ Integration with your existing Windows dotfiles

### Why Symlinks Are Problematic for WSL

Since you asked about best practices, here's why symlinks aren't recommended for WSL dotfiles:

1. **Filesystem Performance**
   ```bash
   # Symlink pointing to Windows file (SLOW)
   ~/.bashrc -> /mnt/c/Users/username/dotfiles/.bashrc
   
   # Native WSL file (FAST)
   ~/.bashrc (managed by Chezmoi in WSL filesystem)
   ```

2. **Permission Issues**
   - Windows symlinks have different permissions than Linux
   - Can cause issues with SSH keys, scripts, etc.
   - Git may show all files as modified due to permission differences

3. **Line Ending Headaches**
   - Windows uses CRLF, Linux uses LF
   - Symlinked files might get converted unexpectedly
   - Can break shell scripts and configs

4. **Editor Confusion**
   - Some editors treat symlinks differently
   - Path resolution can be inconsistent
   - Watchers/hot-reload may not work properly

### Recommended Script Improvements for Your Setup

Since you already have a Windows dotfiles repo, here's an enhanced setup function:

```bash
setup_unified_chezmoi_with_existing_repo() {
    print_header "Setting up Unified Chezmoi with Your Existing Dotfiles"
    
    # Detect Windows username
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
    if [ -z "$WIN_USER" ]; then
        print_step "Enter your Windows username:"
        read -r WIN_USER
    fi
    
    # Check for your existing Windows dotfiles
    WIN_DOTFILES="/mnt/c/Users/$WIN_USER/dotfiles"
    
    if [ -d "$WIN_DOTFILES/.git" ]; then
        print_success "Found your existing dotfiles repo at $WIN_DOTFILES"
        
        echo -e "\n${BLUE}How would you like to proceed?${NC}"
        echo "1) Use Chezmoi for WSL only (keep Windows symlinks)"
        echo "2) Migrate everything to Chezmoi (recommended)"
        echo "3) Set up from scratch"
        read -r choice
        
        case $choice in
            1)
                setup_wsl_only_chezmoi
                ;;
            2)
                migrate_to_unified_chezmoi "$WIN_DOTFILES"
                ;;
            3)
                setup_fresh_chezmoi
                ;;
            *)
                print_error "Invalid choice"
                return 1
                ;;
        esac
    else
        setup_fresh_chezmoi
    fi
}

setup_wsl_only_chezmoi() {
    print_step "Setting up Chezmoi for WSL only..."
    
    # Use separate source directory for WSL
    mkdir -p "$HOME/.config/chezmoi"
    cat > "$HOME/.config/chezmoi/chezmoi.toml" << EOF
sourceDir = "$HOME/dotfiles-wsl"

[data]
    name = "$GIT_NAME"
    email = "$GIT_EMAIL"
    windowsUser = "$WIN_USER"
    
[edit]
    command = "nvim"
EOF
    
    # Clone your repo for WSL-specific branch
    git clone https://github.com/deejonmustard/dotfiles.git "$HOME/dotfiles-wsl"
    cd "$HOME/dotfiles-wsl"
    
    # Create WSL-specific branch
    git checkout -b wsl-configs
    
    print_success "WSL-only Chezmoi configured"
    print_warning "Remember: Windows and WSL configs are managed separately"
}

migrate_to_unified_chezmoi() {
    local win_dotfiles="$1"
    print_step "Migrating to unified Chezmoi setup..."
    
    # Set up Chezmoi to use Windows location
    WIN_CHEZMOI="/mnt/c/Users/$WIN_USER/.local/share/chezmoi"
    
    # Create Chezmoi config
    mkdir -p "$HOME/.config/chezmoi"
    cat > "$HOME/.config/chezmoi/chezmoi.toml" << EOF
sourceDir = "$WIN_CHEZMOI"

[data]
    name = "$GIT_NAME"
    email = "$GIT_EMAIL"
    
[edit]
    command = "nvim"
    
[diff]
    command = "nvim"
    args = ["-d"]
EOF
    
    # Help with migration
    print_step "To complete migration:"
    echo "1. On Windows, install Chezmoi: winget install twpayne.chezmoi"
    echo "2. Initialize Chezmoi: chezmoi init"
    echo "3. Add your existing configs: chezmoi add ~/.gitconfig"
    echo "4. Push changes to your repo"
    echo "5. In WSL, run: chezmoi init --apply https://github.com/deejonmustard/dotfiles.git"
    
    print_success "Migration guide complete"
}

### Template Example for Your Git Config

Since you'll use Git on both Windows and WSL, here's how to handle it with templates:

Create `.gitconfig.tmpl`:
```ini
[user]
    name = {{ .name }}
    email = {{ .email }}

[core]
{{- if eq .chezmoi.os "windows" }}
    autocrlf = true
    editor = "code --wait"
    sshCommand = "C:/Windows/System32/OpenSSH/ssh.exe"
{{- else if (.chezmoi.kernel.osrelease | lower | contains "microsoft") }}
    autocrlf = input
    editor = nvim
    # Use Windows credential manager from WSL
    sshCommand = "/mnt/c/Windows/System32/OpenSSH/ssh.exe"
{{- end }}

[credential]
{{- if eq .chezmoi.os "windows" }}
    helper = manager
{{- else if (.chezmoi.kernel.osrelease | lower | contains "microsoft") }}
    # Share credentials with Windows
    helper = /mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe
{{- end }}

# Your existing aliases work on both platforms
[alias]
    # Your aliases from your current .gitconfig
```

### Integration with Existing Script

Update your main script to handle your existing setup:

```bash
# In your setup.sh, replace the current setup_chezmoi with:
setup_chezmoi() {
    print_header "Setting up Chezmoi for dotfile management"
    
    # Install Chezmoi first
    if ! command_exists chezmoi; then
        print_step "Installing Chezmoi..."
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    # Check for existing Windows dotfiles
    setup_unified_chezmoi_with_existing_repo
}
```

## Specific Recommendations for Your Use Case

Given your existing setup:

1. **If you want minimal changes**: Keep Windows symlinks, use Chezmoi only for WSL
   - Pros: No disruption to Windows workflow
   - Cons: Can't share configs between Windows/WSL easily

2. **If you want the best setup** (recommended): Migrate both to Chezmoi
   - Pros: One system, automatic sync, handles differences
   - Cons: Initial setup time (1-2 hours)

3. **Hybrid approach**: Not recommended as it's complex to maintain

### Migration Checklist

If you choose to migrate everything:

- [ ] Backup existing dotfiles repo
- [ ] Install Chezmoi on Windows
- [ ] Convert each symlinked file to Chezmoi management
- [ ] Create templates for shared configs (Git, VS Code)
- [ ] Set up WSL to use same Chezmoi source
- [ ] Test on both platforms
- [ ] Update your dotfiles README

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