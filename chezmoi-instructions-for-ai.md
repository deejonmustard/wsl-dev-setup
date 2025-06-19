# Chezmoi Instructions for AI Implementation

## User's Specific Setup

The user has a **unique but valid** dotfile management approach:

1. **Windows Side**: 
   - Dotfiles stored in `C:\Users\12157\dotfiles`
   - Programs read configs through symlinks
   - Example: `C:\mpv\portable_config\mpv.conf` → symlink → `C:\Users\12157\dotfiles\.mpv\mpv.conf`

2. **WSL Side**:
   - Wants to manage these same files using chezmoi
   - Should edit files in WSL, have changes reflect in Windows programs
   - Also needs to add WSL-specific configs

## Critical Script Fixes Required

### Issue 1: Script Creates Wrong Directory

**Current behavior**: Script creates `~/dotfiles` in WSL
**Required behavior**: Use existing Windows dotfiles directory

### Fix for setup_chezmoi function:

```bash
setup_chezmoi() {
    print_header "Setting up Chezmoi for dotfile management"
    
    # Install chezmoi first
    if ! command_exists chezmoi; then
        print_step "Installing Chezmoi..."
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
        export PATH="$HOME/.local/bin:$PATH"
    fi
    
    # Detect Windows username
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
    if [ -z "$WIN_USER" ]; then
        print_step "Enter your Windows username:"
        read -r WIN_USER
    fi
    
    # Check for existing Windows dotfiles
    WIN_DOTFILES="/mnt/c/Users/$WIN_USER/dotfiles"
    
    if [ -d "$WIN_DOTFILES" ]; then
        print_success "Found existing dotfiles at $WIN_DOTFILES"
        
        # Configure chezmoi to use Windows dotfiles directory
        mkdir -p "$HOME/.config/chezmoi"
        cat > "$HOME/.config/chezmoi/chezmoi.toml" << EOF
sourceDir = "$WIN_DOTFILES"

[data]
    name = "$GIT_NAME"
    email = "$GIT_EMAIL"
    windowsUser = "$WIN_USER"
    
[edit]
    command = "nvim"
EOF
        
        print_success "Chezmoi configured to use Windows dotfiles"
        
        # Do NOT create a new dotfiles directory
        # Do NOT clone a new repo
        # Use the existing Windows dotfiles
        
        CHEZMOI_SOURCE_DIR="$WIN_DOTFILES"
    else
        # Fallback to original behavior if no Windows dotfiles found
        print_warning "No Windows dotfiles found, creating new WSL dotfiles"
        ensure_dir "$HOME/dotfiles"
        CHEZMOI_SOURCE_DIR="$HOME/dotfiles"
    fi
}
```

### Issue 2: Git Repository Handling

**Current behavior**: Creates new git repo in WSL
**Required behavior**: Use existing git repo in Windows dotfiles

### Fix for setup_dotfiles_repo function:

```bash
setup_dotfiles_repo() {
    print_header "Setting up dotfiles repository"
    
    # Change to the chezmoi source directory
    cd "$CHEZMOI_SOURCE_DIR" || return 1
    
    # Check if already a git repo
    if [ -d ".git" ]; then
        print_success "Using existing git repository"
        
        # Just ensure we have the latest
        git pull || print_warning "Could not pull latest changes"
    else
        # Only initialize if not already a repo
        print_step "Initializing git repository"
        git init
        git add .
        git commit -m "Initial commit"
    fi
    
    # The rest remains the same...
}
```

## Key Principles for Implementation

### 1. Respect Existing Setup
- Never delete or move the Windows dotfiles
- Never break the Windows symlinks
- Work WITH the existing structure

### 2. Performance Considerations
- Accessing `/mnt/c` is slower than native WSL
- This is acceptable for config files (small, infrequent edits)
- Document this tradeoff for users

### 3. Line Ending Management
```bash
# Add to the script's git configuration
git config --global core.autocrlf input  # In WSL
```

### 4. Template Usage
Encourage templates for cross-platform configs:
- `.gitconfig.tmpl` for different editors/paths
- Shell configs that detect WSL vs native Linux

## Testing Checklist

Before considering the script ready:

1. ✅ Detects existing Windows dotfiles directory
2. ✅ Configures chezmoi to use Windows directory
3. ✅ Doesn't create duplicate dotfiles in WSL
4. ✅ Preserves existing git history
5. ✅ Handles line endings correctly
6. ✅ Allows adding WSL-specific configs
7. ✅ Works with the user's symlink setup

## Common User Mistakes to Prevent

1. **Don't run chezmoi init**: The script handles this
2. **Don't move Windows files**: They stay where they are
3. **Don't recreate symlinks**: Windows symlinks remain untouched

## Success Validation

The user should be able to:
1. Edit `.mpv/mpv.conf` in WSL using nvim
2. See changes immediately in Windows mpv (through symlink)
3. Commit changes to their existing git repo
4. Add new WSL configs alongside Windows configs

## Integration with Existing Workflow

The beauty of this setup:
- Windows programs: Read through symlinks (no change)
- Chezmoi: Manages actual files in dotfiles directory
- Git: Tracks all changes in one place
- User: Edits from either Windows or WSL

This is actually an elegant solution that leverages the best of both systems!