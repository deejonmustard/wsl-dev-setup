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
CHEZMOI_SOURCE_DIR=""  # Will be determined based on user preference
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

# --- Theme Selection ---

# Interactive theme selector
select_theme() {
    print_header "Select Your Preferred Setup Style"
    
    echo -e "${BLUE}Choose your setup approach:${NC}"
    echo "1) Minimal/None (Clean Arch Linux - build your own theme)"
    echo "2) Rose Pine (Themed setup with modern aesthetics)"
    echo "3) Catppuccin (Themed setup)"
    echo "4) Tokyo Night (Themed setup)"
    echo "5) Nord (Themed setup)"
    echo "6) Dracula (Themed setup)"
    
    read -r theme_choice
    
    case $theme_choice in
        1) SELECTED_THEME="minimal" ;;
        2) SELECTED_THEME="rose-pine" ;;
        3) SELECTED_THEME="catppuccin" ;;
        4) SELECTED_THEME="tokyo-night" ;;
        5) SELECTED_THEME="nord" ;;
        6) SELECTED_THEME="dracula" ;;
        *) SELECTED_THEME="minimal" ;;
    esac
    
    export SELECTED_THEME
    if [ "$SELECTED_THEME" = "minimal" ]; then
        print_success "Selected: Minimal setup - clean Arch Linux base"
    else
        print_success "Selected theme: $SELECTED_THEME"
    fi
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



# Function to safely add a file to chezmoi
safe_add_to_chezmoi() {
    local target_file="$1"
    local description="${2:-file}"
    local force="${3:-}"
    
    if [ ! -f "$target_file" ]; then
        print_error "$description not found at $target_file"
        return 1
    fi
    
    print_step "Managing $description with chezmoi..."
    if [ "$force" = "--force" ]; then
        if ! chezmoi add --force "$target_file"; then
            print_error "Failed to add $description to chezmoi"
            return 1
        fi
    else
        if ! chezmoi add "$target_file"; then
            print_error "Failed to add $description to chezmoi"
            return 1
        fi
    fi
    
    print_success "$description managed by chezmoi"
    return 0
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
    
    # Create config directories
    ensure_dir ~/dev/configs/nvim/custom || return 1
    ensure_dir ~/dev/configs/zsh || return 1
    ensure_dir ~/dev/configs/tmux || return 1
    ensure_dir ~/dev/configs/wsl || return 1
    ensure_dir ~/dev/configs/git || return 1
    ensure_dir ~/dev/bin || return 1
    ensure_dir ~/dev/docs || return 1

    # Create dotfiles directory in home
    ensure_dir ~/dotfiles || return 1

    SETUP_DIR="$HOME/dev"
    cd "$SETUP_DIR" || { 
        print_error "Failed to change directory to $SETUP_DIR"
        return 1
    }
    
    print_success "Directory structure created successfully"
    return 0
}

# Update system packages
update_system() {
    print_header "Updating System Packages"
    if [ "$INTERACTIVE_MODE" = false ]; then
        print_step "Updating package database (auto-accepting all prompts)..."
        run_elevated pacman -Syu --noconfirm --noprogressbar 2>&1 | grep -v "warning: insufficient columns"
    else
        print_step "Updating package database..."
        run_elevated pacman -Syu --noprogressbar 2>&1 | grep -v "warning: insufficient columns"
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
    
    run_elevated pacman -S --noconfirm --needed curl wget git python python-pip python-virtualenv unzip \
        base-devel file cmake ripgrep fd fzf tmux zsh \
        jq bat htop github-cli 2>&1 | grep -v "warning: insufficient columns"
    
    if [ ${PIPESTATUS[0]} -ne 0 ]; then
        print_error "Failed to install core dependencies"
        print_warning "You may need to run 'sudo pacman -Syu' first"
        return 1
    fi
    
    # Add local bin to PATH in bashrc if not already there
    if ! grep -q 'PATH="$HOME/.local/bin:$HOME/bin:$PATH"' ~/.bashrc; then
        echo 'export PATH="$HOME/.local/bin:$HOME/bin:$PATH"' >> ~/.bashrc
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
        run_elevated pacman -S --noconfirm --needed rust 2>&1 | grep -v "warning: insufficient columns"
        
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
    
    # Install modern CLI tools - some from pacman, some from cargo if available
    print_step "Installing modern CLI tools from package manager..."
    
    # Many of these tools are available in pacman and more reliable to install
    run_elevated pacman -S --noconfirm --needed \
        exa bat fd ripgrep starship \
        lazygit ranger ncdu duf gdu \
        2>&1 | grep -v "warning: insufficient columns"
    
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

# Setup modern terminal emulator configurations
setup_modern_terminal() {
    print_header "Installing Modern Terminal Dependencies"
    
    # Install dependencies for terminal emulators
    run_elevated pacman -S --noconfirm --needed \
        cmake freetype2 fontconfig pkg-config \
        2>&1 | grep -v "warning: insufficient columns"
    
    # Only create themed configs if not minimal setup
    if [ "$SELECTED_THEME" != "minimal" ]; then
        # Create config directories
        ensure_dir "$HOME/.config/wezterm"
        
        # Create WezTerm config with selected theme
        print_step "Creating WezTerm configuration..."
        cat > "$HOME/.config/wezterm/wezterm.lua" << EOF
local wezterm = require 'wezterm'
local config = {}

$(if [ "$SELECTED_THEME" = "rose-pine" ]; then
    echo "config.color_scheme = 'rose-pine-moon'"
elif [ "$SELECTED_THEME" = "catppuccin" ]; then
    echo "config.color_scheme = 'Catppuccin Mocha'"
elif [ "$SELECTED_THEME" = "tokyo-night" ]; then
    echo "config.color_scheme = 'Tokyo Night'"
elif [ "$SELECTED_THEME" = "nord" ]; then
    echo "config.color_scheme = 'Nord (Gogh)'"
elif [ "$SELECTED_THEME" = "dracula" ]; then
    echo "config.color_scheme = 'Dracula'"
else
    echo "-- Default theme"
fi)
config.font = wezterm.font('JetBrains Mono')
config.font_size = 11.0
config.window_background_opacity = 0.9
config.window_padding = {
    left = 20,
    right = 20,
    top = 20,
    bottom = 20,
}
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.hide_tab_bar_if_only_one_tab = true

return config
EOF
        
        # Add config to chezmoi
        safe_add_to_chezmoi "$HOME/.config/wezterm/wezterm.lua" "WezTerm configuration" || true
        print_success "WezTerm configuration created"
    else
        print_step "Minimal setup selected - skipping terminal theme configuration"
        print_step "You can configure your terminal manually later"
    fi
    
    return 0
}

# Install Fastfetch for system information display
install_fastfetch() {
    print_header "Installing Fastfetch"
    if ! command_exists fastfetch; then
        print_step "Installing Fastfetch (modern neofetch alternative)..."
        run_elevated pacman -S --noconfirm --needed fastfetch 2>&1 | grep -v "warning: insufficient columns"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
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

# Install Neovim text editor
install_neovim() {
    print_header "Installing Neovim"
    if ! command_exists nvim; then
        print_step "Installing Neovim from official Arch repository..."
        
        # Install the latest Neovim from Arch repos
        run_elevated pacman -S --noconfirm --needed neovim 2>&1 | grep -v "warning: insufficient columns"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            print_error "Failed to install Neovim"
            return 1
        fi
        
        # Create symlink in local bin for consistency
        ln -sf /usr/bin/nvim ~/.local/bin/nvim
        
        # Verify installation
        print_step "Verifying Neovim installation..."
        if command_exists nvim; then
            nvim --version
            print_success "Neovim installed successfully"
        else
            print_warning "Neovim installation verification failed."
            print_warning "You may need to restart your terminal or log out and back in."
            return 1
        fi
    else
        print_step "Neovim is already installed"
        nvim --version
    fi
    return 0
}

# Setup nvim with Kickstart configuration 
setup_nvim_config() {
    print_header "Setting up Neovim configuration with Chezmoi"
    
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
    
    print_step "Managing Neovim configuration with chezmoi..."
    
    mkdir -p "$HOME/.config"
    
    if [ -d "$HOME/.config/nvim" ] && [ "$(ls -A $HOME/.config/nvim)" ]; then
        BACKUP_DIR="$HOME/.config/nvim_backup_$(date +%Y%m%d%H%M%S)"
        print_step "Backing up existing Neovim configuration to $BACKUP_DIR"
        mv "$HOME/.config/nvim" "$BACKUP_DIR"
    fi
    
    cp -r "$TEMP_NVIM_DIR" "$HOME/.config/nvim"
    
    # Add the entire nvim config directory to chezmoi for complete dotfile management
    print_step "Adding Neovim configuration to chezmoi dotfiles..."
    if chezmoi add "$HOME/.config/nvim"; then
        print_success "Neovim configuration added to chezmoi"
        
        # Add to git if in a git repository
        if [ -d "$CHEZMOI_SOURCE_DIR/.git" ]; then
            cd "$CHEZMOI_SOURCE_DIR" || return 1
            if git add . && git commit -m "Add Neovim Kickstart configuration"; then
                print_step "Neovim configuration committed to dotfiles repository"
            else
                print_warning "Failed to commit Neovim configuration to git"
            fi
            cd "$HOME" || return 1
        fi
    else
        print_warning "Failed to add Neovim configuration to chezmoi, but installation succeeded"
    fi
    
    rm -rf "$TEMP_NVIM_DIR"
    
    print_success "Neovim Kickstart configuration installed and managed by chezmoi"
    return 0
}

# Enhanced Neovim setup with theme
setup_enhanced_nvim() {
    print_header "Setting up Enhanced Neovim Configuration"
    
    # Skip theme setup for minimal installations
    if [ "$SELECTED_THEME" = "minimal" ]; then
        print_step "Minimal setup selected - skipping Neovim theme configuration"
        print_step "Your Neovim uses the default Kickstart configuration"
        print_step "You can add themes and plugins manually later"
        return 0
    fi
    
    # Ask if user wants their selected theme for Neovim
    echo -e "\n${BLUE}Would you like to add the $SELECTED_THEME theme to your Neovim setup? (y/n) [y]${NC}"
    read -r add_theme
    add_theme=${add_theme:-y}
    
    if [[ "$add_theme" =~ ^[Yy]$ ]]; then
        print_step "Adding $SELECTED_THEME configuration to Neovim..."
        
        # Create custom plugins directory
        ensure_dir "$HOME/.config/nvim/lua/custom/plugins"
        
        # Create theme config based on selected theme
        cat > "$HOME/.config/nvim/lua/custom/plugins/theme.lua" << EOF
return {
$(if [ "$SELECTED_THEME" = "rose-pine" ]; then
cat << 'ROSE_PINE'
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    priority = 1000,
    config = function()
      require('rose-pine').setup({
        variant = 'moon',
        dim_inactive_windows = false,
        styles = {
          transparency = true,
        },
      })
      vim.cmd('colorscheme rose-pine')
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    end,
  },
ROSE_PINE
elif [ "$SELECTED_THEME" = "catppuccin" ]; then
cat << 'CATPPUCCIN'
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function()
      require("catppuccin").setup({
        flavour = "mocha",
        transparent_background = true,
      })
      vim.cmd('colorscheme catppuccin')
    end,
  },
CATPPUCCIN
elif [ "$SELECTED_THEME" = "tokyo-night" ]; then
cat << 'TOKYO_NIGHT'
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    config = function()
      require("tokyonight").setup({
        style = "night",
        transparent = true,
      })
      vim.cmd('colorscheme tokyonight')
    end,
  },
TOKYO_NIGHT
elif [ "$SELECTED_THEME" = "nord" ]; then
cat << 'NORD'
  {
    "shaunsingh/nord.nvim",
    priority = 1000,
    config = function()
      vim.g.nord_disable_background = true
      vim.cmd('colorscheme nord')
    end,
  },
NORD
elif [ "$SELECTED_THEME" = "dracula" ]; then
cat << 'DRACULA'
  {
    "Mofiqul/dracula.nvim",
    priority = 1000,
    config = function()
      require("dracula").setup({
        transparent_bg = true,
      })
      vim.cmd('colorscheme dracula')
    end,
  },
DRACULA
fi)
}
EOF
        
        # Check which version of kickstart we're using
        if [ -d "$HOME/.config/nvim/lua/kickstart" ]; then
            # Modular version - has a kickstart directory
            print_step "Detected Modular Kickstart configuration"
            
            # For modular kickstart, custom plugins go in lua/kickstart/plugins/
            ensure_dir "$HOME/.config/nvim/lua/kickstart/plugins/custom"
            
            # Move the theme to the appropriate location
            mv "$HOME/.config/nvim/lua/custom/plugins/theme.lua" \
               "$HOME/.config/nvim/lua/kickstart/plugins/custom/theme.lua" 2>/dev/null || true
            
            # Move UI enhancements
            mv "$HOME/.config/nvim/lua/custom/plugins/ui.lua" \
               "$HOME/.config/nvim/lua/kickstart/plugins/custom/ui.lua" 2>/dev/null || true
            
            # Update paths for chezmoi
            safe_add_to_chezmoi "$HOME/.config/nvim/lua/kickstart/plugins/custom/theme.lua" "Neovim Rose Pine theme" || true
            safe_add_to_chezmoi "$HOME/.config/nvim/lua/kickstart/plugins/custom/ui.lua" "Neovim UI enhancements" || true
            
            print_step "Custom plugins added to modular Kickstart structure"
        else
            # Regular version - single init.lua file
            print_step "Detected Regular Kickstart configuration"
            
            # Check if init.lua has custom plugin loading
            if ! grep -q "custom.plugins" "$HOME/.config/nvim/init.lua"; then
                print_step "Note: For regular Kickstart, add custom plugins directly to init.lua"
                print_step "Custom plugin files created in lua/custom/plugins/ for reference"
            fi
        fi
        
        # Add UI enhancements
        cat > "$HOME/.config/nvim/lua/custom/plugins/ui.lua" << 'EOF'
return {
  -- Status line
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = {
          theme = 'rose-pine',
        },
      })
    end
  },
  
  -- File tree
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require('nvim-tree').setup({
        view = {
          width = 35,
          side = 'left',
        },
        renderer = {
          indent_markers = {
            enable = true,
          },
        },
      })
    end
  },
}
EOF
        
        # Add the configurations to chezmoi
        safe_add_to_chezmoi "$HOME/.config/nvim/lua/custom/plugins/theme.lua" "Neovim $SELECTED_THEME theme" || true
        safe_add_to_chezmoi "$HOME/.config/nvim/lua/custom/plugins/ui.lua" "Neovim UI enhancements" || true
        
        print_success "$SELECTED_THEME theme added to Neovim configuration"
        print_step "Theme will be loaded on next Neovim start"
        print_step "Run ':Lazy' in Neovim to install the theme"
    else
        print_step "Skipping theme setup - using default Kickstart configuration"
    fi
    
    return 0
}



# Determine chezmoi source directory based on user preference
determine_chezmoi_source_dir() {
    print_header "Configuring Chezmoi Source Directory"
    
    echo -e "\n${CYAN}Choose your dotfiles management approach:${NC}"
    echo -e "${BLUE}1) Unified Windows + WSL dotfiles (recommended for cross-platform editing)${NC}"
    echo -e "   - Dotfiles stored in Windows-accessible location"
    echo -e "   - Edit from both Windows and WSL"
    echo -e "   - Single git repository for all dotfiles"
    echo -e ""
    echo -e "${BLUE}2) Separate WSL-only dotfiles${NC}"
    echo -e "   - Traditional Linux approach"
    echo -e "   - Dotfiles stored in WSL home directory"
    echo -e "   - Separate from Windows dotfiles"
    echo -e ""
    
    read -p "Enter your choice (1 or 2) [1]: " choice
    choice=${choice:-1}
    
    case $choice in
        1)
            # Get Windows username
            WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
            if [ -n "$WIN_USER" ]; then
                CHEZMOI_SOURCE_DIR="/mnt/c/Users/$WIN_USER/dotfiles"
                print_step "Using unified Windows-accessible dotfiles directory: $CHEZMOI_SOURCE_DIR"
                print_step "This allows editing dotfiles from both Windows and WSL"
            else
                print_warning "Could not determine Windows username, falling back to WSL-only"
                CHEZMOI_SOURCE_DIR="$HOME/dotfiles"
            fi
            ;;
        2)
            CHEZMOI_SOURCE_DIR="$HOME/dotfiles"
            print_step "Using WSL-only dotfiles directory: $CHEZMOI_SOURCE_DIR"
            ;;
        *)
            print_warning "Invalid choice, using unified approach"
            WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
            if [ -n "$WIN_USER" ]; then
                CHEZMOI_SOURCE_DIR="/mnt/c/Users/$WIN_USER/dotfiles"
            else
                CHEZMOI_SOURCE_DIR="$HOME/dotfiles"
            fi
            ;;
    esac
    
    print_success "Chezmoi source directory: $CHEZMOI_SOURCE_DIR"
}

# Setup Chezmoi for dotfile management
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
        print_step "Configuring chezmoi to use existing Windows dotfiles..."
        cat > "$HOME/.config/chezmoi/chezmoi.toml" << EOF
# Chezmoi configuration for WSL development environment
# Using existing Windows dotfiles directory
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
        
        # Check if it's already a git repo
        if [ -d "$WIN_DOTFILES/.git" ]; then
            print_step "Using existing git repository in Windows dotfiles"
        else
            # Initialize git if not already a repo
            print_step "Initializing git repository in existing dotfiles..."
            cd "$WIN_DOTFILES" || return 1
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
                git commit -m "Initial commit: My dotfiles managed by Chezmoi"
            fi
            
            cd "$HOME" || return 1
        fi
    else
        # Fallback to original behavior if no Windows dotfiles found
        print_warning "No Windows dotfiles found, falling back to WSL-only setup"
        print_header "Configuring Chezmoi Source Directory"
        
        echo -e "\n${CYAN}Choose your dotfiles management approach:${NC}"
        echo -e "${BLUE}1) Create unified Windows + WSL dotfiles (recommended)${NC}"
        echo -e "   - Dotfiles stored in Windows-accessible location"
        echo -e "   - Edit from both Windows and WSL"
        echo -e "   - Single git repository for all dotfiles"
        echo -e ""
        echo -e "${BLUE}2) Create WSL-only dotfiles${NC}"
        echo -e "   - Traditional Linux approach"
        echo -e "   - Dotfiles stored in WSL home directory"
        echo -e "   - Separate from Windows dotfiles"
        echo -e ""
        
        read -p "Enter your choice (1 or 2) [1]: " choice
        choice=${choice:-1}
        
        case $choice in
            1)
                CHEZMOI_SOURCE_DIR="/mnt/c/Users/$WIN_USER/dotfiles"
                print_step "Creating unified Windows-accessible dotfiles directory: $CHEZMOI_SOURCE_DIR"
                print_step "This allows editing dotfiles from both Windows and WSL"
                ;;
            2)
                CHEZMOI_SOURCE_DIR="$HOME/dotfiles"
                print_step "Creating WSL-only dotfiles directory: $CHEZMOI_SOURCE_DIR"
                ;;
            *)
                print_warning "Invalid choice, using unified approach"
                CHEZMOI_SOURCE_DIR="/mnt/c/Users/$WIN_USER/dotfiles"
                ;;
        esac
        
        # Create directory for chezmoi documentation
        ensure_dir "$SETUP_DIR/docs/chezmoi" || return 1
        ensure_dir "$CHEZMOI_SOURCE_DIR" || return 1
        
        # Configure chezmoi
        mkdir -p "$HOME/.config/chezmoi"
        print_step "Configuring chezmoi to use custom source directory: $CHEZMOI_SOURCE_DIR"
        cat > "$HOME/.config/chezmoi/chezmoi.toml" << EOF
# Chezmoi configuration for WSL development environment
# Using custom source directory for better organization
sourceDir = "$CHEZMOI_SOURCE_DIR"

[data]
    name = "$GIT_NAME"
    email = "$GIT_EMAIL"
    windowsUser = "$WIN_USER"
    
[edit]
    command = "nvim"
EOF
        
        # Initialize git repo in the source directory
        cd "$CHEZMOI_SOURCE_DIR" || return 1
        git init
        
        # Create a basic .gitignore file
        if [ ! -f ".gitignore" ]; then
            print_step "Creating basic .gitignore file for dotfiles repo..."
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
        
        cd "$HOME" || return 1
    fi
    
    # Create a simple README in the chezmoi source directory if it doesn't exist
    if [ ! -f "$CHEZMOI_SOURCE_DIR/README.md" ]; then
        cat > "$CHEZMOI_SOURCE_DIR/README.md" << 'EOL'
# My Dotfiles

This directory contains my dotfiles managed by [chezmoi](https://www.chezmoi.io).

## How to use

To apply changes:
```bash
chezmoi apply
```

To add a new file:
```bash
chezmoi add ~/.zshrc
```

For more information, see the [chezmoi documentation](https://www.chezmoi.io/user-guide/command-overview/).
EOL
    fi
    
    print_success "Chezmoi setup completed with source directory: $CHEZMOI_SOURCE_DIR"
    
    # Show helpful chezmoi commands
    echo -e "\n${CYAN}Helpful chezmoi commands:${NC}"
    echo -e "${BLUE}→ chezmoi add ~/.zshrc${NC}    # Add a file to be managed"
    echo -e "${BLUE}→ chezmoi edit ~/.zshrc${NC}   # Edit a managed file"
    echo -e "${BLUE}→ chezmoi diff${NC}            # See what would change"
    echo -e "${BLUE}→ chezmoi apply${NC}           # Apply changes"
    echo -e "${BLUE}→ chezmoi update${NC}          # Pull and apply latest changes"
    echo -e "${BLUE}→ chezmoi cd${NC}              # Open shell in source directory"
    
    # Show cross-platform information if using unified directory
    if [[ "$CHEZMOI_SOURCE_DIR" == "/mnt/c/"* ]]; then
        echo -e "\n${CYAN}Cross-Platform Usage:${NC}"
        echo -e "${BLUE}→ Windows path: $(echo "$CHEZMOI_SOURCE_DIR" | sed 's|/mnt/c|C:|')${NC}"
        echo -e "${BLUE}→ Edit from Windows: Open the above path in your editor${NC}"
        echo -e "${BLUE}→ Templates handle OS differences automatically${NC}"
        echo -e "${BLUE}→ Use 'chezmoi apply' after editing from Windows${NC}"
    fi
    
    return 0
}

# Setup Zsh shell with Oh My Zsh
setup_zsh() {
    print_header "Setting up Zsh with Oh My Zsh"
    
    # Install zsh if not already installed
    if ! command_exists zsh; then
        print_step "Installing Zsh..."
        run_elevated pacman -S --noconfirm --needed zsh 2>&1 | grep -v "warning: insufficient columns"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            print_error "Failed to install Zsh"
            return 1
        fi
    fi
    
    # Install Oh My Zsh if not already installed
    if [ ! -d "$HOME/.oh-my-zsh" ]; then
        print_step "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        if [ $? -ne 0 ]; then
            print_error "Failed to install Oh My Zsh"
            print_warning "Make sure you have internet connectivity"
            return 1
        fi
    else
        print_step "Oh My Zsh is already installed"
    fi
    
    # Install custom plugins
    print_step "Installing Zsh plugins..."
    
    # zsh-autosuggestions
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions \
            ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    fi
    
    # zsh-syntax-highlighting
    if [ ! -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
            ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting
    fi
    
    print_success "Zsh setup completed"
    return 0
}

# Setup Zsh configuration file
setup_zshrc() {
    print_header "Creating Zsh configuration file with Chezmoi"
    print_step "Creating Zsh configuration..."
    
    # Clean up any existing conflicting files in chezmoi source directory
    if [ -f "$CHEZMOI_SOURCE_DIR/dot_zshrc" ]; then
        print_step "Removing existing dot_zshrc from chezmoi source..."
        rm -f "$CHEZMOI_SOURCE_DIR/dot_zshrc"
    fi
    if [ -f "$CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl" ]; then
        print_step "Removing existing dot_zshrc.tmpl from chezmoi source..."
        rm -f "$CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl"
    fi
    
    # Create a temporary file with our zshrc content
    TEMP_ZSHRC=$(mktemp)
    
    cat > "$TEMP_ZSHRC" << EOL
# Path to Oh My Zsh installation
export ZSH="\$HOME/.oh-my-zsh"

# Theme - simple but informative
ZSH_THEME="robbyrussell"

# Plugins - keep minimal but useful
plugins=(
  git                      # Git integration
  zsh-autosuggestions      # Command suggestions as you type
  zsh-syntax-highlighting  # Syntax highlighting for commands
  fzf                      # Fuzzy finder
  tmux                     # Tmux integration
)

source \$ZSH/oh-my-zsh.sh

# Environment setup
export EDITOR='nvim'
export PATH="\$HOME/bin:\$HOME/.local/bin:/usr/local/bin:\$PATH"
export CHEZMOI_SOURCE_DIR="$CHEZMOI_SOURCE_DIR"

{{- if eq .chezmoi.os "linux" }}
# WSL/Linux specific configuration

# NVM setup if it exists
export NVM_DIR="\$HOME/.nvm"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# FZF Configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND="\$FZF_DEFAULT_COMMAND"

$(if [ "$SELECTED_THEME" != "minimal" ]; then
echo "# Run fastfetch and show quick reference at startup"
echo "if command -v fastfetch >/dev/null 2>&1; then"
echo "  fastfetch"
echo "  "
echo "  # Display a brief helpful summary after fastfetch"
echo "  echo \"\""
echo "  echo \"🚀 WSL Dev Environment - Quick Reference\""
echo "  echo \"───────────────────────────────────────\""
echo "  echo \"📝 Edit config files: chezmoi edit ~/.zshrc\""
echo "  echo \"🔄 Apply dotfile changes: chezmoi apply\""
echo "  echo \"📊 Check dotfile status: chezmoi status\""
echo "  echo \"💻 Editor: nvim | Multiplexer: tmux | Shell: zsh\""
echo "  echo \"📋 Docs: ~/dev/docs/ (try: cat ~/dev/docs/quick-reference.md)\""
echo "  echo \"🔨 Update environment: ~/dev/update.sh\""
echo "  echo \"\""
echo "fi"
else
echo "# Minimal setup - no fastfetch banner"
echo "echo \"WSL Arch Linux ready - configure as needed\""
fi)

# Editor aliases for WSL
alias cursor='\$HOME/bin/cursor-wrapper.sh'
alias code='\$HOME/bin/cursor-wrapper.sh'

# Use Linux versions of tools
if [ -f /usr/bin/git ]; then
    alias git='/usr/bin/git'
fi

if [ -f /usr/bin/python3 ]; then
    alias python3='/usr/bin/python3'
fi

# Alias neofetch to fastfetch for backward compatibility
if command -v fastfetch >/dev/null 2>&1; then
    alias neofetch='fastfetch'
fi

# Set npm to use Linux mode if available
if command -v npm >/dev/null 2>&1; then
    npm config set os linux >/dev/null 2>&1
fi

{{- else if eq .chezmoi.os "windows" }}
# Windows specific configuration
# Add Windows-specific aliases and environment variables here

{{- end }}

# Cross-platform aliases - work on both Windows and Linux
alias vim='nvim'
alias v='nvim'

# Modern CLI tool aliases (available for all setups)
alias ls='exa --icons --group-directories-first'
alias ll='exa -l --icons --group-directories-first'
alias la='exa -la --icons --group-directories-first'
alias tree='exa --tree --icons'
alias cat='bat'
alias find='fd'
alias grep='rg'

# Fallback aliases if modern tools aren't available
command -v exa >/dev/null || alias ls='ls --color=auto'
command -v exa >/dev/null || alias ll='ls -la'
command -v exa >/dev/null || alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'

# Tmux aliases (Linux only but safe to have)
alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux ls'

# Chezmoi aliases (using config file instead of --source flag)
alias cz='chezmoi'
alias cza='chezmoi add'
alias cze='chezmoi edit'
alias czd='chezmoi diff'
alias czap='chezmoi apply'
alias czup='chezmoi update'

# Better cd with zoxide (if available)
if command -v zoxide >/dev/null 2>&1; then
    eval "$(zoxide init zsh)"
    alias cd='z'
fi
EOL
    
    if [ $? -ne 0 ]; then
        print_error "Failed to create temporary Zsh configuration file"
        rm -f "$TEMP_ZSHRC"
        return 1
    fi
    
    # Add to chezmoi
    print_step "Managing zshrc with chezmoi..."
    
    # Check if ~/.zshrc already exists and backup if needed
    backup_file "$HOME/.zshrc"
    
    # Copy our template to chezmoi source directory as template
    cp "$TEMP_ZSHRC" "$CHEZMOI_SOURCE_DIR/dot_zshrc.tmpl"
    
    # Apply it to create the actual file
    cd "$HOME" && chezmoi apply dot_zshrc
    
    # Verify it was applied correctly
    if [ -f "$HOME/.zshrc" ]; then
        print_success "Zsh configuration created and managed by chezmoi"
    else
        print_error "Failed to apply zshrc from chezmoi"
        return 1
    fi
    
    # Cleanup
    rm -f "$TEMP_ZSHRC"
    
    return 0
}

# Setup Starship prompt
setup_starship_prompt() {
    print_header "Setting up Starship Prompt"
    
    # Install if not already installed via cargo
    if ! command_exists starship; then
        print_step "Installing Starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
    
    # Create config based on selected theme
    ensure_dir "$HOME/.config"
    
    if [ "$SELECTED_THEME" = "minimal" ]; then
        # Minimal starship config
        cat > "$HOME/.config/starship.toml" << 'EOF'
# Minimal Starship Configuration
format = """$directory$git_branch$git_status$character"""

[character]
success_symbol = '[❯](bold green)'
error_symbol = '[❯](bold red)'

[directory]
truncation_length = 3
truncate_to_repo = true
EOF
    elif [ "$SELECTED_THEME" = "rose-pine" ]; then
        cat > "$HOME/.config/starship.toml" << 'EOF'
format = """
[](#ea9a97)\
$os\
$username\
[](bg:#f6c177 fg:#ea9a97)\
$directory\
[](fg:#f6c177 bg:#3e8fb0)\
$git_branch\
$git_status\
[](fg:#3e8fb0 bg:#9ccfd8)\
$c\
$golang\
$nodejs\
$rust\
$python\
[](fg:#9ccfd8 bg:#c4a7e7)\
$time\
[ ](fg:#c4a7e7)\
\n$character"""

[username]
show_always = true
style_user = "bg:#ea9a97 fg:#232136"
format = '[ $user ]($style)'

[directory]
style = "bg:#f6c177 fg:#232136"
format = "[ $path ]($style)"
truncation_length = 3

[git_branch]
symbol = ""
style = "bg:#3e8fb0 fg:#232136"
format = '[ $symbol $branch ]($style)'

[time]
disabled = false
time_format = "%R"
style = "bg:#c4a7e7 fg:#232136"
format = '[ $time ]($style)'

[character]
success_symbol = '[➜](bold fg:#3e8fb0)'
error_symbol = '[➜](bold fg:#eb6f92)'
EOF
    else
        # Default config for other themes
        cat > "$HOME/.config/starship.toml" << 'EOF'
format = """$username$directory$git_branch$git_status$time$line_break$character"""

[character]
success_symbol = '[➜](bold green)'
error_symbol = '[➜](bold red)'

[directory]
truncation_length = 3
EOF
    fi
    
    # Add to chezmoi
    safe_add_to_chezmoi "$HOME/.config/starship.toml" "Starship prompt configuration" || true
    
    # Add starship to shell configs if not already there
    if ! grep -q "starship init zsh" "$HOME/.zshrc" 2>/dev/null; then
        echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
        safe_add_to_chezmoi "$HOME/.zshrc" "Zsh configuration with Starship" --force || true
    fi
    
    if ! grep -q "starship init bash" "$HOME/.bashrc" 2>/dev/null; then
        echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
        safe_add_to_chezmoi "$HOME/.bashrc" "Bash configuration with Starship" --force || true
    fi
    
    print_success "Starship prompt configured"
    return 0
}

# Setup WSL-specific optimizations
setup_wsl_optimizations() {
    print_header "Applying WSL-Specific Optimizations"
    
    # Create WSL configuration
    print_step "Creating WSL configuration..."
    if [ ! -f /etc/wsl.conf ]; then
        run_elevated tee /etc/wsl.conf > /dev/null << 'EOF'
[boot]
systemd=true

[interop]
enabled=true
appendWindowsPath=false

[network]
generateHosts=false
generateResolvConf=false
EOF
    fi
    
    # Add performance tweaks to shell configs
    if ! grep -q "WSL2 Performance Optimizations" "$HOME/.zshrc" 2>/dev/null; then
        cat >> "$HOME/.zshrc" << 'EOF'

# WSL2 Performance Optimizations
export WSL_INTEROP=/run/WSL/$(ls -1 /run/WSL | head -1)
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1
export CHOKIDAR_USEPOLLING=1
export NODE_OPTIONS="--max-old-space-size=4096"
EOF
        
        # Update chezmoi
        safe_add_to_chezmoi "$HOME/.zshrc" "Zsh configuration with WSL optimizations" --force || true
    fi
    
    print_success "WSL optimizations applied"
    return 0
}

# Install Nerd Fonts
install_nerd_fonts() {
    print_header "Installing Nerd Fonts"
    
    # Create fonts directory
    ensure_dir "$HOME/.local/share/fonts"
    
    # Download JetBrains Mono Nerd Font
    print_step "Downloading JetBrains Mono Nerd Font..."
    curl -L -o "/tmp/JetBrainsMono.zip" \
        "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip"
    
    # Extract fonts
    unzip -o "/tmp/JetBrainsMono.zip" -d "$HOME/.local/share/fonts/"
    
    # Update font cache
    fc-cache -fv
    
    # Cleanup
    rm -f "/tmp/JetBrainsMono.zip"
    
    print_success "Nerd Fonts installed"
    return 0
}

# Setup system monitoring tools
setup_system_monitoring() {
    print_header "Setting up system monitoring tools"
    
    # Install monitoring tools
    run_elevated pacman -S --noconfirm --needed \
        htop btop iotop nethogs \
        2>&1 | grep -v "warning: insufficient columns"
    
    # Create btop config with Rose Pine if selected
    ensure_dir "$HOME/.config/btop"
    if [ "$SELECTED_THEME" = "rose-pine" ]; then
        echo 'color_theme = "rose-pine"' > "$HOME/.config/btop/btop.conf"
    fi
    
    # Add to chezmoi
    safe_add_to_chezmoi "$HOME/.config/btop/btop.conf" "btop configuration" || true
    
    print_success "System monitoring tools installed"
    return 0
}

# Setup WSL clipboard integration
setup_wsl_clipboard_integration() {
    print_header "Setting up WSL clipboard integration"
    
    # Add to shell configs if not already there
    if ! grep -q "WSL Clipboard integration" "$HOME/.zshrc" 2>/dev/null; then
        cat >> "$HOME/.zshrc" << 'EOF'

# WSL Clipboard integration
alias pbcopy='clip.exe'
alias pbpaste='powershell.exe -command "Get-Clipboard"'

# Open in Windows browser
export BROWSER='/mnt/c/Program Files/Mozilla Firefox/firefox.exe'
alias browse='$BROWSER'
EOF
        
        # Update chezmoi
        safe_add_to_chezmoi "$HOME/.zshrc" "Zsh configuration with clipboard integration" --force || true
    fi
    
    print_success "Clipboard integration configured"
    return 0
}

# Setup tmux 
setup_tmux() {
    print_header "Setting up tmux configuration with Chezmoi"
    
    # Check if tmux is installed
    if ! command_exists tmux; then
        print_step "Installing tmux..."
        run_elevated pacman -S --noconfirm --needed tmux 2>&1 | grep -v "warning: insufficient columns"
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            print_error "Failed to install tmux"
            return 1
        fi
    fi
    
    # Create tmux configuration
    print_step "Creating tmux configuration..."
    TEMP_TMUX=$(mktemp)
    
    cat > "$TEMP_TMUX" << 'EOL'
# Use Ctrl+a as prefix (easier to reach than Ctrl+b)
unbind C-b
set-option -g prefix C-a
bind-key C-a send-prefix

# Improve colors and terminal compatibility
set -g default-terminal "screen-256color"

# Start window numbering at 1
set -g base-index 1
set -g pane-base-index 1
set -g renumber-windows on

# Reload config with 'r'
bind r source-file ~/.tmux.conf \; display "Config reloaded!"

# Split windows with | and - (and keep current path)
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind c new-window -c "#{pane_current_path}"

# Better navigation with vim-like keys
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Enable mouse support
set -g mouse on

# Increase scrollback buffer
set -g history-limit 10000

# Status bar - clean and informative
set -g status-position top
set -g status-style bg=default
set -g status-left "#[fg=green]Session: #S #[fg=yellow]#I #[fg=cyan]#P "
set -g status-left-length 40
set -g status-right "#[fg=cyan]%d %b %R"
set -g status-interval 60
EOL
    
    if [ $? -ne 0 ]; then
        print_error "Failed to create temporary tmux configuration"
        rm -f "$TEMP_TMUX"
        return 1
    fi
    
    # Backup existing file if needed
    backup_file "$HOME/.tmux.conf"
    
    # Copy our template to home directory
    cp "$TEMP_TMUX" "$HOME/.tmux.conf"
    
    # Add to chezmoi using the safe function
    safe_add_to_chezmoi "$HOME/.tmux.conf" "Tmux configuration"
    local result=$?
    
    # Cleanup
    rm -f "$TEMP_TMUX"
    
    if [ $result -ne 0 ]; then
        print_error "Failed to add tmux.conf to chezmoi"
        return 1
    fi
    
    print_success "tmux configuration created and managed by chezmoi"
    return 0
}

# Setup WSL utilities
setup_wsl_utilities() {
    print_header "Setting up WSL utilities with Chezmoi"
    
    # Temporary directory for WSL utility scripts
    TEMP_DIR=$(mktemp -d)
    
    # Create Cursor wrapper
    print_step "Creating Cursor wrapper script..."
    cat > "$TEMP_DIR/cursor-wrapper.sh" << 'EOL'
#!/bin/bash
# Cursor wrapper script for WSL

# If run with no arguments, open current directory
if [ $# -eq 0 ]; then
    cmd.exe /c "cursor" "$(wslpath -w "$(pwd)")" > /dev/null 2>&1
    exit $?
fi

# Convert Linux paths to Windows paths when needed
args=()
for arg in "$@"; do
    # Check if the argument is a file or directory that exists
    if [ -e "$arg" ]; then
        # Convert to Windows path
        win_path=$(wslpath -w "$arg")
        args+=("$win_path")
    else
        # Pass through as-is for flags or non-existent paths
        args+=("$arg")
    fi
done

# Launch Cursor via cmd.exe to avoid permission issues
cmd.exe /c "cursor" "${args[@]}" > /dev/null 2>&1
exit $?
EOL
    
    # Create Windows path opener
    print_step "Creating Windows path opener utility..."
    cat > "$TEMP_DIR/winopen" << 'EOL'
#!/bin/bash
# Open current directory or specified path in Windows Explorer

path_to_open="${1:-.}"
windows_path=$(wslpath -w "$(realpath "$path_to_open")")
explorer.exe "$windows_path"
EOL
    
    # Create clipboard utility
    print_step "Creating clipboard utility..."
    cat > "$TEMP_DIR/clip-copy" << 'EOL'
#!/bin/bash
# Copy text to Windows clipboard

if [ -p /dev/stdin ]; then
  # If data is being piped in
  cat - | clip.exe
else
  # If used with arguments
  echo -n "$*" | clip.exe
fi
EOL
    
    # Create Cursor PATH helper for common Windows installation paths
    print_step "Creating Cursor PATH helper..."
    cat > "$TEMP_DIR/cursor-path.sh" << 'EOL'
#!/bin/bash
# Helper script to find and add Cursor to PATH if installed on Windows

# Get Windows username (might be different from WSL username)
WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')

# Common Cursor installation paths
CURSOR_PATHS=(
    "/mnt/c/Users/$USER/AppData/Local/Programs/cursor/resources/app/bin"
    "/mnt/c/Users/${WIN_USER}/AppData/Local/Programs/cursor/resources/app/bin"
    "/mnt/c/Program Files/Cursor/resources/app/bin"
    "/mnt/c/Users/*/AppData/Local/Programs/cursor/resources/app/bin"
)

# Check if cursor is already in PATH
if command -v cursor >/dev/null 2>&1; then
    exit 0
fi

# Try to find Cursor installation
for path in "${CURSOR_PATHS[@]}"; do
    if [ -f "$path/cursor" ]; then
        # Add to PATH if not already there
        if [[ ":$PATH:" != *":$path:"* ]]; then
            export PATH="$PATH:$path"
            echo "# Cursor PATH (auto-detected)" >> ~/.bashrc
            echo "export PATH=\"\$PATH:$path\"" >> ~/.bashrc
            echo "Added Cursor to PATH: $path"
        fi
        exit 0
    fi
done

echo "Cursor installation not found in common Windows paths"
exit 1
EOL
    
    # Make scripts executable
    chmod +x "$TEMP_DIR/cursor-wrapper.sh"
    chmod +x "$TEMP_DIR/winopen"
    chmod +x "$TEMP_DIR/clip-copy"
    chmod +x "$TEMP_DIR/cursor-path.sh"
    
    # Create bin directory if it doesn't exist
    ensure_dir ~/bin || return 1
    
    # Backup existing scripts if needed
    for script in "cursor-wrapper.sh" "winopen" "clip-copy" "cursor-path.sh"; do
        if [ -f "$HOME/bin/$script" ]; then
            print_step "Backing up existing $script..."
            mv "$HOME/bin/$script" "$HOME/bin/${script}.backup.$(date +%Y%m%d%H%M%S)"
        fi
    done
    
    # Copy scripts to bin directory
    cp "$TEMP_DIR/cursor-wrapper.sh" "$HOME/bin/"
    cp "$TEMP_DIR/winopen" "$HOME/bin/"
    cp "$TEMP_DIR/clip-copy" "$HOME/bin/"
    cp "$TEMP_DIR/cursor-path.sh" "$HOME/bin/"
    
    # Add bin directory to chezmoi using the safe function
    print_step "Managing WSL utility scripts with chezmoi..."
    local result=0
    safe_add_to_chezmoi "$HOME/bin/cursor-wrapper.sh" "Cursor wrapper" || result=1
    safe_add_to_chezmoi "$HOME/bin/winopen" "Windows path opener" || result=1
    safe_add_to_chezmoi "$HOME/bin/clip-copy" "Clipboard utility" || result=1
    safe_add_to_chezmoi "$HOME/bin/cursor-path.sh" "Cursor PATH helper" || result=1
    
    # Try to auto-detect Cursor installation and add to PATH
    print_step "Checking for Cursor installation on Windows..."
    if "$HOME/bin/cursor-path.sh"; then
        print_success "Cursor found and added to PATH"
    else
        print_warning "Cursor not found in common Windows installation paths"
        print_warning "You may need to install Cursor or manually add it to your PATH"
    fi
    
    # Update bashrc with cursor alias via chezmoi
    if ! grep -q "alias cursor=" ~/.bashrc; then
        print_step "Configuring cursor and code aliases in .bashrc..."
        echo 'alias cursor="$HOME/bin/cursor-wrapper.sh"' >> ~/.bashrc
        echo 'alias code="$HOME/bin/cursor-wrapper.sh"' >> ~/.bashrc
        
        # Update bashrc in chezmoi
        if chezmoi managed ~/.bashrc &>/dev/null; then
            safe_add_to_chezmoi "$HOME/.bashrc" "Bash configuration with cursor alias" --force
        fi
    fi
    
    # Cleanup temporary directory
    rm -rf "$TEMP_DIR"
    
    if [ $result -ne 0 ]; then
        print_warning "Some WSL utilities may not have been added properly"
        return 1
    fi
    
    print_success "WSL utilities setup completed and managed by chezmoi"
    return 0
}

# Setup bash helper for users who prefer bash
setup_bashrc_helper() {
    print_header "Setting up Bash quick reference with Chezmoi"
    print_step "Adding quick reference to .bashrc..."
    
    # Check if .bashrc exists
    if [ ! -f "$HOME/.bashrc" ]; then
        print_warning "No .bashrc file found. Creating a basic one..."
        touch "$HOME/.bashrc"
    fi
    
    # First, make a backup of current .bashrc
    BASHRC_BACKUP="$HOME/.bashrc.backup.$(date +%Y%m%d%H%M%S)"
    cp "$HOME/.bashrc" "$BASHRC_BACKUP"
    print_step "Backed up existing .bashrc to $BASHRC_BACKUP"
    
    # Create a temp file with the quick reference content
    QUICK_REF=$(mktemp)
    cat > "$QUICK_REF" << 'EOL'

# Export chezmoi source directory
export CHEZMOI_SOURCE_DIR="$HOME/dotfiles"

# Display helpful quick reference after fastfetch
if command -v fastfetch >/dev/null 2>&1; then
  # Display a brief helpful summary
  echo ""
  echo "🚀 WSL Dev Environment - Quick Reference"
  echo "───────────────────────────────────────"
  echo "📝 Edit config files: chezmoi edit ~/.bashrc"
  echo "🔄 Apply dotfile changes: chezmoi apply"
  echo "📊 Check dotfile status: chezmoi status"
  echo "💻 Editor: nvim | Multiplexer: tmux"
  echo "📋 Docs: ~/dev/docs/ (try: cat ~/dev/docs/quick-reference.md)"
  echo "🔨 Update environment: ~/dev/update.sh"
  echo ""
fi

# Chezmoi aliases (using config file instead of --source flag)
alias cz='chezmoi'
alias cza='chezmoi add'
alias cze='chezmoi edit'
alias czd='chezmoi diff'
alias czap='chezmoi apply'
EOL
    
    # Check if fastfetch alias exists, add if not
    if ! grep -q "alias neofetch='fastfetch'" "$HOME/.bashrc"; then
        print_step "Configuring neofetch alias in .bashrc..."
        echo "alias neofetch='fastfetch'" >> "$HOME/.bashrc"
    fi
    
    # Check if quick reference already exists, add if not
    if ! grep -q "WSL Dev Environment - Quick Reference" "$HOME/.bashrc"; then
        print_step "Configuring quick reference in .bashrc..."
        cat "$QUICK_REF" >> "$HOME/.bashrc"
    else
        print_step "Quick reference already exists in .bashrc"
    fi
    
    # Important: Add .bashrc to chezmoi AFTER all modifications
    print_step "Managing .bashrc with chezmoi..."
    if chezmoi managed ~/.bashrc &>/dev/null; then
        # Already managed by chezmoi, update it
        print_step "Updating .bashrc in chezmoi..."
        safe_add_to_chezmoi "$HOME/.bashrc" "Bash configuration" --force
    else
        # First time managing with chezmoi
        safe_add_to_chezmoi "$HOME/.bashrc" "Bash configuration"
    fi
    
    local result=$?
    if [ $result -ne 0 ]; then
        print_error "Failed to add .bashrc to chezmoi"
        print_warning "Restoring backup of .bashrc..."
        cp "$BASHRC_BACKUP" "$HOME/.bashrc"
        rm -f "$QUICK_REF"
        return 1
    fi
    
    # Verify that NVM configuration is preserved
    if grep -q "export NVM_DIR=\"\$HOME/.nvm\"" "$HOME/.bashrc"; then
        print_success "NVM configuration preserved in .bashrc"
    else
        # If NVM config is missing, check if it was in the backup and restore it
        if grep -q "export NVM_DIR=\"\$HOME/.nvm\"" "$BASHRC_BACKUP"; then
            print_warning "NVM configuration was missing, restoring it..."
            # Extract NVM config from backup and append to current .bashrc
            grep -A 3 "export NVM_DIR" "$BASHRC_BACKUP" >> "$HOME/.bashrc"
            # Update chezmoi again
            safe_add_to_chezmoi "$HOME/.bashrc" "Bash configuration with NVM" --force
            if [ $? -eq 0 ]; then
                print_success "NVM configuration restored and added to chezmoi"
            else
                print_error "Failed to update .bashrc in chezmoi with NVM configuration"
            fi
        else
            print_warning "No NVM configuration found in .bashrc"
        fi
    fi
    
    # Cleanup
    rm -f "$QUICK_REF"
    
    print_success ".bashrc setup completed and managed by chezmoi"
    return 0
}

# Setup dotfiles repository for chezmoi
setup_dotfiles_repo() {
    print_header "Setting up dotfiles repository"
    
    # Check if chezmoi is available
    if ! command_exists chezmoi; then
        print_error "Chezmoi is not installed. Run setup_chezmoi first."
        return 1
    fi
    
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
    if [ -d "$CHEZMOI_SOURCE_DIR/.git" ]; then
        print_step "Dotfiles repository already initialized"
        
        # Change to the source directory
        cd "$CHEZMOI_SOURCE_DIR" || return 1
        
        # Make sure we're on the main branch
        git checkout main 2>/dev/null || git checkout -b main
        
        # Check if the branch has any commits
        if ! git rev-parse --verify main >/dev/null 2>&1; then
            # If not, stage all files and make an initial commit
            print_step "Creating initial commit on main branch..."
            git add .
            git commit -m "Initial commit: My dotfiles managed by Chezmoi"
        fi
        
        # Setup GitHub repository
        setup_github_repository "dotfiles" "My dotfiles managed by Chezmoi"
    else
        print_step "Initializing dotfiles repository"
        
        # Initialize git in chezmoi source directory
        cd "$CHEZMOI_SOURCE_DIR" || return 1
        
        # Initialize Git and set main as the default branch
        git init -b main
        
        # Add all files
        git add .
        
        # Create initial commit with a meaningful message
        git commit -m "Initial commit: My dotfiles managed by Chezmoi"
        
        # Setup GitHub repository
        setup_github_repository "dotfiles" "My dotfiles managed by Chezmoi"
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
    
    # Change directory to chezmoi source directory
    cd "$CHEZMOI_SOURCE_DIR" || return 1
    
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
                print_warning "cd $CHEZMOI_SOURCE_DIR && git push -u origin $current_branch"
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
                print_warning "2. Run: cd $CHEZMOI_SOURCE_DIR && git push -u origin $current_branch"
            fi
        fi
    fi
    
    return 0
}

# Setup Git configuration with chezmoi
setup_git_config() {
    print_header "Setting up Git configuration with Chezmoi"
    
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
    
    # Check if user already has Git config
    if [ -f "$HOME/.gitconfig" ]; then
        print_step "Existing Git configuration found. Managing with chezmoi..."
        safe_add_to_chezmoi "$HOME/.gitconfig" "Git configuration"
        return $?
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
        
        # Create temporary gitconfig
        TEMP_GITCONFIG=$(mktemp)
        
        cat > "$TEMP_GITCONFIG" << EOL
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
        
        # Copy to home directory
        cp "$TEMP_GITCONFIG" "$HOME/.gitconfig"
        
        # Add to chezmoi
        print_step "Managing Git configuration with chezmoi..."
        safe_add_to_chezmoi "$HOME/.gitconfig" "Git configuration"
        
        # Cleanup
        rm -f "$TEMP_GITCONFIG"
    else
        print_step "Skipping Git configuration setup"
    fi
    
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
    print_warning "You'll need at least $5 in credits to use Claude Code"
    
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

# Create Chezmoi documentation
create_chezmoi_docs() {
    print_header "Creating Chezmoi documentation"
    
    ensure_dir "$SETUP_DIR/docs/chezmoi" || return 1
    
    # Create a basic documentation file
    cat > "$SETUP_DIR/docs/chezmoi/getting-started.md" << EOL
# Getting Started with Chezmoi

Chezmoi is a dotfile manager that helps you manage your configuration files across multiple machines.

## Your Setup

Your chezmoi source directory is: \`$CHEZMOI_SOURCE_DIR\`

$(if [[ "$CHEZMOI_SOURCE_DIR" == "/mnt/c/"* ]]; then
    echo "This is a **unified Windows + WSL setup** that allows cross-platform dotfile editing!"
    echo ""
    echo "### Cross-Platform Editing"
    echo ""
    echo "- **WSL path:** \`$CHEZMOI_SOURCE_DIR\`"
    echo "- **Windows path:** \`$(echo "$CHEZMOI_SOURCE_DIR" | sed 's|/mnt/c|C:|')\`"
    echo ""
    echo "You can edit your dotfiles from either Windows or WSL:"
    echo ""
    echo "1. **From Windows:** Open \`$(echo "$CHEZMOI_SOURCE_DIR" | sed 's|/mnt/c|C:|')\` in your editor"
    echo "2. **From WSL:** Use \`chezmoi edit\` or \`chezmoi cd\`"
    echo "3. **Apply changes:** Run \`chezmoi apply\` after editing"
    echo ""
    echo "### Templates Handle OS Differences"
    echo ""
    echo "Your \`.zshrc\` file uses chezmoi templates to handle differences between Windows and Linux:"
    echo ""
    echo "\`\`\`bash"
    echo "{{- if eq .chezmoi.os \"linux\" }}"
    echo "# WSL/Linux specific configuration"
    echo "{{- else if eq .chezmoi.os \"windows\" }}"
    echo "# Windows specific configuration"
    echo "{{- end }}"
    echo "\`\`\`"
else
    echo "This is a **WSL-only setup** with dotfiles stored in your WSL home directory."
fi)

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
        LATEST_TAG=$(git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)) && \
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
                        echo -e "${YELLOW}! cd $CHEZMOI_SOURCE_DIR && git branch --set-upstream-to=origin/$BRANCH $BRANCH${NC}"
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
    echo -e "• Chezmoi (dotfile manager): ${GREEN}chezmoi${NC}"
    echo -e "• Node.js (JavaScript runtime): ${GREEN}node${NC}"
    echo -e "• Cursor wrapper: ${GREEN}cursor${NC} or ${GREEN}code${NC}"
    if command_exists claude; then
        echo -e "• Claude Code (AI assistant): ${GREEN}claude${NC}"
    fi
    
    # Show quick reference and documentation location
    echo -e "\n${CYAN}Documentation:${NC}"
    echo -e "Workflow guide: ${GREEN}cat ~/dev/docs/workflow-guide.md${NC}"
    echo -e "Quick reference: ${GREEN}cat $QUICK_REF_PATH${NC}"
    echo -e "All documentation: ${GREEN}ls ~/dev/docs/${NC}"
    echo -e "Chezmoi setup guide: ${GREEN}cat ~/dev/docs/chezmoi/getting-started.md${NC}"
    echo -e "Chezmoi user guide: ${BLUE}https://chezmoi.io/user-guide/${NC}"
    
    # Show update script location
    echo -e "\n${CYAN}Updates:${NC}"
    echo -e "To update your environment: ${GREEN}~/dev/update.sh${NC}"
    
    # Show dotfiles information
    echo -e "\n${CYAN}Dotfiles Management:${NC}"
    if [[ "$CHEZMOI_SOURCE_DIR" == "/mnt/c/"* ]]; then
        echo -e "${GREEN}✓ Unified Windows + WSL dotfiles enabled${NC}"
        echo -e "Windows path: ${BLUE}$(echo "$CHEZMOI_SOURCE_DIR" | sed 's|/mnt/c|C:|')${NC}"
        echo -e "WSL path: ${BLUE}$CHEZMOI_SOURCE_DIR${NC}"
        echo -e "Edit from either Windows or WSL - changes sync automatically!"
    else
        echo -e "WSL-only dotfiles: ${BLUE}$CHEZMOI_SOURCE_DIR${NC}"
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

# Theme selection
select_theme || SELECTED_THEME="minimal"

# Step 1: Initial setup
setup_workspace || exit 1
update_system || exit 1
install_core_deps || exit 1

# Set up GitHub information after core deps are installed
setup_github_info || exit 1

# Step 2: Set up chezmoi early for dotfile management (FIXED version for user's setup)
setup_chezmoi || exit 1

# Step 3: Enhanced installations
install_modern_cli_tools || print_warning "Modern CLI tools installation failed, continuing..."
setup_modern_terminal || print_warning "Modern terminal setup failed, continuing..."
install_nerd_fonts || print_warning "Nerd fonts installation failed, continuing..."
install_fastfetch || print_warning "Fastfetch installation failed, continuing..."
install_neovim || { print_error "Neovim installation failed"; exit 1; }
setup_nvim_config || exit 1
setup_enhanced_nvim || print_warning "Enhanced Neovim setup failed, continuing..."
setup_git_config || print_warning "Git config setup failed, continuing..."
setup_zsh || { print_error "Zsh setup failed"; exit 1; }
setup_nodejs || exit 1
setup_starship_prompt || print_warning "Starship prompt setup failed, continuing..."

# Step 4: Configure dotfiles
setup_zshrc || exit 1
setup_tmux || exit 1
setup_wsl_utilities || exit 1
setup_wsl_optimizations || print_warning "WSL optimizations failed, continuing..."
setup_wsl_clipboard_integration || print_warning "WSL clipboard integration failed, continuing..."
setup_bashrc_helper || exit 1

# Step 5: Optional tools
setup_claude_code || print_warning "Claude Code installation skipped or failed, continuing..."
setup_system_monitoring || print_warning "System monitoring tools setup failed, continuing..."

# Step 6: Documentation
if command_exists claude; then
    create_claude_code_docs || print_warning "Claude Code docs creation failed, continuing..."
fi
create_chezmoi_docs || exit 1
create_component_docs || exit 1
create_update_script || exit 1

# Step 7: Final setup
setup_dotfiles_repo || exit 1

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
