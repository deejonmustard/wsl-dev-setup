# Your Specific Chezmoi Setup: Windows Symlinks + WSL Management

## Your Current Setup (Which Works Great with Chezmoi!)

You have:
```
C:\Users\12157\dotfiles\.mpv\mpv.conf (actual file)
                ↑
                symlink
                ↓
C:\mpv\portable_config\mpv.conf (where mpv reads)
```

This is **perfect** for chezmoi because:
- Chezmoi manages the actual files in your dotfiles directory
- Your symlinks remain untouched
- Programs continue reading through symlinks as before

## Step-by-Step Setup

### 1. Configure Chezmoi in WSL to Use Your Windows Dotfiles

```bash
# Create chezmoi config
mkdir -p ~/.config/chezmoi

# Point chezmoi to your Windows dotfiles
cat > ~/.config/chezmoi/chezmoi.toml << 'EOF'
sourceDir = "/mnt/c/Users/12157/dotfiles"

[data]
    name = "Your Name"
    email = "your.email@example.com"
    
[edit]
    command = "nvim"
EOF
```

### 2. Initialize Your Existing Dotfiles

```bash
# Since you already have a dotfiles folder with a git repo
cd /mnt/c/Users/12157/dotfiles

# If not already a git repo, initialize it
git init

# Create initial commit if needed
git add .
git commit -m "Initial commit: My Windows dotfiles"

# Set up GitHub remote
git remote add origin https://github.com/deejonmustard/dotfiles.git
git push -u origin main
```

### 3. Working with Your Dotfiles

**Add existing files to chezmoi management**:
```bash
# For your mpv config
chezmoi add /mnt/c/Users/12157/dotfiles/.mpv/mpv.conf

# For your git config
chezmoi add /mnt/c/Users/12157/dotfiles/.gitconfig
```

**Edit files through chezmoi**:
```bash
# This opens the file in nvim
chezmoi edit .mpv/mpv.conf

# Apply changes (saves to the actual file)
chezmoi apply
```

**Your Windows programs automatically see changes** because they're reading through symlinks!

### 4. Adding WSL-Specific Configs

For files that only exist in WSL:
```bash
# Add WSL configs
chezmoi add ~/.bashrc
chezmoi add ~/.zshrc
chezmoi add ~/.config/nvim
```

These will be stored alongside your Windows configs in `/mnt/c/Users/12157/dotfiles`.

### 5. Handling Platform Differences with Templates

For configs used on both Windows and WSL (like Git):

Create `.gitconfig.tmpl`:
```ini
[user]
    name = {{ .name }}
    email = {{ .email }}

[core]
{{- if eq .chezmoi.os "windows" }}
    autocrlf = true
    editor = "code --wait"
{{- else if (.chezmoi.kernel.osrelease | lower | contains "microsoft") }}
    autocrlf = input
    editor = nvim
    # Share Windows SSH keys
    sshCommand = "/mnt/c/Windows/System32/OpenSSH/ssh.exe"
{{- end }}

[credential]
    # Always use Windows credential manager
    helper = /mnt/c/Program\\ Files/Git/mingw64/bin/git-credential-manager.exe
```

### 6. Daily Workflow

**Morning sync**:
```bash
# Pull any changes
cd /mnt/c/Users/12157/dotfiles
git pull

# Apply to WSL configs
chezmoi apply
```

**After making changes**:
```bash
# See what changed
chezmoi diff

# Commit and push
cd $(chezmoi source-path)
git add .
git commit -m "Update configs"
git push
```

## Important Notes for Your Setup

### Performance Consideration
- Editing through `/mnt/c` is slightly slower than native WSL files
- But since you're only editing config files (small), this is negligible
- Your setup avoids the performance issues of symlinks because programs read real files

### Line Endings
- Git should be configured to handle CRLF/LF automatically
- Chezmoi respects your git settings
- Your Windows programs will continue to work normally

### What You Don't Need to Change
- ✅ Keep your Windows symlinks exactly as they are
- ✅ Keep your dotfiles in `C:\Users\12157\dotfiles`
- ✅ Your Windows programs will work exactly as before

### What Chezmoi Adds
- ✅ Version control for all changes
- ✅ Easy editing from WSL with your preferred editor
- ✅ Templates for platform-specific configs
- ✅ Ability to add WSL-only configs to the same repo

## Quick Reference Commands

```bash
# Edit a file
chezmoi edit .mpv/mpv.conf

# Add a new file
chezmoi add /mnt/c/Users/12157/dotfiles/.config/newapp/config

# See what files are managed
chezmoi managed

# Update from git and apply
cd /mnt/c/Users/12157/dotfiles && git pull && chezmoi apply

# Create a backup
chezmoi archive --output=~/dotfiles-backup.tar.gz
```

## Troubleshooting

**"Permission denied" errors?**
- Your Windows files should be accessible from WSL by default
- If not: `sudo chmod 644 /mnt/c/Users/12157/dotfiles/file`

**Git shows all files as modified?**
- This is a line ending issue
- Fix: `git config core.autocrlf true` on Windows
- Fix: `git config core.autocrlf input` in WSL

**Slow performance?**
- Normal for `/mnt/c` access
- Only affects editing, not program usage
- Consider moving frequently-edited WSL configs to native WSL filesystem

Your setup is actually ideal for chezmoi - you get centralized management without breaking your existing Windows workflow!