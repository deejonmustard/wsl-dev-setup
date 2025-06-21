#!/bin/bash

# ===================================
# WSL Development Environment Setup
# Comprehensive development environment for WSL Arch Linux
# ===================================

# --- Color definitions for output formatting ---
NC='\033[0m'         # Reset color
GREEN='\033[0;32m'   # Success messages
YELLOW='\033[0;33m'  # Warnings/tips
BLUE='\033[0;34m'    # Information steps
RED='\033[0;31m'     # Error messages
PURPLE='\033[0;35m'  # Titles
CYAN='\033[0;36m'    # Section headers

# --- Global configuration ---
SCRIPT_VERSION="0.0.1"
SETUP_DIR="$HOME/dev"
DOTFILES_DIR=""  # Will be determined based on user preference
USE_CHEZMOI=false
CHEZMOI_SOURCE_DIR=""
GITHUB_USERNAME=""
GITHUB_TOKEN=""
USE_GITHUB=false
GITHUB_REPO_CREATED=false
INTERACTIVE_MODE=false
GIT_NAME=""
GIT_EMAIL=""

# --- Utility functions ---

# Set error handling
set -euo pipefail

# Trap for cleanup on exit
trap 'cleanup_on_exit' INT TERM

# Cleanup function
cleanup_on_exit() {
    echo -e "\n${RED}Script interrupted. Cleaning up...${NC}"
    # Remove temporary files
    rm -rf /tmp/kickstart-nvim-*
    rm -rf /tmp/JetBrainsMono.zip
    # Reset terminal colors
    echo -e "${NC}"
}

# Print a section header
print_header() {
    echo -e "\n${CYAN}==== $1 ====${NC}"
}

# Print a step message (for individual actions)
print_step() {
    echo -e "${BLUE}→ $1${NC}"
}

# Print success message
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Print warning message
print_warning() {
    echo -e "${YELLOW}! $1${NC}"
}

# Print error message
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Create directory if it doesn't exist
ensure_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        if [ $? -ne 0 ]; then
            echo -e "${RED}ERROR: Failed to create directory: $1${NC}"
            return 1
        fi
    fi
    return 0
}

# --- Bootstrap Functions ---

# Check if running as root and handle initial setup
bootstrap_arch() {
    print_header "Bootstrapping Arch Linux WSL Environment"
    
    # Check if we're running as root
    if [ "$EUID" -eq 0 ]; then
        print_warning "Running as root. Setting up basic environment..."
        
        # Initialize pacman keyring if needed
        if [ ! -d /etc/pacman.d/gnupg ]; then
            print_step "Initializing pacman keyring..."
            pacman-key --init
            pacman-key --populate
        fi
        
        # Update system first
        if [ "$INTERACTIVE_MODE" = false ]; then
            print_step "Updating system packages (auto-accepting all prompts)..."
            pacman -Syu --noconfirm --noprogressbar 2>&1 | grep -v "warning: insufficient columns"
        else
            print_step "Updating system packages..."
            pacman -Syu --noprogressbar 2>&1 | grep -v "warning: insufficient columns"
        fi
        
        # Generate locale to fix perl warnings
        print_step "Generating locale..."
        sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
        locale-gen
        echo "LANG=en_US.UTF-8" > /etc/locale.conf
        
        # Install sudo if not present
        if ! command_exists sudo; then
            if [ "$INTERACTIVE_MODE" = false ]; then
                print_step "Installing sudo (auto-accepting prompts)..."
                pacman -S --noconfirm --needed sudo 2>&1 | grep -v "warning: insufficient columns"
            else
                print_step "Installing sudo..."
                pacman -S --needed sudo 2>&1 | grep -v "warning: insufficient columns"
            fi
            if [ ${PIPESTATUS[0]} -ne 0 ]; then
                print_error "Failed to install sudo"
                exit 1
            fi
        fi
        
        # Ask if user wants to create a new user
        echo -e "\n${BLUE}You're currently running as root. Would you like to create a new user? (recommended) (y/n) [y]${NC}"
        read -r create_user
        create_user=${create_user:-y}
        
        if [[ "$create_user" =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}Enter username for the new user:${NC}"
            read -r new_username
            
            if [ -n "$new_username" ]; then
                # Check if user already exists
                if id "$new_username" &>/dev/null; then
                    print_step "User $new_username already exists"
                    
                    # Check if user is in wheel group
                    if ! groups "$new_username" | grep -q wheel; then
                        print_step "Adding $new_username to wheel group..."
                        usermod -a -G wheel "$new_username"
                    fi
                    
                    # Ask if they want to reset password
                    echo -e "${BLUE}Would you like to reset the password for $new_username? (y/n) [n]${NC}"
                    read -r reset_password
                    if [[ "$reset_password" =~ ^[Yy]$ ]]; then
                        echo -e "${BLUE}Please set a password for $new_username:${NC}"
                        passwd "$new_username"
                    fi
                else
                    # Create user with home directory
                    print_step "Creating user $new_username..."
                    useradd -m -G wheel -s /bin/bash "$new_username"
                    
                    # Set password
                    echo -e "${BLUE}Please set a password for $new_username:${NC}"
                    passwd "$new_username"
                fi
                
                # Configure sudo for wheel group (always ensure this is set)
                print_step "Configuring sudo access..."
                echo "%wheel ALL=(ALL:ALL) ALL" > /etc/sudoers.d/wheel
                
                # Set as default WSL user (always ensure this is set)
                print_step "Setting $new_username as default WSL user..."
                echo "[user]" > /etc/wsl.conf
                echo "default=$new_username" >> /etc/wsl.conf
                
                print_success "User $new_username configured successfully!"
                print_warning "Please restart WSL and run this script again as $new_username"
                print_step "To restart WSL, run in PowerShell: wsl.exe --terminate archlinux"
                exit 0
            fi
        fi
        
        print_warning "Continuing as root user..."
    else
        # Running as regular user, check if sudo works
        if ! command_exists sudo; then
            print_error "sudo is not installed and you're not running as root"
            print_warning "Please run this script as root first to set up the environment"
            exit 1
        fi
        
        # Test sudo access
        if ! sudo -n true 2>/dev/null; then
            print_step "Testing sudo access..."
            sudo true
            if [ $? -ne 0 ]; then
                print_error "Failed to obtain sudo access"
                exit 1
            fi
        fi
        
        # Check and fix locale if needed
        if ! locale 2>&1 | grep -q "LANG=en_US.UTF-8"; then
            print_step "Fixing locale settings..."
            if run_elevated grep -q "^en_US.UTF-8 UTF-8" /etc/locale.gen; then
                run_elevated locale-gen
            else
                run_elevated sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
                run_elevated locale-gen
            fi
            if [ ! -f /etc/locale.conf ] || ! grep -q "LANG=en_US.UTF-8" /etc/locale.conf; then
                echo "LANG=en_US.UTF-8" | run_elevated tee /etc/locale.conf > /dev/null
            fi
        fi
    fi
    
    print_success "Bootstrap checks completed"
}

# Wrapper for commands that need elevated privileges
run_elevated() {
    if [ "$EUID" -eq 0 ]; then
        # Already root, run directly
        "$@"
    else
        # Use sudo
        sudo "$@"
    fi
}

# Robust package installation with retry logic
install_packages_robust() {
    local packages="$1"
    local description="${2:-packages}"
    local max_attempts=2
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        print_step "Installing $description (attempt $attempt of $max_attempts)..."
        
        # Handle provider selection automatically in non-interactive mode
        if [ "$INTERACTIVE_MODE" = false ]; then
            # Auto-select first option for any provider prompts (like jack)
            printf "1\n" | run_elevated pacman -S --noconfirm --needed $packages 2>&1 | grep -v "warning: insufficient columns"
            local install_result=${PIPESTATUS[1]}
        else
            run_elevated pacman -S --noconfirm --needed $packages 2>&1 | grep -v "warning: insufficient columns"
            local install_result=${PIPESTATUS[0]}
        fi
        
        if [ $install_result -eq 0 ]; then
            print_success "$description installed successfully"
            return 0
        else
            if [ $attempt -lt $max_attempts ]; then
                print_warning "Installation failed, switching to more reliable mirrors..."
                use_emergency_mirrors
                sleep 1
            else
                print_error "Failed to install $description after $max_attempts attempts"
                return 1
            fi
        fi
        
        attempt=$((attempt + 1))
    done
    
    return 1
}

# Function to safely add a file to chezmoi when chezmoi is enabled
safe_add_to_chezmoi() {
    # Only proceed if chezmoi is enabled
    if [ "$USE_CHEZMOI" != true ]; then
        return 0
    fi
    
    local target_file="$1"
    local description="${2:-file}"
    local force="${3:-}"
    
    if [ ! -f "$target_file" ]; then
        print_error "$description not found at $target_file"
        return 1
    fi
    
    print_step "Managing $description with chezmoi..."
    if [ "$force" = "--force" ]; then
        # Use --force and auto-answer no to template attribute questions (avoid template processing)
        printf "no\n" | chezmoi add --force "$target_file" 2>/dev/null || true
    else
        # Auto-answer no to template attribute questions (avoid template processing)
        printf "no\n" | chezmoi add "$target_file" 2>/dev/null || true
    fi
    
    if [ $? -eq 0 ]; then
        print_success "$description managed by chezmoi"
        return 0
    else
        print_error "Failed to add $description to chezmoi"
        return 1
    fi
}

# Initialize NVM environment
init_nvm() {
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
}

# Backup a file if it exists
backup_file() {
    local file_path="$1"
    if [ -f "$file_path" ]; then
        local backup_path="${file_path}.backup.$(date +%Y%m%d%H%M%S)"
        print_step "Backing up existing $(basename "$file_path") file..."
        mv "$file_path" "$backup_path"
        print_step "Backed up to $backup_path"
        return 0
    fi
    return 1
}

# --- Main functions ---

# Create the necessary directory structure
setup_workspace() {
    print_header "Creating Workspace Structure"
    print_step "Setting up directory structure..."

    # Main directory structure
    ensure_dir ~/dev || return 1
    ensure_dir ~/.local/bin || return 1
    ensure_dir ~/bin || return 1

    # Create projects directory
    ensure_dir ~/dev/projects || return 1
    
    # Note: Config files are stored in the dotfiles directory, not in dev/configs
    ensure_dir ~/dev/bin || return 1
    ensure_dir ~/dev/docs || return 1

    SETUP_DIR="$HOME/dev"
    cd "$SETUP_DIR" || { 
        print_error "Failed to change directory to $SETUP_DIR"
        return 1
    }
    
    print_success "Directory structure created successfully"
    return 0
}

# Determine dotfiles directory based on user preference
determine_dotfiles_directory() {
    print_header "Setting up Dotfiles Directory"
    
    # Get Windows username
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
    if [ -z "$WIN_USER" ]; then
        print_step "Enter your Windows username:"
        read -r WIN_USER
    fi
    
    # Check for existing Windows dotfiles
    WIN_DOTFILES="/mnt/c/Users/$WIN_USER/dotfiles"
    
    if [ -d "$WIN_DOTFILES" ]; then
        print_success "Found existing dotfiles at $WIN_DOTFILES"
        DOTFILES_DIR="$WIN_DOTFILES"
    else
        echo -e "\n${CYAN}Choose your dotfiles storage location:${NC}"
        echo -e "${BLUE}1) Unified Windows + WSL location (recommended for cross-platform editing)${NC}"
        echo -e "   - Dotfiles stored in Windows-accessible location"
        echo -e "   - Edit from both Windows and WSL"
        echo -e ""
        echo -e "${BLUE}2) WSL-only location${NC}"
        echo -e "   - Traditional Linux approach"
        echo -e "   - Dotfiles stored in WSL home directory"
        echo -e ""
        
        read -p "Enter your choice (1 or 2) [1]: " choice
        choice=${choice:-1}
        
        case $choice in
            1)
                DOTFILES_DIR="/mnt/c/Users/$WIN_USER/dotfiles"
                print_step "Using unified Windows-accessible dotfiles directory: $DOTFILES_DIR"
                ;;
            2)
                DOTFILES_DIR="$HOME/dotfiles"
                print_step "Using WSL-only dotfiles directory: $DOTFILES_DIR"
                ;;
            *)
                print_warning "Invalid choice, using unified approach"
                DOTFILES_DIR="/mnt/c/Users/$WIN_USER/dotfiles"
                ;;
        esac
    fi
    
    # Create dotfiles directory
    ensure_dir "$DOTFILES_DIR" || return 1
    
    # Create subdirectories for organization
    ensure_dir "$DOTFILES_DIR/.config" || return 1
    ensure_dir "$DOTFILES_DIR/.config/nvim" || return 1
    ensure_dir "$DOTFILES_DIR/.config/tmux" || return 1
    ensure_dir "$DOTFILES_DIR/bin" || return 1
    
    # Export DOTFILES_DIR as global variable
    export DOTFILES_DIR
    
    # Verify directory exists and is accessible
    if [ ! -d "$DOTFILES_DIR" ]; then
        print_error "Dotfiles directory creation failed: $DOTFILES_DIR"
        return 1
    fi
    
    if [ ! -w "$DOTFILES_DIR" ]; then
        print_error "Dotfiles directory is not writable: $DOTFILES_DIR"
        return 1
    fi
    
    print_success "Dotfiles directory configured at: $DOTFILES_DIR"
    print_step "Directory verified: $(ls -ld "$DOTFILES_DIR")"
    
    # Show cross-platform information if using unified directory
    if [[ "$DOTFILES_DIR" == "/mnt/c/"* ]]; then
        echo -e "\n${CYAN}Cross-Platform Access:${NC}"
        echo -e "${BLUE}→ Windows path: $(echo "$DOTFILES_DIR" | sed 's|/mnt/c|C:|')${NC}"
        echo -e "${BLUE}→ Edit from Windows: Open the above path in your editor${NC}"
        echo -e "${BLUE}→ Edit from WSL: Access at $DOTFILES_DIR${NC}"
    fi
    
    return 0
}

# Ask if user wants to use chezmoi
ask_chezmoi() {
    print_header "Dotfile Management Setup"
    
    echo -e "\n${CYAN}Would you like to use Chezmoi for dotfile management?${NC}"
    echo -e "${BLUE}Chezmoi helps manage your configuration files across systems.${NC}"
    echo -e ""
    echo -e "${GREEN}Benefits:${NC}"
    echo -e "  • Version control for all your config files"
    echo -e "  • Easy syncing across multiple machines"
    echo -e "  • Template support for machine-specific configs"
    echo -e "  • Automatic backups before applying changes"
    echo -e ""
    echo -e "${YELLOW}Note: You can always set this up later if you prefer.${NC}"
    echo -e ""
    
    read -p "Use Chezmoi for dotfile management? (y/n) [n]: " use_chezmoi_response
    use_chezmoi_response=${use_chezmoi_response:-n}
    
    if [[ "$use_chezmoi_response" =~ ^[Yy]$ ]]; then
        USE_CHEZMOI=true
        print_success "Chezmoi will be configured for dotfile management"
        
        # Set the chezmoi source directory to the dotfiles directory
        CHEZMOI_SOURCE_DIR="$DOTFILES_DIR"
        
        return 0
    else
        USE_CHEZMOI=false
        print_step "Skipping Chezmoi setup"
        print_step "Your dotfiles will be stored in: $DOTFILES_DIR"
        print_step "To set up Chezmoi later, see: ~/dev/docs/dotfile-management.md"
        return 0
    fi
}

# Setup Chezmoi for dotfile management (only called if user wants it)
setup_chezmoi() {
    print_header "Setting up Chezmoi for dotfile management"
    
    # Install chezmoi first
    if ! command_exists chezmoi; then
        print_step "Installing Chezmoi..."
        sh -c "$(curl -fsLS get.chezmoi.io)" -- -b ~/.local/bin
        if [ $? -ne 0 ]; then
            print_error "Failed to install Chezmoi"
            print_warning "Make sure you have internet connectivity"
            return 1
        fi
        
        # Add to PATH for current session
        export PATH="$HOME/.local/bin:$PATH"
        print_success "Chezmoi installed successfully!"
    else
        print_step "Chezmoi is already installed"
        chezmoi --version
    fi
    
    # Get Git user configuration if not already set
    if [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ]; then
        if command_exists git; then
            GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
            GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
        fi
    fi
    
    # Configure chezmoi
    mkdir -p "$HOME/.config/chezmoi"
    print_step "Configuring chezmoi to use dotfiles directory: $CHEZMOI_SOURCE_DIR"
    
    # Get Windows username for cross-platform support
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
    
    cat > "$HOME/.config/chezmoi/chezmoi.toml" << EOF
# Chezmoi configuration for WSL development environment
sourceDir = "$CHEZMOI_SOURCE_DIR"

[data]
    name = "$GIT_NAME"
    email = "$GIT_EMAIL"
    windowsUser = "$WIN_USER"
    
[edit]
    command = "nvim"
EOF
    
    # Initialize git repo in the source directory if not already present
    if [ ! -d "$CHEZMOI_SOURCE_DIR/.git" ]; then
        print_step "Initializing git repository in dotfiles..."
        cd "$CHEZMOI_SOURCE_DIR" || return 1
        git init
        
        # Create .gitignore if it doesn't exist
        if [ ! -f ".gitignore" ]; then
            print_step "Creating .gitignore file..."
            cat > ".gitignore" << 'EOL'
# Editor temporary files
*~
*.swp
*.swo
.DS_Store
Thumbs.db

# Neovim specific
lazy-lock.json
.netrwhist

# Node.js
node_modules/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
venv/
.env

# Machine-specific files
.chezmoi.toml.local
EOL
        fi
        
        # Create initial commit if needed
        if ! git rev-parse HEAD >/dev/null 2>&1; then
            git add .
            git commit -m "Initial commit: My dotfiles"
        fi
        
        cd "$HOME" || return 1
    fi
    
    # Create README if it doesn't exist
    if [ ! -f "$CHEZMOI_SOURCE_DIR/README.md" ]; then
        cat > "$CHEZMOI_SOURCE_DIR/README.md" << 'EOL'
# My Dotfiles

This directory contains my dotfiles managed by [chezmoi](https://www.chezmoi.io).

## Quick Start

To apply dotfiles on a new machine:

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# Initialize from this repo
chezmoi init <your-github-username>

# Apply the dotfiles
chezmoi apply
```

## Daily Usage

```bash
# See what would change
chezmoi diff

# Apply changes
chezmoi apply

# Add a new file
chezmoi add ~/.zshrc

# Edit a managed file
chezmoi edit ~/.zshrc

# Update from remote
chezmoi update
```
EOL
    fi
    
    print_success "Chezmoi setup completed"
    
    # Show helpful chezmoi commands
    echo -e "\n${CYAN}Helpful chezmoi commands:${NC}"
    echo -e "${BLUE}→ chezmoi add ~/.zshrc${NC}    # Add a file to be managed"
    echo -e "${BLUE}→ chezmoi edit ~/.zshrc${NC}   # Edit a managed file"
    echo -e "${BLUE}→ chezmoi diff${NC}            # See what would change"
    echo -e "${BLUE}→ chezmoi apply${NC}           # Apply changes"
    echo -e "${BLUE}→ chezmoi update${NC}          # Pull and apply latest changes"
    echo -e "${BLUE}→ chezmoi cd${NC}              # Open shell in source directory"
    
    return 0
}

# Optimize mirrors for better download speeds
optimize_mirrors() {
    print_header "Optimizing Package Mirrors"
    
    # Install reflector if not already installed
    if ! command_exists reflector; then
        print_step "Installing reflector for mirror optimization..."
        run_elevated pacman -S --noconfirm --needed reflector 2>&1 | grep -v "warning: insufficient columns"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            print_warning "Failed to install reflector, using curated fast mirrors"
            use_fallback_mirrors
            return 0
        fi
    fi
    
    # Backup current mirrorlist
    print_step "Backing up current mirrorlist..."
    run_elevated cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.backup
    
    # Generate optimized mirrorlist with shorter timeout to avoid hanging
    print_step "Generating optimized mirrorlist (this may take a moment)..."
    
    # Use a more conservative reflector command with shorter timeout
    if [ "$EUID" -eq 0 ]; then
        timeout 60 reflector \
            --age 12 \
            --latest 15 \
            --fastest 10 \
            --threads 10 \
            --sort rate \
            --protocol https \
            --save /etc/pacman.d/mirrorlist
    else
        timeout 60 sudo reflector \
            --age 12 \
            --latest 15 \
            --fastest 10 \
            --threads 10 \
            --sort rate \
            --protocol https \
            --save /etc/pacman.d/mirrorlist
    fi
    
    if [ $? -eq 0 ]; then
        print_success "Mirrors optimized successfully"
        
        # Test the new mirrors with a quick sync
        print_step "Testing mirror performance..."
        if [ "$EUID" -eq 0 ]; then
            timeout 30 pacman -Sy --noconfirm >/dev/null 2>&1
        else
            timeout 30 sudo pacman -Sy --noconfirm >/dev/null 2>&1
        fi
        
        if [ $? -ne 0 ]; then
            print_warning "Optimized mirrors are slow, switching to curated fast mirrors"
            use_fallback_mirrors
        fi
    else
        print_warning "Mirror optimization failed, using curated fast mirrors"
        use_fallback_mirrors
    fi
    
    return 0
}

# Use curated list of fast, reliable mirrors
use_fallback_mirrors() {
    print_step "Using curated fast mirror list..."
    
    # List of globally fast and reliable mirrors based on current mirror status
    if [ "$EUID" -eq 0 ]; then
        tee /etc/pacman.d/mirrorlist > /dev/null << 'EOF'
# Curated fast mirror list - updated for current performance
# Based on mirror status and community feedback

# United States - Consistently fast
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://mirror.arizona.edu/archlinux/$repo/os/$arch
Server = https://mirrors.lug.mtu.edu/archlinux/$repo/os/$arch
Server = https://repo.ialab.dsu.edu/archlinux/$repo/os/$arch

# Europe - High performance
Server = https://mirror.selfnet.de/archlinux/$repo/os/$arch
Server = https://arch.mirror.constant.com/$repo/os/$arch
Server = https://mirrors.dotsrc.org/archlinux/$repo/os/$arch

# Global CDN - Reliable fallbacks
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://archlinux.thaller.ws/$repo/os/$arch
EOF
    else
        sudo tee /etc/pacman.d/mirrorlist > /dev/null << 'EOF'
# Curated fast mirror list - updated for current performance
# Based on mirror status and community feedback

# United States - Consistently fast
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://mirror.arizona.edu/archlinux/$repo/os/$arch
Server = https://mirrors.lug.mtu.edu/archlinux/$repo/os/$arch
Server = https://repo.ialab.dsu.edu/archlinux/$repo/os/$arch

# Europe - High performance
Server = https://mirror.selfnet.de/archlinux/$repo/os/$arch
Server = https://arch.mirror.constant.com/$repo/os/$arch
Server = https://mirrors.dotsrc.org/archlinux/$repo/os/$arch

# Global CDN - Reliable fallbacks
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://archlinux.thaller.ws/$repo/os/$arch
EOF
    fi
    
    print_success "Curated fast mirrors configured"
    
    # Update package database with new mirrors
    print_step "Updating package database with fast mirrors..."
    if [ "$EUID" -eq 0 ]; then
        pacman -Sy --noconfirm 2>&1 | grep -v "warning: insufficient columns"
    else
        sudo pacman -Sy --noconfirm 2>&1 | grep -v "warning: insufficient columns"
    fi
}

# Test mirror connectivity and warn user if issues persist
test_mirror_connectivity() {
    print_step "Testing mirror connectivity..."
    
    # Quick test with a small package info fetch
    if [ "$EUID" -eq 0 ]; then
        timeout 15 pacman -Si bash >/dev/null 2>&1
    else
        timeout 15 sudo pacman -Si bash >/dev/null 2>&1
    fi
    
    if [ $? -ne 0 ]; then
        print_warning "Mirror connectivity issues detected"
        echo -e "${YELLOW}Your current mirrors may be slow or experiencing issues.${NC}"
        echo -e "${YELLOW}The script will continue with retry logic, but installations may take longer.${NC}"
        echo -e "${BLUE}If you experience repeated failures, you may want to:${NC}"
        echo -e "${BLUE}1. Check your internet connection${NC}"
        echo -e "${BLUE}2. Try running the script again later${NC}"
        echo -e "${BLUE}3. Use: ./setup.sh --interactive for more control${NC}"
        echo -e ""
        
        if [ "$INTERACTIVE_MODE" = true ]; then
            echo -e "${CYAN}Continue with current mirrors? (y/n) [y]${NC}"
            read -r continue_setup
            continue_setup=${continue_setup:-y}
            
            if [[ ! "$continue_setup" =~ ^[Yy]$ ]]; then
                print_warning "Setup cancelled by user"
                exit 1
            fi
        else
            print_step "Continuing in non-interactive mode with retry logic..."
            sleep 2
        fi
    else
        print_success "Mirror connectivity test passed"
    fi
}

# Update system packages
update_system() {
    print_header "Updating System Packages"
    if [ "$INTERACTIVE_MODE" = false ]; then
        print_step "Updating package database (auto-accepting all prompts)..."
        if [ "$EUID" -eq 0 ]; then
            pacman -Syu --noconfirm --noprogressbar 2>&1 | grep -v "warning: insufficient columns"
        else
            sudo pacman -Syu --noconfirm --noprogressbar 2>&1 | grep -v "warning: insufficient columns"
        fi
    else
        print_step "Updating package database..."
        if [ "$EUID" -eq 0 ]; then
            pacman -Syu --noprogressbar 2>&1 | grep -v "warning: insufficient columns"
        else
            sudo pacman -Syu --noprogressbar 2>&1 | grep -v "warning: insufficient columns"
        fi
    fi
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Failed to update system packages"
        return 1
    fi
    
    print_success "System packages current"
    return 0
}

# Install core dependencies
install_core_deps() {
    print_header "Installing Core Dependencies"
    print_step "Installing essential packages..."
    
    # Export COLUMNS to help pacman format output better
    export COLUMNS=120
    
    install_packages_robust "curl wget git python python-pip python-virtualenv unzip base-devel file cmake ripgrep fd fzf tmux zsh jq bat htop github-cli" "core dependencies"
    
    if [ $? -ne 0 ]; then
        print_error "Failed to install core dependencies"
        print_warning "You may need to run 'sudo pacman -Syu' first or try the script again"
        return 1
    fi
    
    # Add local bin to PATH in bashrc if not already there
    if ! grep -q 'PATH="$HOME/.local/bin:$HOME/bin:$PATH"' ~/.bashrc; then
        echo 'export PATH="$HOME/.local/bin:$HOME/bin:$PATH"' >> ~/.bashrc
    fi
    
    # Add NVM to bashrc if it's not already there (will be needed later)
    if ! grep -q "export NVM_DIR" ~/.bashrc; then
        cat >> ~/.bashrc << 'EOF'

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOF
    fi
    
    print_success "Core dependencies installed successfully"
    return 0
}

# Install modern CLI tools
install_modern_cli_tools() {
    print_header "Installing Modern CLI Tools"
    
    # Try to install Rust via pacman first (more reliable in WSL)
    if ! command_exists cargo; then
        print_step "Installing Rust via pacman..."
        install_packages_robust "rust" "Rust programming language"
        
        # If pacman installation failed, try rustup as fallback
        if ! command_exists cargo; then
            print_warning "Pacman installation failed, trying rustup..."
            print_step "Downloading and installing Rust via rustup..."
            
            # Download rustup script first to check if download works
            if curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup.sh; then
                # Run with timeout to prevent hanging
                timeout 300 sh /tmp/rustup.sh -y --no-modify-path
                if [ $? -eq 0 ]; then
                    source "$HOME/.cargo/env"
                    rm -f /tmp/rustup.sh
                else
                    print_warning "Rustup installation failed or timed out"
                    rm -f /tmp/rustup.sh
                fi
            else
                print_warning "Failed to download rustup installer"
            fi
        fi
    fi
    
    # Add cargo bin to PATH if it exists
    if [ -d "$HOME/.cargo/bin" ]; then
        export PATH="$HOME/.cargo/bin:$PATH"
    fi
    
    # Install modern CLI tools - some from pacman, some from cargo if available
    print_step "Installing modern CLI tools from package manager..."
    
    # Many of these tools are available in pacman and more reliable to install
    install_packages_robust "eza bat fd ripgrep starship lazygit ranger ncdu duf gdu zoxide" "modern CLI tools"
    
    # Only try cargo installs if cargo is available and for tools not in pacman
    if command_exists cargo; then
        print_step "Installing additional tools via Cargo..."
        # Set cargo to use fewer parallel downloads to avoid timeouts
        export CARGO_NET_RETRY=3
        export CARGO_NET_GIT_FETCH_WITH_CLI=true
        
        # Try to install bottom with timeout protection
        print_step "Installing bottom (system monitor)..."
        timeout 600 cargo install bottom || print_warning "Bottom installation failed or timed out, continuing..."
        
        # Try to install zoxide with timeout protection
        print_step "Installing zoxide (smarter cd)..."
        timeout 600 cargo install zoxide || print_warning "Zoxide installation failed or timed out, continuing..."
        
        print_step "Cargo tool installations completed (some may have been skipped due to network issues)"
    else
        print_warning "Cargo not available, skipping Rust-based tool installations"
        print_warning "You can install Rust later with: curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh"
    fi
    
    print_success "Modern CLI tools installation completed"
    return 0
}

# Setup music system (MPD + rmpc) with Windows music access
setup_music_system() {
    print_header "Setting up Music System (MPD + rmpc)"
    
    # Install MPD (Music Player Daemon) and related tools
    print_step "Installing MPD and audio dependencies..."
    install_packages_robust "mpd rmpc mpc alsa-utils pulseaudio" "music player daemon and audio system"
    
    # Get Windows username for music path
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
    if [ -z "$WIN_USER" ]; then
        WIN_USER="$USER"
    fi
    
    # Configure MPD
    local mpd_config_dir="$DOTFILES_DIR/.config/mpd"
    ensure_dir "$mpd_config_dir"
    
    # Create MPD directories
    ensure_dir "$HOME/.local/share/mpd"
    ensure_dir "$HOME/.local/share/mpd/playlists"
    
    print_step "Creating MPD configuration with Windows music access..."
    cat > "$mpd_config_dir/mpd.conf" << EOF
# MPD Configuration for WSL with Windows Music Access

# Music directory (Windows music folder)
music_directory     "/mnt/c/Users/$WIN_USER/Music"

# MPD data directories
playlist_directory  "$HOME/.local/share/mpd/playlists"
db_file             "$HOME/.local/share/mpd/database"
log_file            "$HOME/.local/share/mpd/log"
pid_file            "$HOME/.local/share/mpd/pid"
state_file          "$HOME/.local/share/mpd/state"
sticker_file        "$HOME/.local/share/mpd/sticker.sql"

# Network settings
bind_to_address     "127.0.0.1"
port                "6600"

# Audio output configuration
audio_output {
    type        "pulse"
    name        "PulseAudio Output"
    server      "unix:/mnt/wslg/PulseServer"
}

# Alternative ALSA output (fallback)
audio_output {
    type        "alsa"
    name        "ALSA Output"
    device      "default"
    enabled     "no"
}

# Performance settings
auto_update         "yes"
auto_update_depth   "3"
follow_outside_symlinks "yes"
follow_inside_symlinks  "yes"

# Input plugins
input {
    plugin "curl"
}

# Decoder plugins
decoder {
    plugin                  "mad"
    enabled                 "yes"
}

decoder {
    plugin                  "flac"
    enabled                 "yes"
}

decoder {
    plugin                  "vorbis"
    enabled                 "yes"
}

decoder {
    plugin                  "opus"
    enabled                 "yes"
}
EOF
    
    # Create symlink for MPD config
    ensure_dir "$HOME/.config"
    if [ -L "$HOME/.config/mpd" ] || [ -d "$HOME/.config/mpd" ]; then
        rm -rf "$HOME/.config/mpd"
    fi
    ln -sf "$mpd_config_dir" "$HOME/.config/mpd"
    
    # Verify the symlink works by checking if config is accessible
    if [ ! -f "$HOME/.config/mpd/mpd.conf" ]; then
        print_warning "MPD config symlink failed, creating direct config in ~/.config/mpd"
        ensure_dir "$HOME/.config/mpd"
        cp "$mpd_config_dir/mpd.conf" "$HOME/.config/mpd/mpd.conf"
    fi
    
    # Configure rmpc
    local rmpc_config_dir="$DOTFILES_DIR/.config/rmpc"
    ensure_dir "$rmpc_config_dir"
    
    print_step "Creating rmpc configuration..."
    cat > "$rmpc_config_dir/config.ron" << 'EOF'
// rmpc Configuration for WSL Music System

(
    // Connection settings
    address: "127.0.0.1:6600",
    
    // UI settings
    theme: (
        primary_color: "Blue",
        secondary_color: "Green",
        highlight_color: "Yellow",
        background_color: "Black",
        text_color: "White",
    ),
    
    // Behavior settings
    auto_update: true,
    shuffle_on_startup: false,
    repeat_mode: "Off",
    volume_step: 5,
    
    // Key bindings (vim-like)
    keybinds: (
        global: {
            "q": "Quit",
            "h": "Left",
            "j": "Down", 
            "k": "Up",
            "l": "Right",
            "g": "Top",
            "G": "Bottom",
            "/": "Search",
            "n": "NextSearchResult",
            "N": "PrevSearchResult",
            "Space": "PlayPause",
            "Enter": "Confirm",
            "Escape": "Close",
        },
        queue: {
            "d": "Delete",
            "c": "Clear",
            "s": "Shuffle",
        },
        browser: {
            "a": "AddToQueue",
            "A": "AddToPlaylist",
            "Enter": "PlayFromHere",
        },
    ),
    
    // Display settings
    show_borders: true,
    show_volume: true,
    show_progress_bar: true,
    columns: [
        "Track",
        "Title", 
        "Artist",
        "Album",
        "Duration",
    ],
)
EOF
    
    # Create symlink for rmpc config
    if [ -L "$HOME/.config/rmpc" ] || [ -d "$HOME/.config/rmpc" ]; then
        rm -rf "$HOME/.config/rmpc"
    fi
    ln -sf "$rmpc_config_dir" "$HOME/.config/rmpc"
    
    # Verify the symlink works by checking if config is accessible
    if [ ! -f "$HOME/.config/rmpc/config.ron" ]; then
        print_warning "rmpc config symlink failed, creating direct config in ~/.config/rmpc"
        ensure_dir "$HOME/.config/rmpc"
        cp "$rmpc_config_dir/config.ron" "$HOME/.config/rmpc/config.ron"
    fi
    
    # Add to chezmoi if enabled
    if [ "$USE_CHEZMOI" = true ]; then
        safe_add_to_chezmoi "$HOME/.config/mpd" "MPD music daemon configuration"
        safe_add_to_chezmoi "$HOME/.config/rmpc" "rmpc music client configuration"
    fi
    
    # Create helper scripts
    print_step "Creating music system helper scripts..."
    
    # MPD control script
    cat > "$HOME/bin/music-start" << 'EOF'
#!/bin/bash
# Start MPD daemon and rmpc client

# Ensure MPD directories exist
mkdir -p "$HOME/.local/share/mpd/playlists"

# Start MPD
echo "Starting MPD..."
mpd --no-daemon --stderr ~/.config/mpd/mpd.conf &
MPD_PID=$!

# Wait a moment for MPD to start
sleep 2

# Update database if music directory exists
if [ -d "/mnt/c/Users/$USER/Music" ]; then
    echo "Updating music database..."
    mpc update
fi

echo "MPD started (PID: $MPD_PID)"
echo "Music directory: /mnt/c/Users/$USER/Music"
echo "Run 'rmpc' to start the music client"
echo "Run 'music-stop' to stop the daemon"
EOF
    chmod +x "$HOME/bin/music-start"
    
    # MPD stop script
    cat > "$HOME/bin/music-stop" << 'EOF'
#!/bin/bash
# Stop MPD daemon

echo "Stopping MPD..."
mpd --kill ~/.config/mpd/mpd.conf 2>/dev/null || killall mpd 2>/dev/null
echo "MPD stopped"
EOF
    chmod +x "$HOME/bin/music-stop"
    
    # Quick music status script
    cat > "$HOME/bin/music-status" << 'EOF'
#!/bin/bash
# Show music system status

echo "=== Music System Status ==="
if pgrep -f "mpd" > /dev/null; then
    echo "MPD: Running"
    mpc status
else
    echo "MPD: Not running"
    echo "Run 'music-start' to start the music system"
fi

echo ""
echo "Music directory: /mnt/c/Users/$USER/Music"
if [ -d "/mnt/c/Users/$USER/Music" ]; then
    echo "Music files found: $(find "/mnt/c/Users/$USER/Music" -type f \( -name "*.mp3" -o -name "*.flac" -o -name "*.ogg" -o -name "*.m4a" \) | wc -l)"
else
    echo "Warning: Music directory not found"
fi
EOF
    chmod +x "$HOME/bin/music-status"
    
    # Add to chezmoi if enabled
    if [ "$USE_CHEZMOI" = true ]; then
        safe_add_to_chezmoi "$HOME/bin/music-start" "MPD start script"
        safe_add_to_chezmoi "$HOME/bin/music-stop" "MPD stop script"  
        safe_add_to_chezmoi "$HOME/bin/music-status" "Music status script"
    fi
    
    # Add aliases to shell config
    print_step "Adding music aliases to shell configuration..."
    
    # Add music aliases to .zshrc if it exists
    if [ -f "$DOTFILES_DIR/.zshrc" ]; then
        if ! grep -q "# Music system aliases" "$DOTFILES_DIR/.zshrc"; then
            cat >> "$DOTFILES_DIR/.zshrc" << 'EOF'

# Music system aliases
alias music='rmpc'
alias music-start='music-start'
alias music-stop='music-stop'
alias music-status='music-status'
alias mpc-update='mpc update'
EOF
        fi
    fi
    
    # Test MPD configuration by starting it briefly
    print_step "Testing MPD configuration..."
    if mpd --test ~/.config/mpd/mpd.conf >/dev/null 2>&1; then
        print_success "MPD configuration is valid"
    else
        print_warning "MPD configuration may have issues"
    fi
    
    print_success "Music system (MPD + rmpc) configured successfully"
    
    echo -e "\n${CYAN}Music System Setup Complete:${NC}"
    echo -e "${BLUE}→ Music directory: /mnt/c/Users/$WIN_USER/Music${NC}"
    echo -e "${BLUE}→ Start music system: ${GREEN}music-start${NC}"
    echo -e "${BLUE}→ Launch music client: ${GREEN}rmpc${NC} or ${GREEN}music${NC}"
    echo -e "${BLUE}→ Check status: ${GREEN}music-status${NC}"
    echo -e "${BLUE}→ Stop music system: ${GREEN}music-stop${NC}"
    echo -e ""
    echo -e "${YELLOW}Note: Run ${GREEN}music-start${YELLOW} before using ${GREEN}rmpc${YELLOW} to start the MPD daemon${NC}"
    
    return 0
}


# Install Fastfetch for system information display
install_fastfetch() {
    print_header "Installing Fastfetch"
    if ! command_exists fastfetch; then
        install_packages_robust "fastfetch" "Fastfetch (modern neofetch alternative)"
        if [ $? -ne 0 ]; then
            print_error "Failed to install Fastfetch"
            return 1
        fi
        
        # Create an alias for backward compatibility
        if ! grep -q "alias neofetch='fastfetch'" ~/.bashrc; then
            echo "alias neofetch='fastfetch'" >> ~/.bashrc
        fi
        
        print_success "Fastfetch installed successfully"
    else
        print_step "Fastfetch is already installed"
        
        # Ensure the alias exists
        if ! grep -q "alias neofetch='fastfetch'" ~/.bashrc; then
            echo "alias neofetch='fastfetch'" >> ~/.bashrc
        fi
    fi
    return 0
}

# Install Neovim text editor with retry logic for mirror issues
install_neovim() {
    print_header "Installing Neovim"
    if ! command_exists nvim; then
        print_step "Installing Neovim from official Arch repository..."
        
        # Attempt installation with retry logic for mirror issues
        local max_attempts=3
        local attempt=1
        local install_success=false
        
        while [ $attempt -le $max_attempts ] && [ "$install_success" = false ]; do
            print_step "Installation attempt $attempt of $max_attempts..."
            
            # Try installing Neovim
            if run_elevated pacman -S --noconfirm --needed neovim 2>&1 | grep -v "warning: insufficient columns"; then
                install_success=true
                print_success "Neovim installation successful"
            else
                if [ $attempt -lt $max_attempts ]; then
                    print_warning "Installation attempt $attempt failed, trying different mirrors..."
                    
                    # Switch to different mirrors for retry
                    if [ $attempt -eq 2 ]; then
                        print_step "Switching to alternative mirrors..."
                        use_fallback_mirrors
                    elif [ $attempt -eq 3 ]; then
                        print_step "Using emergency mirror configuration..."
                        use_emergency_mirrors
                    fi
                    
                    # Brief delay before retry
                    sleep 2
                else
                    print_warning "All installation attempts failed, trying alternative method..."
                fi
            fi
            
            attempt=$((attempt + 1))
        done
        
        # If pacman installation failed, try manual installation as fallback
        if [ "$install_success" = false ]; then
            print_step "Attempting manual Neovim installation as fallback..."
            install_neovim_manual
            install_success=$?
        fi
        
        if [ "$install_success" = true ] || [ $? -eq 0 ]; then
            # Create symlink in local bin for consistency
            if [ -f /usr/bin/nvim ]; then
                ln -sf /usr/bin/nvim ~/.local/bin/nvim
            fi
            
            # Verify installation
            print_step "Verifying Neovim installation..."
            if command_exists nvim; then
                nvim --version | head -1
                print_success "Neovim installed successfully"
            else
                print_error "Neovim installation verification failed"
                return 1
            fi
        else
            print_error "Failed to install Neovim after all attempts"
            return 1
        fi
    else
        print_step "Neovim is already installed"
        nvim --version | head -1
    fi
    return 0
}

# Emergency mirror configuration for critical installations
use_emergency_mirrors() {
    print_step "Configuring emergency mirrors..."
    
    # Use only the most reliable mirrors for emergency installations
    if [ "$EUID" -eq 0 ]; then
        tee /etc/pacman.d/mirrorlist > /dev/null << 'EOF'
# Emergency mirror configuration - most reliable only
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://mirror.arizona.edu/archlinux/$repo/os/$arch
Server = https://mirror.selfnet.de/archlinux/$repo/os/$arch
EOF
    else
        sudo tee /etc/pacman.d/mirrorlist > /dev/null << 'EOF'
# Emergency mirror configuration - most reliable only
Server = https://mirrors.kernel.org/archlinux/$repo/os/$arch
Server = https://mirror.arizona.edu/archlinux/$repo/os/$arch
Server = https://mirror.selfnet.de/archlinux/$repo/os/$arch
EOF
    fi
    
    # Force refresh package database
    run_elevated pacman -Sy --noconfirm >/dev/null 2>&1
}

# Manual Neovim installation fallback
install_neovim_manual() {
    print_step "Downloading Neovim manually..."
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir" || return 1
    
    # Download latest Neovim release
    local nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz"
    
    if curl -L -o nvim-linux64.tar.gz "$nvim_url"; then
        print_step "Installing Neovim manually to /opt..."
        
        # Install to /opt directory
        if run_elevated tar -C /opt -xzf nvim-linux64.tar.gz; then
            # Create symlink
            run_elevated ln -sf /opt/nvim-linux64/bin/nvim /usr/local/bin/nvim
            
            # Cleanup
            cd "$HOME" || return 1
            rm -rf "$temp_dir"
            
            print_success "Neovim installed manually"
            return 0
        else
            print_error "Failed to extract Neovim"
            cd "$HOME" || return 1
            rm -rf "$temp_dir"
            return 1
        fi
    else
        print_error "Failed to download Neovim"
        cd "$HOME" || return 1
        rm -rf "$temp_dir"
        return 1
    fi
}

# Setup nvim with Kickstart configuration 
setup_nvim_config() {
    print_header "Setting up Neovim configuration"
    
    # Ask user which version of kickstart they prefer
    echo -e "\n${CYAN}Choose your Neovim configuration style:${NC}"
    echo -e "${BLUE}1) Regular Kickstart (single init.lua file)${NC}"
    echo -e "   - Everything in one file"
    echo -e "   - Easier for beginners"
    echo -e "   - Original from nvim-lua team"
    echo -e ""
    echo -e "${BLUE}2) Modular Kickstart (multi-file structure)${NC}"
    echo -e "   - Better organization"
    echo -e "   - Easier to customize"
    echo -e "   - Same features, better structure"
    echo -e ""
    
    read -p "Enter your choice (1 or 2) [1]: " kickstart_choice
    kickstart_choice=${kickstart_choice:-1}
    
    local repo_type=""
    local default_repo=""
    
    case $kickstart_choice in
        2)
            repo_type="kickstart-modular.nvim"
            default_repo="https://github.com/dam9000/kickstart-modular.nvim.git"
            print_step "Using Modular Kickstart configuration..."
            ;;
        *)
            repo_type="kickstart.nvim"
            default_repo="https://github.com/nvim-lua/kickstart.nvim.git"
            print_step "Using Regular Kickstart configuration..."
            ;;
    esac

    # Create a temporary directory for cloning kickstart
    TEMP_NVIM_DIR=$(mktemp -d)
    
    # Check if user has an existing fork/repo
    echo -e "\n${BLUE}Do you have an existing $repo_type repository? (y/n) [n]${NC}"
    read -r has_existing_repo
    has_existing_repo=${has_existing_repo:-n}
    
    if [[ "$has_existing_repo" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}Is it:${NC}"
        echo -e "1) Your own fork on GitHub"
        echo -e "2) A local clone you want to use"
        read -r repo_source
        
        case $repo_source in
            2)
                # Local clone
                echo -e "${BLUE}Enter the full path to your local $repo_type:${NC}"
                read -r local_path
                
                if [ -d "$local_path" ]; then
                    print_step "Using existing local repository..."
                    cp -r "$local_path" "$TEMP_NVIM_DIR"
                else
                    print_warning "Path not found, falling back to default repository"
                    git clone --depth=1 "$default_repo" "$TEMP_NVIM_DIR"
                fi
                ;;
            *)
                # GitHub fork
                if $USE_GITHUB && [ -n "$GITHUB_USERNAME" ]; then
                    # Use stored GitHub username
                    print_step "Cloning from your fork at https://github.com/$GITHUB_USERNAME/$repo_type"
                    git clone --depth=1 "https://github.com/$GITHUB_USERNAME/$repo_type" "$TEMP_NVIM_DIR"
                else
                    # Ask for GitHub username
                    echo -e "${BLUE}Enter your GitHub username:${NC}"
                    read -r github_username
                    
                    if [ -z "$github_username" ]; then
                        print_warning "No username provided, falling back to default repository"
                        git clone --depth=1 "$default_repo" "$TEMP_NVIM_DIR"
                    else
                        print_step "Cloning from your fork at https://github.com/$github_username/$repo_type"
                        git clone --depth=1 "https://github.com/$github_username/$repo_type" "$TEMP_NVIM_DIR"
                    fi
                fi
                ;;
        esac
        
        # Check if clone was successful
        if [ $? -ne 0 ]; then
            print_warning "Failed to clone from fork, trying default repository..."
            git clone --depth=1 "$default_repo" "$TEMP_NVIM_DIR"
        fi
        
        # Modify .gitignore to track lazy-lock.json if it exists
        if [ -f "$TEMP_NVIM_DIR/.gitignore" ] && grep -q "lazy-lock.json" "$TEMP_NVIM_DIR/.gitignore"; then
            print_step "Modifying .gitignore to track lazy-lock.json..."
            sed -i '/lazy-lock.json/d' "$TEMP_NVIM_DIR/.gitignore"
            print_success "Modified .gitignore to track lazy-lock.json"
        fi
    else
        # No existing repo, clone default
        print_step "Installing $repo_type from official repository..."
        git clone --depth=1 "$default_repo" "$TEMP_NVIM_DIR"
    fi
    
    if [ $? -ne 0 ]; then
        print_error "Failed to clone Kickstart Neovim"
        print_warning "Make sure git is installed and you have internet connectivity"
        rm -rf "$TEMP_NVIM_DIR"
        return 1
    fi
    
    # Create the custom directory
    mkdir -p "$TEMP_NVIM_DIR/lua/custom"
    
    # Store Neovim configuration in dotfiles directory
    local nvim_config_dir="$DOTFILES_DIR/.config/nvim"
    ensure_dir "$(dirname "$nvim_config_dir")"
    
    print_step "Setting up Neovim configuration in dotfiles directory..."
    
    # Backup existing config in dotfiles if exists
    if [ -d "$nvim_config_dir" ] && [ "$(ls -A "$nvim_config_dir")" ]; then
        BACKUP_DIR="${nvim_config_dir}_backup_$(date +%Y%m%d%H%M%S)"
        print_step "Backing up existing Neovim configuration to $BACKUP_DIR"
        mv "$nvim_config_dir" "$BACKUP_DIR"
    fi
    
    # Copy configuration to dotfiles directory
    cp -r "$TEMP_NVIM_DIR" "$nvim_config_dir"
    
    # Create symlink from ~/.config/nvim to dotfiles
    if [ -L "$HOME/.config/nvim" ] || [ -d "$HOME/.config/nvim" ]; then
        print_step "Removing existing Neovim configuration..."
        rm -rf "$HOME/.config/nvim"
    fi
    
    print_step "Creating symlink for Neovim configuration..."
    mkdir -p "$HOME/.config"
    ln -sf "$nvim_config_dir" "$HOME/.config/nvim"
    
    # Add to chezmoi if enabled
    if [ "$USE_CHEZMOI" = true ]; then
        print_step "Adding Neovim configuration to chezmoi..."
        if chezmoi add "$HOME/.config/nvim"; then
            print_success "Neovim configuration added to chezmoi"
        else
            print_warning "Failed to add Neovim configuration to chezmoi"
        fi
    fi
    
    rm -rf "$TEMP_NVIM_DIR"
    
    print_success "Neovim Kickstart configuration installed"
    print_step "Configuration stored in: $nvim_config_dir"
    print_step "Symlinked to: ~/.config/nvim"
    
    return 0
}

# Enhanced Neovim setup with theme


# Setup dotfiles repository
setup_dotfiles_repo() {
    print_header "Setting up dotfiles repository"
    
    # This function works whether using chezmoi or not
    
    # Check if git is available
    if ! command_exists git; then
        print_warning "Git is not installed. Installing Git..."
        run_elevated pacman -S --noconfirm --needed git 2>&1 | grep -v "warning: insufficient columns"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            print_error "Failed to install Git"
            return 1
        fi
    fi
    
    # Ensure Git identity is configured before making commits
    if ! git config --get user.name > /dev/null || ! git config --get user.email > /dev/null; then
        print_step "Git identity not configured. Setting up Git user information..."
        
        echo -e "${BLUE}Enter your Git user name:${NC}"
        read -r git_name
        
        echo -e "${BLUE}Enter your Git email address:${NC}"
        read -r git_email
        
        if [ -n "$git_name" ] && [ -n "$git_email" ]; then
            git config --global user.name "$git_name"
            git config --global user.email "$git_email"
            print_success "Git identity configured"
        else
            print_error "Git identity not configured. Repository operations may fail."
            return 1
        fi
    fi
    
    # Set default branch to main to avoid warnings
    if ! git config --get init.defaultBranch > /dev/null; then
        git config --global init.defaultBranch main
    fi
    
    # Check if we already have a dotfiles repository
    if [ -d "$DOTFILES_DIR/.git" ]; then
        print_step "Dotfiles repository already initialized"
        
        # Change to the dotfiles directory
        cd "$DOTFILES_DIR" || return 1
        
        # Make sure we're on the main branch
        git checkout main 2>/dev/null || git checkout -b main
        
        # Check if the branch has any commits
        if ! git rev-parse --verify main >/dev/null 2>&1; then
            # If not, stage all files and make an initial commit
            print_step "Creating initial commit on main branch..."
            git add .
            if [ "$USE_CHEZMOI" = true ]; then
                git commit -m "Initial commit: My dotfiles managed by Chezmoi"
            else
                git commit -m "Initial commit: My dotfiles"
            fi
        fi
        
        # Setup GitHub repository
        if [ "$USE_CHEZMOI" = true ]; then
            setup_github_repository "dotfiles" "My dotfiles managed by Chezmoi"
        else
            setup_github_repository "dotfiles" "My WSL dotfiles"
        fi
    else
        print_step "Initializing dotfiles repository"
        
        # Initialize git in dotfiles directory
        cd "$DOTFILES_DIR" || return 1
        
        # Initialize Git and set main as the default branch
        git init -b main
        
        # Add all files
        git add .
        
        # Create initial commit with a meaningful message
        if [ "$USE_CHEZMOI" = true ]; then
            git commit -m "Initial commit: My dotfiles managed by Chezmoi"
        else
            git commit -m "Initial commit: My dotfiles"
        fi
        
        # Setup GitHub repository
        if [ "$USE_CHEZMOI" = true ]; then
            setup_github_repository "dotfiles" "My dotfiles managed by Chezmoi"
        else
            setup_github_repository "dotfiles" "My WSL dotfiles"
        fi
    fi
    
    print_success "Dotfiles repository setup completed"
    return 0
}

# Setup GitHub repository
setup_github_repository() {
    local repo_name="$1"
    local description="$2"
    
    if ! $USE_GITHUB; then
        print_warning "GitHub integration is disabled. Skipping repository creation."
        return 1
    fi
    
    # Change directory to dotfiles directory
    cd "$DOTFILES_DIR" || return 1
    
    echo -e "\n${BLUE}Do you want to push your dotfiles to a GitHub repository? (y/n) [y]${NC}"
    read -r push_to_github
    push_to_github=${push_to_github:-y}  # Default to yes
    
    if [[ "$push_to_github" =~ ^[Yy]$ ]]; then
        # GitHub CLI workflow
        if command_exists gh; then
            # Check if GitHub CLI is authenticated
            if ! gh auth status &>/dev/null; then
                print_warning "GitHub CLI is not authenticated. Please authenticate first."
                gh auth login
                if [ $? -ne 0 ]; then
                    print_error "Failed to authenticate with GitHub. Skipping repository creation."
                    return 1
                fi
            fi
            
            # Verify we have a username
            if [ -z "$GITHUB_USERNAME" ]; then
                GITHUB_USERNAME=$(gh api user | jq -r '.login')
                if [ -z "$GITHUB_USERNAME" ] || [ "$GITHUB_USERNAME" = "null" ]; then
                    print_error "Could not determine GitHub username. Repository operations may fail."
                    return 1
                fi
                print_step "Using GitHub username: $GITHUB_USERNAME"
            fi
            
            # Ask if repository should be public
            echo -e "\n${BLUE}Should the repository be public? (y/n, default: n)${NC}"
            read -r repo_public
            is_public="false"
            if [[ "$repo_public" =~ ^[Yy]$ ]]; then
                is_public="true"
            fi
            
            # Create and connect to GitHub repository
            print_step "Creating GitHub repository: $repo_name..."
            
            # Check if repository already exists
            if gh repo view "$GITHUB_USERNAME/$repo_name" &>/dev/null; then
                print_step "Repository $GITHUB_USERNAME/$repo_name already exists"
            else
                # Create the repository
                if [ "$is_public" = "true" ]; then
                    gh repo create "$repo_name" --description "$description" --public --source=. --remote=origin
                else
                    gh repo create "$repo_name" --description "$description" --private --source=. --remote=origin
                fi
                
                if [ $? -ne 0 ]; then
                    print_error "Failed to create GitHub repository"
                    return 1
                fi
                
                print_success "Repository created: https://github.com/$GITHUB_USERNAME/$repo_name"
            fi
            
            # Check if remote already exists
            if ! git remote | grep -q "origin"; then
                git remote add origin "https://github.com/$GITHUB_USERNAME/$repo_name.git"
            fi
            
            # Determine current branch name
            current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
            
            # Try pushing to GitHub with token auth for reliability
            print_step "Pushing to GitHub..."
            git push -u origin "$current_branch"
            if [ $? -eq 0 ]; then
                print_success "Successfully pushed to GitHub"
                GITHUB_REPO_CREATED=true
            else 
                print_warning "Failed to push to GitHub. You can try again later with:"
                print_warning "cd \"$DOTFILES_DIR\" && git push -u origin $current_branch"
                print_warning "You may need to create the repository manually at https://github.com/new"
            fi
        else
            # Manual GitHub workflow
            echo -e "${BLUE}Enter your GitHub username:${NC}"
            read -r github_username
            
            if [ -n "$github_username" ]; then
                repo_url="https://github.com/$github_username/$repo_name.git"
                
                print_step "Setting up remote origin to $repo_url"
                # Check if remote already exists
                if git remote | grep -q "origin"; then
                    git remote set-url origin "$repo_url"
                else
                    git remote add origin "$repo_url"
                fi
                
                # Determine current branch name
                current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || echo "main")
                
                print_step "To push your dotfiles to GitHub:"
                print_warning "1. Create a repository named '$repo_name' on GitHub"
                print_warning "2. Run: cd \"$DOTFILES_DIR\" && git push -u origin $current_branch"
            fi
        fi
    fi
    
    return 0
}

# Setup Windows terminal configurations (like WezTerm)
setup_windows_terminal_configs() {
    print_header "Setting up Windows Terminal Configurations"
    
    # Get Windows username
    WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r\n')
    if [ -z "$WIN_USER" ]; then
        print_step "Enter your Windows username:"
        read -r WIN_USER
    fi
    
    # Check for WezTerm configuration
    local wezterm_windows_path="/mnt/c/Users/$WIN_USER/dotfiles/.wez/.wezterm.lua"
    local wezterm_config_path="/mnt/c/Users/$WIN_USER/.config/wezterm/wezterm.lua"
    local wezterm_dotfiles_path="$DOTFILES_DIR/.config/wezterm/wezterm.lua"
    
    # Check various possible WezTerm config locations
    if [ -f "$wezterm_windows_path" ]; then
        print_success "Found WezTerm config at: $wezterm_windows_path"
        
        # If using chezmoi, add it for management
        if [ "$USE_CHEZMOI" = true ]; then
            print_step "Setting up chezmoi to manage your existing WezTerm config..."
            
            # Create the config directory in dotfiles
            ensure_dir "$DOTFILES_DIR/.config/wezterm"
            
            # Create a symlink in dotfiles to the Windows config
            if [ ! -L "$wezterm_dotfiles_path" ]; then
                ln -sf "$wezterm_windows_path" "$wezterm_dotfiles_path"
            fi
            
            # Add to chezmoi
            safe_add_to_chezmoi "$wezterm_dotfiles_path" "WezTerm configuration"
        fi
        
        print_step "Your existing WezTerm configuration will be used"
        print_step "Edit it at: $(echo "$wezterm_windows_path" | sed 's|/mnt/c|C:|')"
        
    elif [ -f "$wezterm_config_path" ]; then
        print_success "Found WezTerm config at standard Windows location"
        
        if [ "$USE_CHEZMOI" = true ]; then
            print_step "Setting up chezmoi to manage your existing WezTerm config..."
            
            # Create the config directory in dotfiles
            ensure_dir "$DOTFILES_DIR/.config/wezterm"
            
            # Create a symlink in dotfiles to the Windows config
            if [ ! -L "$wezterm_dotfiles_path" ]; then
                ln -sf "$wezterm_config_path" "$wezterm_dotfiles_path"
            fi
            
            # Add to chezmoi
            safe_add_to_chezmoi "$wezterm_dotfiles_path" "WezTerm configuration"
        fi
        
        print_step "Your existing WezTerm configuration will be used"
        print_step "Edit it at: $(echo "$wezterm_config_path" | sed 's|/mnt/c|C:|')"
    else
        print_step "No WezTerm configuration found"
        print_step "If you use WezTerm, place your config at one of these locations:"
        print_step "  • C:\\Users\\$WIN_USER\\dotfiles\\.wez\\.wezterm.lua"
        print_step "  • C:\\Users\\$WIN_USER\\.config\\wezterm\\wezterm.lua"
    fi
    
    # Check for Windows Terminal settings
    local windows_terminal_path="/mnt/c/Users/$WIN_USER/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
    if [ -f "$windows_terminal_path" ]; then
        print_success "Found Windows Terminal settings"
        print_step "Your Windows Terminal settings are at: $(echo "$windows_terminal_path" | sed 's|/mnt/c|C:|')"
        print_step "Note: Windows Terminal settings are managed separately from WSL dotfiles"
    fi
    
    return 0
}

# Setup Git configuration
setup_git_config() {
    print_header "Setting up Git configuration"
    
    # Check if Git is installed
    if ! command_exists git; then
        print_warning "Git is not installed. Installing Git..."
        run_elevated pacman -S --noconfirm --needed git 2>&1 | grep -v "warning: insufficient columns"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            print_error "Failed to install Git"
            return 1
        fi
    fi
    
    # Prompt for Git configuration
    print_step "Setting up Git user configuration..."
    
    # Store Git config in dotfiles directory
    local git_config_path="$DOTFILES_DIR/.gitconfig"
    
    # Check if user already has Git config
    if [ -f "$git_config_path" ]; then
        print_step "Existing Git configuration found in dotfiles."
        
        # Create symlink if it doesn't exist
        if [ ! -L "$HOME/.gitconfig" ]; then
            print_step "Creating symlink for Git configuration..."
            ln -sf "$git_config_path" "$HOME/.gitconfig"
        fi
        
        # Add to chezmoi if enabled
        if [ "$USE_CHEZMOI" = true ]; then
            safe_add_to_chezmoi "$HOME/.gitconfig" "Git configuration"
        fi
        
        return 0
    fi
    
    # Prompt for user information
    echo -e "\n${BLUE}Do you want to configure Git with your user information? (y/n) [y]${NC}"
    read -r setup_git
    setup_git=${setup_git:-y}  # Default to yes
    
    if [[ "$setup_git" =~ ^[Yy]$ ]]; then
        # Ask for name and email
        echo -e "${BLUE}Enter your Git user name:${NC}"
        read -r git_name
        
        echo -e "${BLUE}Enter your Git email address:${NC}"
        read -r git_email
        
        # Create git config in dotfiles directory
        cat > "$git_config_path" << EOL
[user]
    name = $git_name
    email = $git_email
[init]
    defaultBranch = main
[core]
    editor = nvim
    autocrlf = input
[color]
    ui = auto
[pull]
    rebase = false
[push]
    default = simple
EOL
        
        # Create symlink to home directory
        print_step "Creating symlink for Git configuration..."
        ln -sf "$git_config_path" "$HOME/.gitconfig"
        
        # Add to chezmoi if enabled
        if [ "$USE_CHEZMOI" = true ]; then
            print_step "Managing Git configuration with chezmoi..."
            safe_add_to_chezmoi "$HOME/.gitconfig" "Git configuration"
        fi
        
        print_success "Git configuration created in dotfiles directory"
    else
        print_step "Skipping Git configuration setup"
    fi
    
    return 0
}

# Setup Zsh configuration with Oh My Zsh
setup_zsh_config() {
    print_header "Setting up Zsh configuration"
    
    # Install Oh My Zsh if not already installed
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_step "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        if [ $? -ne 0 ]; then
            print_error "Failed to install Oh My Zsh"
            return 1
        fi
    else
        print_step "Oh My Zsh is already installed"
    fi
    
    # Create .zshrc in dotfiles directory
    local zshrc_path="$DOTFILES_DIR/.zshrc"
    
    print_step "Creating Zsh configuration..."
    cat > "$zshrc_path" << 'EOF'
# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="robbyrussell"

# Which plugins would you like to load?
plugins=(
    git
    zsh-autosuggestions
    zsh-syntax-highlighting
    fzf
    tmux
    z
    colored-man-pages
    command-not-found
    sudo
)

source $ZSH/oh-my-zsh.sh

# User configuration

# Export PATH
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

# Set default editor
export EDITOR='nvim'
export VISUAL='nvim'

# Enable true color support
export COLORTERM=truecolor

# Aliases
alias v='nvim'
alias vi='nvim'
alias vim='nvim'
alias ll='eza -la --icons --group-directories-first --time-style=long-iso'
alias la='eza -la --icons --group-directories-first'
alias ls='eza --icons --group-directories-first'
alias lt='eza --tree --level=2 --icons'
alias tree='eza --tree --icons'
alias cat='bat'
alias find='fd'
alias grep='rg'
alias ps='procs'
alias du='gdu'
alias df='duf'
alias top='btm'
alias htop='btm'
alias c='clear'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias gco='git checkout'
alias gb='git branch'
alias glog='git log --oneline --graph --decorate'

# Tmux aliases
alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux list-sessions'
alias tk='tmux kill-session -t'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias ~='cd ~'
alias -- -='cd -'

# Chezmoi aliases (if using chezmoi)
if command -v chezmoi &> /dev/null; then
    alias cz='chezmoi'
    alias cza='chezmoi add'
    alias cze='chezmoi edit'
    alias czap='chezmoi apply'
    alias czd='chezmoi diff'
    alias czup='chezmoi update'
fi

# WSL specific
if [[ "$(uname -r)" == *microsoft* ]]; then
    # WSL2 specific settings
    export DISPLAY=$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}'):0
    export BROWSER='/mnt/c/Program Files/Google/Chrome/Application/chrome.exe'
    
    # Windows interop
    alias explorer='explorer.exe'
    alias notepad='notepad.exe'
fi

# FZF configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'

# Zoxide initialization
eval "$(zoxide init zsh)"

# Starship prompt
eval "$(starship init zsh)"

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Cargo/Rust
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# Add custom bin directories to PATH
export PATH="$HOME/.cargo/bin:$PATH"

# Load custom functions
if [ -f "$HOME/.zsh_functions" ]; then
    source "$HOME/.zsh_functions"
fi

# Welcome message with system info
if command -v fastfetch &> /dev/null; then
    fastfetch
fi

# Show a helpful message
echo ""
echo "Welcome to your WSL development environment!"
echo "Type 'cat ~/dev/docs/quick-reference.md' for command reference"
echo ""
EOF

    # Install zsh plugins
    print_step "Installing Zsh plugins..."
    
    # Autosuggestions
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi
    
    # Syntax highlighting
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi
    
    # Create symlink from home to dotfiles
    if [ -L "$HOME/.zshrc" ] || [ -f "$HOME/.zshrc" ]; then
        backup_file "$HOME/.zshrc"
    fi
    ln -sf "$zshrc_path" "$HOME/.zshrc"
    
    # Add to chezmoi if enabled
    if [ "$USE_CHEZMOI" = true ]; then
        safe_add_to_chezmoi "$HOME/.zshrc" "Zsh configuration"
    fi
    
    print_success "Zsh configuration created successfully"
    return 0
}

# Setup tmux configuration
setup_tmux_config() {
    print_header "Setting up tmux configuration"
    
    local tmux_conf_path="$DOTFILES_DIR/.tmux.conf"
    
    print_step "Creating tmux configuration..."
    cat > "$tmux_conf_path" << 'EOF'
# Tmux configuration for WSL development environment

# Set prefix to Ctrl-a instead of Ctrl-b
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Enable mouse support
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# Renumber windows when one is closed
set -g renumber-windows on

# Split panes using | and -
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Reload config file
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Switch panes using Alt-arrow without prefix
bind -n M-Left select-pane -L
bind -n M-Right select-pane -R
bind -n M-Up select-pane -U
bind -n M-Down select-pane -D

# Vim-like pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Enable 256 colors
set -g default-terminal "screen-256color"
set -ga terminal-overrides ",*256col*:Tc"

# Status bar
set -g status-position bottom
set -g status-style 'bg=colour235 fg=colour137'
set -g status-left '#[fg=colour233,bg=colour245,bold] #S '
set -g status-right '#[fg=colour233,bg=colour241,bold] %d/%m #[fg=colour233,bg=colour245,bold] %H:%M:%S '
set -g status-right-length 50
set -g status-left-length 20

# Window status
setw -g window-status-current-style 'fg=colour1 bg=colour238 bold'
setw -g window-status-current-format ' #I#[fg=colour249]:#[fg=colour255]#W#[fg=colour249]#F '
setw -g window-status-style 'fg=colour9 bg=colour235'
setw -g window-status-format ' #I#[fg=colour237]:#[fg=colour250]#W#[fg=colour244]#F '

# History
set -g history-limit 10000

# Activity monitoring
setw -g monitor-activity on
set -g visual-activity off

# Vi mode for copy mode
setw -g mode-keys vi

# Copy to system clipboard (WSL specific)
if-shell "uname -r | grep -q microsoft" \
    'bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "clip.exe"'
EOF

    # Create symlink from home to dotfiles
    if [ -L "$HOME/.tmux.conf" ] || [ -f "$HOME/.tmux.conf" ]; then
        backup_file "$HOME/.tmux.conf"
    fi
    ln -sf "$tmux_conf_path" "$HOME/.tmux.conf"
    
    # Add to chezmoi if enabled
    if [ "$USE_CHEZMOI" = true ]; then
        safe_add_to_chezmoi "$HOME/.tmux.conf" "Tmux configuration"
    fi
    
    print_success "Tmux configuration created successfully"
    return 0
}

# Setup Starship prompt configuration
setup_starship_config() {
    print_header "Setting up Starship prompt"
    
    local starship_config_dir="$DOTFILES_DIR/.config/starship"
    ensure_dir "$starship_config_dir"
    
    local starship_config_path="$starship_config_dir/starship.toml"
    
    print_step "Creating Starship configuration..."
    cat > "$starship_config_path" << 'EOF'
# Starship prompt configuration for WSL

# Format
format = """
$username\
$hostname\
$directory\
$git_branch\
$git_status\
$nodejs\
$python\
$rust\
$docker_context\
$line_break\
$character"""

# Timeout for commands
command_timeout = 500

[username]
show_always = false
style_user = "bold green"
style_root = "bold red"
format = '[$user ]($style)'

[hostname]
ssh_only = true
format = '[$hostname](bold blue) '
disabled = false

[directory]
truncation_length = 3
truncate_to_repo = true
format = "[$path]($style)[$read_only]($read_only_style) "
style = "bold cyan"

[character]
success_symbol = "[➜](bold green)"
error_symbol = "[➜](bold red)"

[git_branch]
symbol = " "
format = 'on [$symbol$branch]($style) '
style = "bold purple"

[git_status]
format = '([\[$all_status$ahead_behind\]]($style) )'
style = "bold red"

[nodejs]
symbol = " "
format = 'via [$symbol($version )]($style)'
style = "bold green"

[python]
symbol = " "
format = 'via [${symbol}${pyenv_prefix}(${version} )(\($virtualenv\) )]($style)'
style = "bold yellow"

[rust]
symbol = " "
format = 'via [$symbol($version )]($style)'
style = "bold red"

[docker_context]
symbol = " "
format = 'via [$symbol$context]($style) '
style = "bold blue"
EOF

    # Create symlink
    ensure_dir "$HOME/.config"
    if [ -L "$HOME/.config/starship" ] || [ -d "$HOME/.config/starship" ]; then
        rm -rf "$HOME/.config/starship"
    fi
    ln -sf "$starship_config_dir" "$HOME/.config/starship"
    
    # Also create the direct config file for compatibility
    ln -sf "$starship_config_path" "$HOME/.config/starship.toml"
    
    # Add to chezmoi if enabled
    if [ "$USE_CHEZMOI" = true ]; then
        safe_add_to_chezmoi "$HOME/.config/starship.toml" "Starship configuration"
    fi
    
    print_success "Starship prompt configured successfully"
    return 0
}

# Create WSL utility scripts
create_wsl_utilities() {
    print_header "Creating WSL utility scripts"
    
    ensure_dir "$HOME/bin" || return 1
    
    # Create Windows Explorer opener
    print_step "Creating Windows Explorer integration script..."
    cat > "$HOME/bin/winopen" << 'EOF'
#!/bin/bash
# Open Windows Explorer in the current or specified directory

if [ $# -eq 0 ]; then
    # No arguments, open current directory
    explorer.exe .
else
    # Open specified path
    explorer.exe "$1"
fi
EOF
    chmod +x "$HOME/bin/winopen"
    
    # Create clipboard utilities
    print_step "Creating clipboard utilities..."
    cat > "$HOME/bin/clip-copy" << 'EOF'
#!/bin/bash
# Copy to Windows clipboard
clip.exe
EOF
    chmod +x "$HOME/bin/clip-copy"
    
    cat > "$HOME/bin/clip-paste" << 'EOF'
#!/bin/bash
# Paste from Windows clipboard
powershell.exe -command "Get-Clipboard" | tr -d '\r'
EOF
    chmod +x "$HOME/bin/clip-paste"
    
    # Create Cursor wrapper script
    print_step "Creating Cursor IDE wrapper..."
    cat > "$HOME/bin/cursor-wrapper.sh" << 'EOF'
#!/bin/bash
# Wrapper script to launch Cursor IDE from WSL with proper path conversion

# Convert WSL path to Windows path
if [ $# -eq 0 ]; then
    # No arguments, open current directory
    WINPATH=$(wslpath -w "$(pwd)")
else
    # Convert the provided path
    WINPATH=$(wslpath -w "$1")
fi

# Launch Cursor with the Windows path
if command -v cursor.exe &> /dev/null; then
    cursor.exe "$WINPATH"
elif [ -f "/mnt/c/Users/$USER/AppData/Local/Programs/cursor/Cursor.exe" ]; then
    "/mnt/c/Users/$USER/AppData/Local/Programs/cursor/Cursor.exe" "$WINPATH"
else
    echo "Cursor IDE not found. Please install it from https://cursor.sh"
    exit 1
fi
EOF
    chmod +x "$HOME/bin/cursor-wrapper.sh"
    
    # Create symlinks for convenience
    ln -sf "$HOME/bin/cursor-wrapper.sh" "$HOME/bin/cursor"
    ln -sf "$HOME/bin/cursor-wrapper.sh" "$HOME/bin/code"
    
    # Add to chezmoi if enabled
    if [ "$USE_CHEZMOI" = true ]; then
        safe_add_to_chezmoi "$HOME/bin/winopen" "Windows Explorer integration"
        safe_add_to_chezmoi "$HOME/bin/clip-copy" "Clipboard copy utility"
        safe_add_to_chezmoi "$HOME/bin/clip-paste" "Clipboard paste utility"
        safe_add_to_chezmoi "$HOME/bin/cursor-wrapper.sh" "Cursor IDE wrapper"
    fi
    
    print_success "WSL utility scripts created successfully"
    return 0
}

# Setup Node.js and npm via NVM
setup_nodejs() {
    print_header "Setting up Node.js via NVM"
    
    if [ ! -d "$HOME/.nvm" ]; then
        print_step "Installing NVM (Node Version Manager)..."
        # Install development tools needed for building Node.js
        run_elevated pacman -S --noconfirm --needed base-devel openssl 2>&1 | grep -v "warning: insufficient columns"
        
        # Install NVM
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
        if [ $? -ne 0 ]; then
            print_error "Failed to install NVM"
            print_warning "Make sure you have internet connectivity"
            return 1
        fi
        
        # Initialize NVM in current shell
        init_nvm
        
        print_step "Installing latest LTS version of Node.js..."
        nvm install --lts
        if [ $? -ne 0 ]; then
            print_error "Failed to install Node.js"
            return 1
        fi
        
        # Set default Node.js version
        nvm alias default node
        
        print_success "Node.js installed successfully via NVM"
    else
        print_step "NVM is already installed"
        # Initialize NVM in current shell anyway
        init_nvm
        
        # Check if Node.js is installed
        if ! command_exists node; then
            print_step "Installing latest LTS version of Node.js..."
            nvm install --lts
            if [ $? -ne 0 ]; then
                print_error "Failed to install Node.js"
                return 1
            fi
            nvm alias default node
        else
            print_step "Node.js is already installed: $(node --version)"
        fi
    fi
    
    # Make sure NVM is properly configured in .bashrc and tracked by chezmoi
    print_step "Ensuring NVM configuration is in .bashrc and tracked by chezmoi..."
    
    # Check if NVM configuration is in .bashrc
    if ! grep -q "export NVM_DIR=\"\$HOME/.nvm\"" "$HOME/.bashrc"; then
        print_step "Configuring NVM in .bashrc..."
        cat >> "$HOME/.bashrc" << 'EOL'

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOL
    fi
    
    # Update .bashrc in chezmoi if it's already being managed
    if chezmoi managed ~/.bashrc &>/dev/null; then
        print_step "Updating .bashrc in chezmoi to include NVM configuration..."
        safe_add_to_chezmoi "$HOME/.bashrc" "Bash configuration with NVM" --force
        if [ $? -ne 0 ]; then
            print_warning "Failed to update .bashrc in chezmoi"
        else
            print_success "Configured .bashrc in chezmoi with NVM"
        fi
    fi
    
    print_success "Node.js environment configured successfully"
    return 0
}

# Setup Claude Code from Anthropic with chezmoi integration
setup_claude_code() {
    print_header "Claude Code Installation"
    
    print_warning "Claude Code requires an Anthropic account with billing setup"
    print_warning "You'll need at least \$5 in credits to use Claude Code"
    
    echo -e "\n${BLUE}Do you have an Anthropic account with billing configured? (y/n) [n]${NC}"
    read -r has_anthropic_account
    has_anthropic_account=${has_anthropic_account:-n}
    
    if [[ ! "$has_anthropic_account" =~ ^[Yy]$ ]]; then
        print_warning "Skipping Claude Code installation"
        print_warning "To set up later:"
        print_warning "1. Create account at console.anthropic.com"
        print_warning "2. Add payment method and purchase credits"
        print_warning "3. Run: npm install -g claude-ai-cli"
        return 0
    fi
    
    # First ensure Node.js is properly set up
    print_step "Checking Node.js installation..."
    
    # Source NVM to make sure we have Node.js available
    init_nvm
    
    # Verify Node.js is correctly installed
    if ! command_exists node; then
        print_warning "Node.js not found. Installing it first..."
        setup_nodejs
        if [ $? -ne 0 ]; then
            print_error "Failed to setup Node.js, which is required for Claude Code"
            return 1
        fi
    fi
    
    print_step "Using Node.js: $(node --version) at $(which node)"
    print_step "Using npm: $(npm --version) at $(which npm)"
    
    # Apply WSL-specific workarounds
    print_step "Setting npm config for WSL compatibility..."
    npm config set os linux
    
    # Install Claude Code CLI (correct package name based on research)
    print_step "Installing Claude Code CLI..."
    npm install -g claude-ai-cli
    
    if [ $? -eq 0 ]; then
        print_success "Claude Code CLI installed"
        print_step "Run 'claude login' to authenticate"
        print_step "Usage: claude <command> in any project directory"
    else
        print_warning "Failed to install Claude Code CLI"
        print_warning "Try manually: npm install -g claude-ai-cli"
    fi
    
    return 0
}

# Setup GitHub authentication and information
setup_github_info() {
    print_header "Setting up GitHub Integration"
    
    # Check if GitHub CLI is installed, it should be since we installed it in core deps
    if ! command_exists gh; then
        print_error "GitHub CLI is not installed even though it should have been"
        print_warning "GitHub integration features will be disabled"
        USE_GITHUB=false
        return 0
    fi
    
    print_step "GitHub CLI is installed"
    
    # Ask if user wants to set up GitHub integration
    echo -e "\n${BLUE}Do you want to set up GitHub integration? (y/n) [y]${NC}"
    read -r setup_github
    setup_github=${setup_github:-y}  # Default to yes
    
    if [[ "$setup_github" =~ ^[Yy]$ ]]; then
        USE_GITHUB=true
        
        # Check if already authenticated
        if gh auth status &>/dev/null; then
            print_success "Already authenticated with GitHub"
            # Get username
            GITHUB_USERNAME=$(gh api user | jq -r '.login')
            print_success "Detected GitHub username: $GITHUB_USERNAME"
            return 0
        fi
        
        # Prompt for authentication method
        echo -e "\n${BLUE}How would you like to authenticate with GitHub?${NC}"
        echo -e "1) Web browser (recommended)"
        echo -e "2) Personal access token"
        read -r auth_method
        
        case $auth_method in
            2)
                echo -e "${BLUE}Please enter your GitHub Personal Access Token:${NC}"
                read -r GITHUB_TOKEN
                
                if [ -n "$GITHUB_TOKEN" ]; then
                    echo "$GITHUB_TOKEN" | gh auth login --with-token
                    if [ $? -ne 0 ]; then
                        print_error "Failed to authenticate with GitHub using token"
                        USE_GITHUB=false
                        return 0
                    fi
                else
                    print_error "No token provided"
                    USE_GITHUB=false
                    return 0
                fi
                ;;
            *)
                # Default to web-based auth
                gh auth login -w
                if [ $? -ne 0 ]; then
                    print_error "Failed to authenticate with GitHub"
                    USE_GITHUB=false
                    return 0
                fi
                ;;
        esac
        
        # Get username after successful authentication
        GITHUB_USERNAME=$(gh api user | jq -r '.login')
        print_success "Successfully authenticated with GitHub as $GITHUB_USERNAME"
        
    else
        print_step "Skipping GitHub integration"
        USE_GITHUB=false
    fi
    
    return 0
}

# Create a GitHub repository if it doesn't exist
create_github_repository() {
    local repo_name="$1"
    local description="${2:-My dotfiles repository}"
    local is_public="${3:-false}"
    
    if ! $USE_GITHUB; then
        print_warning "GitHub integration is disabled. Skipping repository creation."
        return 1
    fi
    
    if ! command_exists gh; then
        print_error "GitHub CLI is not installed. Cannot create repository."
        return 1
    fi
    
    print_step "Creating GitHub repository: $repo_name..."
    
    # Check if repository already exists
    if gh repo view "$GITHUB_USERNAME/$repo_name" &>/dev/null; then
        print_step "Repository $GITHUB_USERNAME/$repo_name already exists"
        
        # Set the remote if we're in the chezmoi source directory
        if [ -d "$CHEZMOI_SOURCE_DIR/.git" ]; then
            cd "$CHEZMOI_SOURCE_DIR" || return 1
            
            # Check if remote already exists
            if git remote | grep -q "origin"; then
                print_step "Remote 'origin' already exists, updating URL..."
                git remote set-url origin "https://github.com/$GITHUB_USERNAME/$repo_name.git"
            else
                git remote add origin "https://github.com/$GITHUB_USERNAME/$repo_name.git"
            fi
        fi
        
        return 0
    fi
    
    # Create the repository
    if [ "$is_public" = "true" ]; then
        gh repo create "$repo_name" --description "$description" --public
    else
        gh repo create "$repo_name" --description "$description" --private
    fi
    
    if [ $? -ne 0 ]; then
        print_error "Failed to create GitHub repository"
        return 1
    fi
    
    print_success "Repository created: https://github.com/$GITHUB_USERNAME/$repo_name"
    
    # Set the remote if we're in the chezmoi source directory
    if [ -d "$CHEZMOI_SOURCE_DIR/.git" ]; then
        cd "$CHEZMOI_SOURCE_DIR" || return 1
        
        # Check if remote already exists
        if git remote | grep -q "origin"; then
            print_step "Remote 'origin' already exists, updating URL..."
            git remote set-url origin "https://github.com/$GITHUB_USERNAME/$repo_name.git"
        else
            git remote add origin "https://github.com/$GITHUB_USERNAME/$repo_name.git"
        fi
    fi
    
    return 0
}

# Create Claude Code documentation
create_claude_code_docs() {
    print_header "Creating Claude Code documentation"
    
    ensure_dir "$SETUP_DIR/docs/claude-code" || return 1
    
    # Create a basic documentation file
    cat > "$SETUP_DIR/docs/claude-code/getting-started.md" << 'EOL'
# Getting Started with Claude Code

Claude Code is an AI assistant for coding that helps you write, explain, and debug code right from your terminal.

## Basic Usage

To start a conversation with Claude:

```bash
claude
```

This opens an interactive session. Type your questions or code, and Claude will respond.

## Providing Context

You can provide file context to Claude:

```bash
claude --files path/to/file1.js path/to/file2.js
```

## Common Use Cases

- **Code Generation**: "Write a function that sorts an array of objects by a given property"
- **Debugging**: "Why is this code not working as expected?"
- **Explanations**: "Explain how this algorithm works"
- **Refactoring**: "How can I improve this code?"

## Advanced Usage

For more options and features, run:

```bash
claude --help
```

For more information, visit [Claude Code Documentation](https://docs.anthropic.com/claude/code).
EOL
    
    print_success "Claude Code documentation created successfully"
    return 0
}

# Create manual dotfile management documentation
create_manual_dotfile_docs() {
    print_header "Creating dotfile management documentation"
    
    ensure_dir "$SETUP_DIR/docs/dotfiles" || return 1
    
    # Create a basic documentation file
    cat > "$SETUP_DIR/docs/dotfiles/getting-started.md" << EOL
# Getting Started with Manual Dotfile Management

Your dotfiles are stored in: \`$DOTFILES_DIR\`

$(if [[ "$DOTFILES_DIR" == "/mnt/c/"* ]]; then
    echo "This is a **unified Windows + WSL setup** that allows cross-platform dotfile editing!"
    echo ""
    echo "### Cross-Platform Access"
    echo ""
    echo "- **WSL path:** \`$DOTFILES_DIR\`"
    echo "- **Windows path:** \`$(echo "$DOTFILES_DIR" | sed 's|/mnt/c|C:|')\`"
    echo ""
    echo "You can edit your dotfiles from either Windows or WSL:"
    echo ""
    echo "1. **From Windows:** Open \`$(echo "$DOTFILES_DIR" | sed 's|/mnt/c|C:|')\` in your editor"
    echo "2. **From WSL:** Edit files directly in \`$DOTFILES_DIR\`"
else
    echo "This is a **WSL-only setup** with dotfiles stored in your WSL file system."
fi)

## How It Works

Your configuration files are organized in the dotfiles directory with the same structure as your home directory:

\`\`\`
$DOTFILES_DIR/
├── .gitconfig           # Git configuration
├── .config/
│   ├── nvim/           # Neovim configuration
│   └── wezterm/        # WezTerm config (if applicable)
└── .git/               # Version control
\`\`\`

## Managing Your Dotfiles

### Adding New Configuration Files

1. **Create or copy the config to the dotfiles directory:**
   \`\`\`bash
   # Example: Adding a new .tmux.conf
   cp ~/.tmux.conf $DOTFILES_DIR/.tmux.conf
   \`\`\`

2. **Create a symlink from your home directory:**
   \`\`\`bash
   ln -sf $DOTFILES_DIR/.tmux.conf ~/.tmux.conf
   \`\`\`

3. **Add to version control:**
   \`\`\`bash
   cd "$DOTFILES_DIR"
   git add .tmux.conf
   git commit -m "Add tmux configuration"
   git push
   \`\`\`

### Editing Existing Configurations

Since your configs are symlinked, you can edit them in two ways:

1. **Edit the symlink (appears to edit the file in home):**
   \`\`\`bash
   nvim ~/.gitconfig
   \`\`\`

2. **Edit directly in the dotfiles directory:**
   \`\`\`bash
   nvim $DOTFILES_DIR/.gitconfig
   \`\`\`

Both methods edit the same file!

### Syncing Changes

After making changes, commit and push them:

\`\`\`bash
cd "$DOTFILES_DIR"
git add -A
git commit -m "Update configurations"
git push
\`\`\`

### Setting Up on a New Machine

1. **Clone your dotfiles repository:**
   \`\`\`bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   \`\`\`

2. **Create symlinks for each config:**
   \`\`\`bash
   # Example for common configs
   ln -sf ~/dotfiles/.gitconfig ~/.gitconfig
   ln -sf ~/dotfiles/.config/nvim ~/.config/nvim
   # ... repeat for other configs
   \`\`\`

## Best Practices

1. **Keep sensitive data out**: Don't commit passwords, API keys, or tokens
2. **Use .gitignore**: Exclude machine-specific or generated files
3. **Document your setup**: Keep a README in your dotfiles repo
4. **Regular commits**: Commit changes frequently with descriptive messages

## Common Commands

\`\`\`bash
# Go to dotfiles directory
cd "$DOTFILES_DIR"

# Check status
git status

# See what changed
git diff

# Add all changes
git add -A

# Commit with message
git commit -m "Description of changes"

# Push to GitHub
git push
\`\`\`

## Tips

- Use descriptive commit messages like "Add tmux mouse support" instead of "Update .tmux.conf"
- Consider organizing configs by topic (e.g., a "shell" directory for all shell-related configs)
- Test configuration changes before committing
- Keep a changelog or notes about significant changes

Your dotfiles repository makes it easy to maintain consistent configurations across machines and track changes over time!
EOL
    
    print_success "Manual dotfile management documentation created"
    return 0
}

# Create Chezmoi documentation
create_chezmoi_docs() {
    print_header "Creating Chezmoi documentation"
    
    ensure_dir "$SETUP_DIR/docs/chezmoi" || return 1
    
    # Create a basic documentation file
    cat > "$SETUP_DIR/docs/chezmoi/getting-started.md" << 'EOL'
# Getting Started with Chezmoi

Chezmoi is a dotfile manager that helps you manage your configuration files across multiple machines.

## Your Setup

Your chezmoi source directory is configured for your environment.
EOL

    # Add platform-specific content
    if [[ "$CHEZMOI_SOURCE_DIR" == "/mnt/c/"* ]]; then
        local windows_path=$(echo "$CHEZMOI_SOURCE_DIR" | sed 's|/mnt/c|C:|')
        cat >> "$SETUP_DIR/docs/chezmoi/getting-started.md" << EOL

This is a **unified Windows + WSL setup** that allows cross-platform dotfile editing!

### Cross-Platform Editing

- **WSL path:** \`$CHEZMOI_SOURCE_DIR\`
- **Windows path:** \`$windows_path\`

You can edit your dotfiles from either Windows or WSL:

1. **From Windows:** Open \`$windows_path\` in your editor
2. **From WSL:** Use \`chezmoi edit\` or \`chezmoi cd\`
3. **Apply changes:** Run \`chezmoi apply\` after editing

### Templates Handle OS Differences

Your \`.zshrc\` file uses chezmoi templates to handle differences between Windows and Linux:

\`\`\`bash
{{- if eq .chezmoi.os "linux" }}
# WSL/Linux specific configuration
{{- else if eq .chezmoi.os "windows" }}
# Windows specific configuration
{{- end }}
\`\`\`
EOL
    else
        cat >> "$SETUP_DIR/docs/chezmoi/getting-started.md" << EOL

This is a **WSL-only setup** with dotfiles stored in your WSL home directory.
EOL
    fi

    # Add the rest of the documentation
    cat >> "$SETUP_DIR/docs/chezmoi/getting-started.md" << 'EOL'

## Basic Commands

```bash
# Add a file to be managed by chezmoi
chezmoi add ~/.zshrc

# Edit a file
chezmoi edit ~/.zshrc

# Apply changes
chezmoi apply

# See what changes would be made
chezmoi diff

# Update from remote repository
chezmoi update
```

## Using Aliases

Your .zshrc and .bashrc include aliases for common chezmoi commands:

```bash
# Add a file
cza ~/.zshrc

# Edit a file
cze ~/.zshrc

# Apply changes
czap

# See differences
czd

# Update from remote
czup
```

## Working with Templates

Chezmoi supports templates for managing differences between machines:

\`\`\`
{{- if eq .chezmoi.os "linux" }}
# Linux-specific configuration
{{- else if eq .chezmoi.os "windows" }}
# Windows-specific configuration
{{- end }}
\`\`\`

## Git Integration

Your dotfiles are stored in a git repository. Common workflow:

\`\`\`bash
# Make changes to dotfiles
chezmoi edit ~/.zshrc

# Apply changes locally
chezmoi apply

# Commit and push changes
chezmoi cd
git add .
git commit -m "Update zsh config"
git push
exit

# On another machine, pull updates
chezmoi update
\`\`\`

## For More Information

See the [official Chezmoi documentation](https://www.chezmoi.io/).
EOL
    
    print_success "Chezmoi documentation created successfully"
    return 0
}

# Verify dotfiles symlinks are working
verify_dotfiles_setup() {
    print_header "Verifying Dotfiles Setup"
    
    local failed=false
    
    # Check if DOTFILES_DIR exists and is accessible
    if [ ! -d "$DOTFILES_DIR" ]; then
        print_error "Dotfiles directory does not exist: $DOTFILES_DIR"
        failed=true
    else
        print_success "Dotfiles directory exists: $DOTFILES_DIR"
    fi
    
    # Check common symlinks
    local configs_to_check=(
        "$HOME/.gitconfig:$DOTFILES_DIR/.gitconfig"
        "$HOME/.zshrc:$DOTFILES_DIR/.zshrc" 
        "$HOME/.tmux.conf:$DOTFILES_DIR/.tmux.conf"
        "$HOME/.config/nvim:$DOTFILES_DIR/.config/nvim"
    )
    
    for config_pair in "${configs_to_check[@]}"; do
        local symlink_path="${config_pair%%:*}"
        local target_path="${config_pair##*:}"
        
        if [ -L "$symlink_path" ]; then
            local actual_target=$(readlink "$symlink_path")
            if [ "$actual_target" = "$target_path" ] && [ -e "$target_path" ]; then
                print_success "✓ $symlink_path → $target_path"
            else
                print_error "✗ $symlink_path → $actual_target (target missing or incorrect)"
                failed=true
            fi
        elif [ -e "$symlink_path" ]; then
            print_warning "! $symlink_path exists but is not a symlink"
        else
            print_warning "! $symlink_path does not exist"
        fi
    done
    
    if [ "$failed" = true ]; then
        print_error "Some dotfiles configurations are not properly set up"
        return 1
    else
        print_success "All checked dotfiles configurations are properly linked"
        return 0
    fi
}

# Create component documentation
create_component_docs() {
    print_header "Creating component documentation"
    
    ensure_dir "$SETUP_DIR/docs" || return 1
    
    # Create a comprehensive workflow documentation
    cat > "$SETUP_DIR/docs/workflow-guide.md" << 'EOL'
# WSL Development Environment Workflow Guide

This guide explains the complete workflow and architecture of your WSL development environment setup.

## Overview

This WSL development environment provides a comprehensive, cross-platform development setup optimized for Arch Linux on WSL. The environment integrates Windows and WSL seamlessly through unified dotfile management, intelligent tool detection, and cross-platform utilities.

## Architecture

### Directory Structure
```
~/
├── dev/                          # Main development environment
│   ├── docs/                     # Documentation and guides
│   ├── bin/                      # Custom scripts and utilities
│   ├── projects/                 # Your development projects
│   ├── configs/                  # Configuration backups
│   └── update.sh                 # Environment update script
├── dotfiles/                     # Chezmoi source directory
│   ├── .git/                     # Git repository for dotfiles
│   ├── dot_zshrc.tmpl           # Cross-platform Zsh configuration
│   ├── dot_tmux.conf            # Tmux configuration
│   └── README.md                # Dotfiles documentation
└── bin/                          # User executables directory
    ├── cursor-wrapper.sh         # Cursor IDE integration
    ├── cursor-path.sh            # Cursor PATH detection
    ├── winopen                   # Windows Explorer integration
    └── clip-copy                 # Clipboard utilities
```

### Core Components

#### 1. Shell Environment (Zsh + Oh My Zsh)
- **Primary Shell**: Zsh with Oh My Zsh framework
- **Plugins**: Autosuggestions, syntax highlighting, fzf, tmux integration
- **Theme**: Robbyrussell (clean and informative)
- **Cross-Platform Configuration**: Templates handle Windows vs Linux differences

#### 2. Dotfile Management (Chezmoi)
- **Source Directory**: Configurable (unified Windows-accessible or WSL-only)
- **Template System**: OS-specific configurations using Go templates
- **Git Integration**: Automatic repository management and synchronization
- **Cross-Platform Support**: Single repository manages both Windows and WSL dotfiles

#### 3. Text Editor (Neovim + Kickstart)
- **Configuration Options**: 
  - Regular Kickstart: Single-file configuration (easier for beginners)
  - Modular Kickstart: Multi-file structure (better for extensive customization)
- **Base Configuration**: Kickstart.nvim for modern Neovim setup
- **Package Manager**: Lazy.nvim for plugin management
- **Language Support**: Built-in LSP, treesitter, and completion
- **Customization**: User fork support for personalized configurations
- **Theme Support**: Optional Rose Pine theme with transparency

#### 4. Terminal Multiplexer (Tmux)
- **Prefix Key**: Ctrl+a (more accessible than default Ctrl+b)
- **Vim-like Navigation**: hjkl keys for pane navigation
- **Intelligent Splits**: Preserves current working directory
- **Mouse Support**: Full mouse integration for modern workflow

#### 5. Node.js Environment (NVM)
- **Version Manager**: NVM for flexible Node.js version management
- **LTS Installation**: Automatic latest LTS version installation
- **Development Tools**: Base development tools for building native modules
- **Cross-Platform Compatibility**: Linux-optimized npm configuration

#### 6. AI Assistant (Claude Code)
- **Optional Installation**: User-confirmed installation with timeout protection
- **Interactive Mode**: Terminal-based AI coding assistance
- **Context Awareness**: File context support for better assistance
- **Development Integration**: Seamless workflow integration

## Unified Cross-Platform Dotfiles

### Concept
The unified dotfiles approach eliminates the traditional problem of maintaining separate dotfile configurations for Windows and WSL. Instead of using symlinks or duplicate configurations, this system uses a single git repository with intelligent templating.

### How It Works

#### Template-Based Configuration
Files use Chezmoi's Go template syntax to handle OS differences:

```go
{{- if eq .chezmoi.os "linux" }}
# WSL/Linux specific configuration
export EDITOR='nvim'
alias ls='ls --color=auto'
{{- else if eq .chezmoi.os "windows" }}
# Windows specific configuration
export EDITOR='code'
alias ls='dir'
{{- end }}
```

#### Cross-Platform Paths
- **Windows Access**: `C:\Users\username\dotfiles`
- **WSL Access**: `/mnt/c/Users/username/dotfiles`
- **Seamless Editing**: Edit from either environment, changes sync instantly

#### Git Integration
- **Single Repository**: One git history for all platforms
- **Platform Agnostic**: Commit and push from Windows or WSL
- **Automatic Sync**: Changes available immediately across platforms

### Workflow Examples

#### Daily Development Workflow
1. **Morning Setup**:
   ```bash
   # Check system status
   fastfetch
   
   # Update environment if needed
   ~/dev/update.sh
   
   # Start working in tmux
   tmux new -s dev
   ```

2. **Configuration Changes**:
   ```bash
   # Edit configuration (opens in Neovim)
   chezmoi edit ~/.zshrc
   
   # Preview changes
   chezmoi diff
   
   # Apply changes
   chezmoi apply
   
   # Commit and push
   chezmoi cd
   git add .
   git commit -m "Update shell configuration"
   git push
   ```

3. **Cross-Platform Editing**:
   ```bash
   # From Windows: Open in Cursor/VS Code
   # Navigate to C:\Users\username\dotfiles
   # Edit files directly
   
   # From WSL: Apply changes
   chezmoi apply
   ```

## Tool Integration

### Cursor IDE Integration
The setup provides comprehensive Cursor IDE support for seamless Windows-WSL development:

#### Features
- **Path Conversion**: Automatic Linux to Windows path translation
- **WSL-Optimized Wrapper**: Handles edge cases and permission issues
- **Dual Commands**: Both `cursor` and `code` commands work
- **Auto-Detection**: Scans common Windows installation paths

#### Usage
```bash
# Open current directory in Cursor
cursor .

# Open specific file
cursor src/main.js

# Open project (converts WSL paths automatically)
cursor ~/dev/projects/my-app
```

### GitHub Integration
Comprehensive GitHub integration using GitHub CLI:

#### Authentication
- **Web-Based**: Secure browser authentication (recommended)
- **Token-Based**: Personal access token support
- **Automatic Detection**: Username and repository detection

#### Repository Management
```bash
# Create new repository
gh repo create my-project --private

# Clone and work with repositories
gh repo clone username/repository
```

### Windows Integration Utilities

#### File System Integration
```bash
# Open current directory in Windows Explorer
winopen

# Open specific path
winopen ~/dev/projects

# Copy to Windows clipboard
echo "text" | clip-copy
```

## Development Workflows

### New Project Setup
1. **Create Project Directory**:
   ```bash
   mkdir ~/dev/projects/new-project
   cd ~/dev/projects/new-project
   ```

2. **Initialize Git**:
   ```bash
   git init
   gh repo create new-project --private
   git remote add origin https://github.com/username/new-project.git
   ```

3. **Start Development Environment**:
   ```bash
   tmux new -s new-project
   cursor .
   ```

### Configuration Management
1. **Add New Configuration File**:
   ```bash
   # Create or modify configuration
   nvim ~/.config/newapp/config.yaml
   
   # Add to chezmoi management
   chezmoi add ~/.config/newapp/config.yaml
   ```

2. **Update Existing Configuration**:
   ```bash
   # Edit through chezmoi
   chezmoi edit ~/.zshrc
   
   # Or edit directly and re-add
   nvim ~/.zshrc
   chezmoi add --force ~/.zshrc
   ```

3. **Synchronize Across Machines**:
   ```bash
   # On first machine: commit changes
   chezmoi cd
   git add . && git commit -m "Update configuration"
   git push
   
   # On second machine: pull changes
   chezmoi update
   ```

## Troubleshooting

### Common Issues

#### Chezmoi Template Errors
If template rendering fails:
```bash
# Check template syntax
chezmoi execute-template < ~/.local/share/chezmoi/dot_zshrc.tmpl

# Debug with verbose output
chezmoi apply --verbose
```

#### Node.js Environment Issues
If Node.js commands fail:
```bash
# Reinitialize NVM
source ~/.nvm/nvm.sh

# Reinstall Node.js
nvm install --lts --reinstall-packages-from=default
```

#### Cursor Integration Issues
If Cursor commands don't work:
```bash
# Re-detect Cursor installation
~/bin/cursor-path.sh

# Manual PATH addition
export PATH="$PATH:/path/to/cursor/bin"
```

### Maintenance

#### Regular Updates
Run the update script monthly:
```bash
~/dev/update.sh
```

#### Dotfiles Backup
Your dotfiles are automatically backed up to GitHub, but for extra safety:
```bash
# Create local backup
cp -r ~/dotfiles ~/dotfiles.backup.$(date +%Y%m%d)

# Verify GitHub backup
cd ~/dotfiles && git log --oneline -10
```

## Advanced Customization

### Adding New Tools
1. **Install Tool**:
   ```bash
   # Install via package manager
   sudo pacman -S new-tool
   ```

2. **Add Configuration**:
   ```bash
   # Add config to chezmoi
   chezmoi add ~/.config/new-tool/config
   ```

3. **Update Shell Configuration**:
   ```bash
   # Add aliases or environment variables
   chezmoi edit ~/.zshrc
   ```

### Custom Templates
Create machine-specific configurations:
```go
{{- if eq .chezmoi.hostname "work-laptop" }}
# Work-specific configuration
export COMPANY_API_KEY="{{ .work_api_key }}"
{{- else if eq .chezmoi.hostname "personal-desktop" }}
# Personal configuration
export PERSONAL_SETTING="value"
{{- end }}
```

### Plugin Development
Add custom functionality:
```bash
# Create custom script
nvim ~/bin/my-custom-tool
chmod +x ~/bin/my-custom-tool

# Add to chezmoi
chezmoi add ~/bin/my-custom-tool
```

## Security Considerations

### Dotfiles Security
- **Private Repository**: Keep dotfiles in private GitHub repository
- **Sensitive Data**: Use chezmoi's secret management for API keys
- **File Permissions**: Chezmoi preserves file permissions automatically

### WSL Security
- **File System Access**: Be cautious with Windows file system modifications
- **Network Access**: WSL shares network with Windows host
- **User Permissions**: Use proper sudo practices

## Performance Optimization

### Shell Startup Time
- **Plugin Management**: Only load necessary Oh My Zsh plugins
- **Lazy Loading**: Use lazy loading for heavy tools like NVM
- **Profile Startup**: Profile shell startup time with `time zsh -i -c exit`

### Resource Usage
- **Tmux Sessions**: Close unused tmux sessions
- **Node.js**: Use `nvm use` to switch versions rather than global installs
- **Git Repositories**: Keep git repositories clean and optimized

This workflow guide provides the foundation for efficient development in your WSL environment. The unified approach eliminates traditional Windows-Linux development friction while maintaining the flexibility and power of both platforms.
EOL

    # Create a quick reference file
    cat > "$SETUP_DIR/docs/quick-reference.md" << 'EOL'
# Quick Reference Guide

## Core Tools

| Tool | Purpose | Basic Commands |
|------|---------|----------------|
| Neovim | Text editor | `nvim <filename>` |
| Tmux | Terminal multiplexer | `tmux new -s <session>`, `tmux attach -t <session>` |
| Zsh | Shell environment | Default shell with Oh My Zsh |
| Chezmoi | Dotfile manager | `cza <file>`, `czap` |
| Node.js | JavaScript runtime | Managed with NVM: `nvm install <version>` |
| Claude Code | AI coding assistant | `claude` |

### Neovim Configuration
Your Neovim is configured with either:
- **Regular Kickstart**: Single `init.lua` file (check `~/.config/nvim/init.lua`)
- **Modular Kickstart**: Multi-file structure (check `~/.config/nvim/lua/kickstart/`)

To update plugins: Open Neovim and run `:Lazy`

## Essential Aliases

```bash
# Core tools
v          # Open Neovim
ll         # List files with details
c          # Clear terminal

# Git shortcuts
gs         # Git status
ga         # Git add
gc         # Git commit with message
gp         # Git push
gl         # Git pull

# Tmux shortcuts
t          # Start tmux
ta         # Attach to session
tn         # New session
tl         # List sessions

# Chezmoi shortcuts
cz         # Chezmoi command
cza        # Add file to chezmoi
cze        # Edit file in chezmoi
czap       # Apply changes
czd        # Show differences
czup       # Update from remote
```

## WSL Integration Utilities

- `winopen`: Open current directory in Windows Explorer
- `clip-copy`: Copy text to Windows clipboard
- `cursor-wrapper.sh`: Cursor launcher for WSL paths
- `cursor-path.sh`: Auto-detect and add Cursor to PATH
- `cursor` / `code`: Both commands launch Cursor (for compatibility)

## Cross-Platform Dotfiles

Your setup supports unified Windows + WSL dotfiles management:

- **Single Repository**: One git repo for all your dotfiles
- **Template-Based**: OS differences handled automatically via chezmoi templates
- **Edit Anywhere**: Use Windows editors or WSL tools - changes sync instantly
- **Source Directory**: Located at a Windows-accessible path for seamless integration

## Directory Structure

- `~/dev`: Main environment directory
  - `/docs`: Documentation and guides
  - `/bin`: Custom scripts and utilities
  - `/projects`: Project storage (recommended)
- `~/dotfiles`: Chezmoi source directory

## Daily Workflow

```bash
# Morning setup
fastfetch                    # Check system status
~/dev/update.sh             # Update environment

# Start development session
tmux new -s work            # Create tmux session
cursor ~/dev/projects       # Open IDE

# Configuration management
chezmoi edit ~/.zshrc       # Edit config
chezmoi apply              # Apply changes
chezmoi cd && git push     # Save to GitHub

# Cross-platform editing
# Edit from Windows: C:\Users\username\dotfiles
# Apply from WSL: chezmoi apply
```

## Environment Updates

Run `~/dev/update.sh` to update your entire environment including:
- System packages
- Oh My Zsh and plugins
- NVM and Node.js
- Chezmoi and dotfiles
- Development tools

## Troubleshooting

### Common Issues
- **Node.js not found**: Run `source ~/.nvm/nvm.sh`
- **Cursor not working**: Run `~/bin/cursor-path.sh`
- **Template errors**: Check syntax with `chezmoi execute-template`
- **Git issues**: Verify identity with `git config --list`

### Getting Help
- Workflow guide: `cat ~/dev/docs/workflow-guide.md`
- Chezmoi guide: `cat ~/dev/docs/chezmoi/getting-started.md`
- Official docs: Visit tool websites for detailed documentation
EOL
    
    print_success "Component documentation created successfully"
    return 0
}

# Create update script
create_update_script() {
    print_header "Creating environment update script"
    print_step "Creating update.sh script..."
    
    cat > "$SETUP_DIR/update.sh" << 'EOL'
#!/bin/bash

# Color definitions
NC='\033[0m'         # Reset color
GREEN='\033[0;32m'   # Success messages
YELLOW='\033[0;33m'  # Warnings
BLUE='\033[0;34m'    # Information
RED='\033[0;31m'     # Error messages
CYAN='\033[0;36m'    # Section headers

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    SUDO=""
else
    SUDO="sudo"
fi

echo -e "${CYAN}==== WSL Development Environment Update ====${NC}"
echo -e "${BLUE}→ Updating system packages...${NC}"

# Update system packages
$SUDO pacman -Syu --noconfirm --noprogressbar 2>&1 | grep -v "warning: insufficient columns"
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo -e "${RED}✗ Failed to update system packages${NC}"
    exit 1
fi

echo -e "${GREEN}✓ System packages current${NC}"

# Update Oh My Zsh if installed
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${BLUE}→ Updating Oh My Zsh...${NC}"
    cd "$HOME" || exit 1
    
    # Run the upgrade directly using bash to avoid 'local' command not in function error
    if [ -f "$HOME/.oh-my-zsh/tools/upgrade.sh" ]; then
        bash "$HOME/.oh-my-zsh/tools/upgrade.sh"
    fi
    
    echo -e "${GREEN}✓ Oh My Zsh current${NC}"
fi

# Update Neovim plugins if Kickstart is installed
if [ -d "$HOME/.config/nvim" ]; then
    echo -e "${BLUE}→ Checking Neovim setup...${NC}"
    # Skip the update since we're using Kickstart
    echo -e "${YELLOW}! Using Kickstart Neovim - plugin updates should be handled within Neovim${NC}"
    echo -e "${YELLOW}! To update plugins, open Neovim and run: :Lazy update${NC}"
fi

# Update NVM if installed
if [ -d "$HOME/.nvm" ]; then
    echo -e "${BLUE}→ Updating NVM...${NC}"
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    # Update NVM itself - with less verbosity
    echo -e "${BLUE}→ Checking for NVM updates...${NC}"
    (
        cd "$NVM_DIR" && \
        git fetch --quiet --tags origin && \
        LATEST_TAG=$(git describe --abbrev=0 --tags --match "v[0-9]*" "$(git rev-list --tags --max-count=1)") && \
        echo -e "${BLUE}→ Latest NVM version: $LATEST_TAG${NC}" && \
        git checkout --quiet "$LATEST_TAG"
    ) && \. "$NVM_DIR/nvm.sh"
    
    # Check for Node.js LTS updates
    echo -e "${BLUE}→ Checking for Node.js LTS updates...${NC}"
    nvm install --lts --reinstall-packages-from=default
    
    echo -e "${GREEN}✓ NVM and Node.js current${NC}"
fi

# Update Claude Code if installed
if command -v claude > /dev/null; then
    echo -e "${BLUE}→ Updating Claude Code...${NC}"
    npm update -g @anthropic-ai/claude-code
    echo -e "${GREEN}✓ Claude Code current${NC}"
fi

# Update Chezmoi dotfiles if configured
if command -v chezmoi > /dev/null; then
    echo -e "${BLUE}→ Updating Chezmoi and dotfiles...${NC}"
    
    # Update Chezmoi itself
    chezmoi upgrade
    
    # Use chezmoi's built-in update command (recommended approach)
    # This pulls latest changes and applies them
    if chezmoi update --verbose; then
        echo -e "${GREEN}✓ Chezmoi and dotfiles synchronized${NC}"
    else
        echo -e "${YELLOW}! Chezmoi update had issues, trying manual approach...${NC}"
        
        # Fallback to manual update
        CHEZMOI_SOURCE_DIR="$HOME/dotfiles"
        if [ -d "$CHEZMOI_SOURCE_DIR/.git" ]; then
            echo -e "${BLUE}→ Checking for remote dotfile updates manually...${NC}"
            
            # Check if remote is properly set up
            cd "$CHEZMOI_SOURCE_DIR" || exit 1
            if git remote -v | grep -q origin; then
                # Check if we have a tracking branch set up
                if git symbolic-ref -q HEAD &>/dev/null; then
                    BRANCH=$(git symbolic-ref --short HEAD)
                    if git config --get "branch.$BRANCH.remote" &>/dev/null; then
                        # Pull updates
                        git pull --quiet
                        echo -e "${GREEN}✓ Dotfiles synchronized from remote${NC}"
                        
                        # Apply any updates
                        chezmoi apply
                    else
                        echo -e "${YELLOW}! No tracking branch configured. To set it up:${NC}"
                        echo -e "${YELLOW}! cd \"$CHEZMOI_SOURCE_DIR\" && git branch --set-upstream-to=origin/$BRANCH $BRANCH${NC}"
                    fi
                fi
            else
                echo -e "${YELLOW}! No remote repository configured for dotfiles${NC}"
            fi
            
            cd "$HOME" || exit 1
        fi
        
        echo -e "${GREEN}✓ Chezmoi manual update completed${NC}"
    fi
fi

echo -e "${CYAN}==== Update Complete ====${NC}"
echo -e "${GREEN}WSL development environment synchronization complete!${NC}"
exit 0
EOL
    
    chmod +x "$SETUP_DIR/update.sh"
    print_success "Update script created successfully"
    return 0
}

# Display final completion message
display_completion_message() {
    print_header "Setup Complete!"
    
    echo -e "${GREEN}Your WSL development environment has been successfully set up!${NC}"
    
    # Create path to the quick reference guide
    QUICK_REF_PATH="$SETUP_DIR/docs/quick-reference.md"
    
    # Check for GitHub repo setup and provide appropriate instructions
    if $GITHUB_REPO_CREATED; then
        echo -e "${GREEN}Your dotfiles are backed up to GitHub at: https://github.com/$GITHUB_USERNAME/dotfiles${NC}"
        echo -e "${BLUE}You can clone them on another machine with:${NC}"
        echo -e "chezmoi init https://github.com/$GITHUB_USERNAME/dotfiles.git"
    elif $USE_GITHUB; then
        echo -e "${YELLOW}GitHub repository setup was not completed.${NC}"
        echo -e "${BLUE}To create it later, run:${NC}"
        echo -e "cd ~/dotfiles && gh repo create dotfiles --private && git push -u origin main"
    fi
    
    # Show tools installed
    echo -e "\n${CYAN}Installed Tools:${NC}"
    # Detect which Kickstart version was installed
    if [ -d "$HOME/.config/nvim/lua/kickstart" ]; then
        echo -e "• Neovim (editor): ${GREEN}nvim${NC} with ${BLUE}Modular Kickstart${NC}"
    else
        echo -e "• Neovim (editor): ${GREEN}nvim${NC} with ${BLUE}Regular Kickstart${NC}"
    fi
    echo -e "• Tmux (terminal multiplexer): ${GREEN}tmux${NC}"
    echo -e "• Zsh (shell): ${GREEN}zsh${NC}"
    if [ "$USE_CHEZMOI" = true ]; then
        echo -e "• Chezmoi (dotfile manager): ${GREEN}chezmoi${NC}"
    fi
    echo -e "• Node.js (JavaScript runtime): ${GREEN}node${NC}"
    echo -e "• Cursor wrapper: ${GREEN}cursor${NC} or ${GREEN}code${NC}"
    if command_exists rmpc; then
        echo -e "• Music system: ${GREEN}rmpc${NC} (MPD client with Windows music access)"
    fi
    if command_exists claude; then
        echo -e "• Claude Code (AI assistant): ${GREEN}claude${NC}"
    fi
    
    # Show quick reference and documentation location
    echo -e "\n${CYAN}Documentation:${NC}"
    echo -e "Workflow guide: ${GREEN}cat ~/dev/docs/workflow-guide.md${NC}"
    echo -e "Quick reference: ${GREEN}cat $QUICK_REF_PATH${NC}"
    echo -e "All documentation: ${GREEN}ls ~/dev/docs/${NC}"
    if [ "$USE_CHEZMOI" = true ]; then
        echo -e "Chezmoi setup guide: ${GREEN}cat ~/dev/docs/chezmoi/getting-started.md${NC}"
        echo -e "Chezmoi user guide: ${BLUE}https://chezmoi.io/user-guide/${NC}"
    fi
    
    # Show update script location
    echo -e "\n${CYAN}Updates:${NC}"
    echo -e "To update your environment: ${GREEN}~/dev/update.sh${NC}"
    
    # Show dotfiles information
    echo -e "\n${CYAN}Dotfiles Management:${NC}"
    if [[ "$DOTFILES_DIR" == "/mnt/c/"* ]]; then
        echo -e "${GREEN}✓ Unified Windows + WSL dotfiles enabled${NC}"
        echo -e "Windows path: ${BLUE}$(echo "$DOTFILES_DIR" | sed 's|/mnt/c|C:|')${NC}"
        echo -e "WSL path: ${BLUE}$DOTFILES_DIR${NC}"
        echo -e "Edit from either Windows or WSL - changes sync automatically!"
    else
        echo -e "WSL-only dotfiles: ${BLUE}$DOTFILES_DIR${NC}"
    fi
    
    if [ "$USE_CHEZMOI" = true ]; then
        echo -e "Dotfile manager: ${GREEN}Chezmoi enabled${NC}"
        echo -e "Apply changes with: ${GREEN}chezmoi apply${NC}"
    else
        echo -e "Dotfile manager: ${YELLOW}Manual management (no Chezmoi)${NC}"
        echo -e "Edit configs directly in: ${BLUE}$DOTFILES_DIR${NC}"
    fi
    
    echo -e "\n${CYAN}Cursor Setup:${NC}"
    if command -v cursor >/dev/null 2>&1; then
        echo -e "Cursor is available via: ${GREEN}cursor .${NC} or ${GREEN}code .${NC}"
    else
        echo -e "${YELLOW}Note: Install Cursor on Windows for full functionality${NC}"
        echo -e "Download from: ${BLUE}https://cursor.sh${NC}"
        echo -e "After installation, run: ${GREEN}~/bin/cursor-path.sh${NC}"
    fi
    
    echo -e "\n${YELLOW}Your development environment is ready!${NC}"
    return 0
}

# --- Main Script Execution ---

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -i|--interactive)
            INTERACTIVE_MODE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo "Options:"
            echo "  -i, --interactive  Run in interactive mode (prompts for package installation)"
            echo "  -h, --help        Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

echo -e "${PURPLE}===============================================${NC}"
echo -e "${PURPLE}| WSL Development Environment Setup v${SCRIPT_VERSION} |${NC}"
echo -e "${PURPLE}===============================================${NC}"
echo -e "${GREEN}This script will set up a development environment optimized for WSL Arch Linux${NC}"

if [ "$INTERACTIVE_MODE" = true ]; then
    echo -e "${CYAN}Running in INTERACTIVE mode - you'll be prompted for each package installation${NC}\n"
else
    echo -e "${YELLOW}Note: This script runs in non-interactive mode. All package installations will proceed automatically.${NC}"
    echo -e "${YELLOW}You'll see [Y/n] prompts but they will be auto-answered with 'yes'.${NC}"
    echo -e "${YELLOW}To run in interactive mode, use: ./setup.sh --interactive${NC}\n"
fi

# Bootstrap the environment first
bootstrap_arch || exit 1

# No theme selection - clean minimal setup

# Step 1: Initial setup
setup_workspace || exit 1
optimize_mirrors || exit 1
test_mirror_connectivity || exit 1
update_system || exit 1
install_core_deps || exit 1

# Set up GitHub information after core deps are installed
setup_github_info || exit 1

# Step 2: Set up dotfiles directory and optionally chezmoi
determine_dotfiles_directory || exit 1

# Debug: Verify DOTFILES_DIR is set
if [ -z "$DOTFILES_DIR" ]; then
    print_error "DOTFILES_DIR variable is empty after determine_dotfiles_directory!"
    exit 1
fi
print_step "Debug: DOTFILES_DIR is set to: $DOTFILES_DIR"

ask_chezmoi || exit 1
if [ "$USE_CHEZMOI" = true ]; then
    setup_chezmoi || exit 1
fi

# Step 3: Enhanced installations
install_modern_cli_tools || print_warning "Modern CLI tools installation failed, continuing..."
setup_music_system || print_warning "Music system setup failed, continuing..."
# Ghostty terminal removed - doesn't work well in WSL
setup_windows_terminal_configs || print_warning "Windows terminal config setup failed, continuing..."
install_fastfetch || print_warning "Fastfetch installation failed, continuing..."
install_neovim || { print_error "Neovim installation failed"; exit 1; }
setup_nvim_config || exit 1
setup_git_config || print_warning "Git config setup failed, continuing..."
setup_nodejs || exit 1

# Step 4: Configure shell environment
setup_zsh_config || exit 1
setup_tmux_config || exit 1
setup_starship_config || exit 1
create_wsl_utilities || exit 1

# Step 5: Optional tools
setup_claude_code || print_warning "Claude Code installation skipped or failed, continuing..."

# Step 6: Documentation
if command_exists claude; then
    create_claude_code_docs || print_warning "Claude Code docs creation failed, continuing..."
fi
if [ "$USE_CHEZMOI" = true ]; then
    create_chezmoi_docs || print_warning "Chezmoi docs creation failed, continuing..."
else
    create_manual_dotfile_docs || print_warning "Manual dotfile docs creation failed, continuing..."
fi
create_component_docs || exit 1
create_update_script || exit 1

# Step 7: Final setup
setup_dotfiles_repo || exit 1

# Step 8: Verify everything is properly set up
verify_dotfiles_setup || print_warning "Some dotfiles may not be properly configured"

# Final setup and display completion message
display_completion_message

echo -e "\n${GREEN}Setup complete! To apply changes, please run:${NC}"
echo -e "${YELLOW}source ~/.bashrc${NC}"
echo -e "${YELLOW}or${NC} ${GREEN}restart your terminal${NC}"

# Set zsh as default shell (optional prompt)
if [ "$SHELL" != "/usr/bin/zsh" ] && [ -f /usr/bin/zsh ]; then
    echo -e "\n${BLUE}Would you like to set Zsh as your default shell? (y/n)${NC}"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        chsh -s /usr/bin/zsh
        echo -e "${GREEN}Zsh set as default shell. Please log out and log back in for this to take effect.${NC}"
    fi
fi

exit 0
