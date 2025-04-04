#!/bin/bash

# ===================================
# WSL Development Environment Setup
# A beginner-friendly setup for WSL Debian
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
SCRIPT_VERSION="0.3.2"
NVIM_VERSION="0.10.0"
SETUP_DIR="$HOME/dev-env"
CHEZMOI_SOURCE_DIR="$HOME/dev-env/dotfiles"
GITHUB_USERNAME=""
GITHUB_TOKEN=""
USE_GITHUB=false
GITHUB_REPO_CREATED=false

# --- Utility functions ---

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

# Function to safely add a file to chezmoi
safe_add_to_chezmoi() {
    local target_file="$1"
    local description="${2:-file}"
    local force="${3:-}"
    
    if [ ! -f "$target_file" ]; then
        print_error "$description not found at $target_file"
        return 1
    fi
    
    print_step "Adding $description to chezmoi..."
    if [ "$force" = "--force" ]; then
        if ! chezmoi add --source="$CHEZMOI_SOURCE_DIR" --force "$target_file"; then
            print_error "Failed to add $description to chezmoi"
            return 1
        fi
    else
        if ! chezmoi add --source="$CHEZMOI_SOURCE_DIR" "$target_file"; then
            print_error "Failed to add $description to chezmoi"
            return 1
        fi
    fi
    
    print_success "$description added to chezmoi successfully"
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
    ensure_dir ~/dev-env || return 1
    ensure_dir ~/.local/bin || return 1
    ensure_dir ~/bin || return 1
    ensure_dir ~/dev || return 1

    # Create projects directory
    ensure_dir ~/dev-env/projects || return 1
    
    # Create config directories
    ensure_dir ~/dev-env/configs/nvim/custom || return 1
    ensure_dir ~/dev-env/configs/zsh || return 1
    ensure_dir ~/dev-env/configs/tmux || return 1
    ensure_dir ~/dev-env/configs/wsl || return 1
    ensure_dir ~/dev-env/configs/git || return 1
    ensure_dir ~/dev-env/bin || return 1
    ensure_dir ~/dev-env/docs || return 1

    SETUP_DIR="$HOME/dev-env"
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
    print_step "Updating package lists..."
    sudo apt update
    if [ $? -ne 0 ]; then
        print_error "Failed to update package lists"
        return 1
    fi

    print_step "Upgrading packages..."
    sudo apt upgrade -y
    if [ $? -ne 0 ]; then
        print_error "Failed to upgrade packages"
        return 1
    fi
    
    print_success "System packages updated successfully"
    return 0
}

# Install core dependencies
install_core_deps() {
    print_header "Installing Core Dependencies"
    print_step "Installing essential packages..."
    
    sudo apt install -y curl wget git python3 python3-pip python3-venv unzip \
        build-essential file cmake ripgrep fd-find fzf tmux zsh \
        jq bat htop
    
    if [ $? -ne 0 ]; then
        print_error "Failed to install core dependencies"
        print_warning "You may need to run 'sudo apt update' first"
        return 1
    fi
    
    # Create symlinks for Debian-specific tool names if needed
    if [ -f /usr/bin/fdfind ] && [ ! -f ~/.local/bin/fd ]; then
        mkdir -p ~/.local/bin
        ln -sf /usr/bin/fdfind ~/.local/bin/fd
    fi
    
    if [ -f /usr/bin/batcat ] && [ ! -f ~/.local/bin/bat ]; then
        mkdir -p ~/.local/bin
        ln -sf /usr/bin/batcat ~/.local/bin/bat
    fi
    
    # Add local bin to PATH in bashrc if not already there
    if ! grep -q 'PATH="$HOME/.local/bin:$HOME/bin:$PATH"' ~/.bashrc; then
        echo 'export PATH="$HOME/.local/bin:$HOME/bin:$PATH"' >> ~/.bashrc
    fi
    
    print_success "Core dependencies installed successfully"
    return 0
}

# Install Neofetch for system information display
install_neofetch() {
    print_header "Installing Neofetch"
    if ! command_exists neofetch || ! [ -f "/usr/bin/neofetch" ]; then
        print_step "Installing Neofetch..."
        sudo apt install -y neofetch
        if [ $? -ne 0 ]; then
            print_error "Failed to install Neofetch"
            return 1
        fi
        
        # Create an alias to ensure Linux version is used
        if ! grep -q "alias neofetch='/usr/bin/neofetch'" ~/.bashrc; then
            echo "alias neofetch='/usr/bin/neofetch'" >> ~/.bashrc
        fi
        
        print_success "Neofetch installed successfully"
    else
        print_step "Neofetch is already installed"
        
        # Ensure the alias exists
        if ! grep -q "alias neofetch='/usr/bin/neofetch'" ~/.bashrc; then
            echo "alias neofetch='/usr/bin/neofetch'" >> ~/.bashrc
        fi
    fi
    return 0
}

# Install Neovim text editor
install_neovim() {
    print_header "Installing Neovim"
    if ! command_exists nvim; then
        print_step "Downloading Neovim..."
        
        # Create temporary directory for installation
        TEMP_DIR=$(mktemp -d)
        if [ $? -ne 0 ]; then
            print_error "Failed to create temporary directory for Neovim installation"
            return 1
        fi
        
        cd "$TEMP_DIR" || { 
            print_error "Failed to change directory to $TEMP_DIR"
            return 1
        }
        
        # Download Neovim AppImage
        print_step "Downloading Neovim v${NVIM_VERSION}..."
        wget -q "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim.appimage"
        if [ $? -ne 0 ]; then
            print_error "Failed to download Neovim AppImage"
            return 1
        fi
        
        # Make it executable
        chmod u+x nvim.appimage
        if [ $? -ne 0 ]; then
            print_error "Failed to make Neovim AppImage executable"
            return 1
        fi
        
        # Extract the AppImage
        print_step "Extracting Neovim AppImage..."
        ./nvim.appimage --appimage-extract
        if [ $? -ne 0 ]; then
            print_error "Failed to extract Neovim AppImage"
            return 1
        fi
        
        # Create the target directory and move files
        print_step "Installing Neovim..."
        sudo mkdir -p /opt/nvim
        if [ $? -ne 0 ]; then
            print_error "Failed to create /opt/nvim directory"
            return 1
        fi
        
        sudo cp -r squashfs-root/* /opt/nvim/
        if [ $? -ne 0 ]; then
            print_error "Failed to copy Neovim files to /opt/nvim"
            return 1
        fi
        
        # Create symlinks
        sudo ln -sf /opt/nvim/AppRun /usr/local/bin/nvim
        if [ $? -ne 0 ]; then
            print_error "Failed to create system-wide Neovim symlink"
            return 1
        fi
        
        ln -sf /usr/local/bin/nvim ~/.local/bin/nvim
        
        # Clean up temporary files
        cd "$HOME" || {
            print_error "Failed to return to home directory"
            return 1
        }
        rm -rf "$TEMP_DIR"
        
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
    print_step "Setting up Kickstart Neovim configuration..."

    # Create a temporary directory for cloning kickstart
    TEMP_NVIM_DIR=$(mktemp -d)
    
    # Check if we have GitHub username and if user has their own fork
    if $USE_GITHUB && [ -n "$GITHUB_USERNAME" ]; then
        echo -e "\n${BLUE}Do you have your own fork of kickstart.nvim on GitHub? (y/n)${NC}"
        read -r has_fork
        
        if [[ "$has_fork" =~ ^[Yy]$ ]]; then
            # Use the stored GitHub username
            print_step "Cloning from your fork at https://github.com/$GITHUB_USERNAME/kickstart.nvim.git"
            git clone --depth=1 "https://github.com/$GITHUB_USERNAME/kickstart.nvim.git" "$TEMP_NVIM_DIR"
            
            # Modify .gitignore to track lazy-lock.json as recommended
            if [ -f "$TEMP_NVIM_DIR/.gitignore" ]; then
                print_step "Modifying .gitignore to track lazy-lock.json..."
                sed -i '/lazy-lock.json/d' "$TEMP_NVIM_DIR/.gitignore"
                print_success "Modified .gitignore to track lazy-lock.json"
            fi
        else
            # Clone default kickstart.nvim
            print_step "Installing Kickstart Neovim from official repository..."
            git clone --depth=1 https://github.com/nvim-lua/kickstart.nvim.git "$TEMP_NVIM_DIR"
        fi
    else
        # Ask if user has their own fork (original behavior if no GitHub username provided)
        echo -e "\n${BLUE}Do you have your own fork of kickstart.nvim on GitHub? (y/n)${NC}"
        read -r has_fork
        
        if [[ "$has_fork" =~ ^[Yy]$ ]]; then
            # Ask for GitHub username
            echo -e "${BLUE}Please enter your GitHub username:${NC}"
            read -r github_username
            
            if [ -z "$github_username" ]; then
                print_warning "No username provided, falling back to default repository"
                git clone --depth=1 https://github.com/nvim-lua/kickstart.nvim.git "$TEMP_NVIM_DIR"
            else
                # Clone from user's fork
                print_step "Cloning from your fork at https://github.com/$github_username/kickstart.nvim.git"
                git clone --depth=1 "https://github.com/$github_username/kickstart.nvim.git" "$TEMP_NVIM_DIR"
                
                # Modify .gitignore to track lazy-lock.json as recommended
                if [ -f "$TEMP_NVIM_DIR/.gitignore" ]; then
                    print_step "Modifying .gitignore to track lazy-lock.json..."
                    sed -i '/lazy-lock.json/d' "$TEMP_NVIM_DIR/.gitignore"
                    print_success "Modified .gitignore to track lazy-lock.json"
                fi
            fi
        else
            # Clone default kickstart.nvim
            print_step "Installing Kickstart Neovim from official repository..."
            git clone --depth=1 https://github.com/nvim-lua/kickstart.nvim.git "$TEMP_NVIM_DIR"
        fi
    fi
    
    if [ $? -ne 0 ]; then
        print_error "Failed to clone Kickstart Neovim"
        print_warning "Make sure git is installed and you have internet connectivity"
        rm -rf "$TEMP_NVIM_DIR"
        return 1
    fi
    
    # Create the custom directory
    mkdir -p "$TEMP_NVIM_DIR/lua/custom"
    
    print_step "Adding Neovim configuration to chezmoi..."
    
    mkdir -p "$HOME/.config"
    
    if [ -d "$HOME/.config/nvim" ] && [ "$(ls -A $HOME/.config/nvim)" ]; then
        BACKUP_DIR="$HOME/.config/nvim_backup_$(date +%Y%m%d%H%M%S)"
        print_step "Backing up existing Neovim configuration to $BACKUP_DIR"
        mv "$HOME/.config/nvim" "$BACKUP_DIR"
    fi
    
    cp -r "$TEMP_NVIM_DIR" "$HOME/.config/nvim"
    
    chezmoi add --source="$CHEZMOI_SOURCE_DIR" "$HOME/.config/nvim"
    
    rm -rf "$TEMP_NVIM_DIR"
    
    print_success "Neovim Kickstart configuration installed and added to chezmoi"
    return 0
}

# Setup Ansible
setup_ansible() {
    print_header "Setting up Ansible"
    if ! command_exists ansible; then
        print_step "Installing Ansible..."
        sudo apt install -y ansible
        if [ $? -ne 0 ]; then
            print_error "Failed to install Ansible"
            return 1
        fi
        print_success "Ansible installed successfully!"
    else
        print_step "Ansible is already installed"
    fi
    
    # Create Ansible directory structure
    ensure_dir "$SETUP_DIR/ansible/roles/core-tools/tasks" || return 1
    ensure_dir "$SETUP_DIR/ansible/roles/shell/tasks" || return 1
    ensure_dir "$SETUP_DIR/ansible/roles/tmux/tasks" || return 1
    ensure_dir "$SETUP_DIR/ansible/roles/wsl-specific/tasks" || return 1
    ensure_dir "$SETUP_DIR/ansible/roles/git-config/tasks" || return 1
    ensure_dir "$SETUP_DIR/ansible/roles/nodejs/tasks" || return 1
    
    print_success "Ansible setup completed"
    return 0
}

# Setup Chezmoi for dotfile management
setup_chezmoi() {
    print_header "Setting up Chezmoi for dotfile management"
    
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
    
    # Create directory for chezmoi documentation
    ensure_dir "$SETUP_DIR/docs/chezmoi" || return 1
    ensure_dir "$CHEZMOI_SOURCE_DIR" || return 1
    
    # Create a basic chezmoi configuration
    print_step "Creating basic Chezmoi configuration..."
    
    # Initialize chezmoi with empty repo if user doesn't already have a dotfiles repo
    if [ ! -d "$CHEZMOI_SOURCE_DIR" ] || [ -z "$(ls -A "$CHEZMOI_SOURCE_DIR")" ]; then
        print_step "Initializing Chezmoi with empty repository in $CHEZMOI_SOURCE_DIR..."
        chezmoi init --source="$CHEZMOI_SOURCE_DIR"
        if [ $? -ne 0 ]; then
            print_error "Failed to initialize Chezmoi"
            return 1
        fi
        
        # Create a basic .gitignore file in the chezmoi source directory
        print_step "Creating basic .gitignore file for dotfiles repo..."
        cat > "$CHEZMOI_SOURCE_DIR/.gitignore" << 'EOL'
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
        
        print_success "Created .gitignore file for dotfiles repo"
        
        # Ask if user wants to use an existing dotfiles repository
        echo -e "\n${BLUE}Do you have an existing dotfiles repo on GitHub? (y/n) [n]${NC}"
        read -r has_dotfiles
        has_dotfiles=${has_dotfiles:-n}  # Default to no
        
        if [[ "$has_dotfiles" =~ ^[Yy]$ ]]; then
            # Ask for GitHub username or full repo URL
            echo -e "${BLUE}Enter your GitHub username or the full repository URL:${NC}"
            read -r dotfiles_repo
            
            if [ -n "$dotfiles_repo" ]; then
                # Check if it's just a username or a full URL
                if [[ "$dotfiles_repo" != *"/"* && "$dotfiles_repo" != "http"* ]]; then
                    print_step "Using GitHub repository: https://github.com/$dotfiles_repo/dotfiles.git"
                    chezmoi init --source="$CHEZMOI_SOURCE_DIR" "https://github.com/$dotfiles_repo/dotfiles.git"
                else
                    print_step "Using repository: $dotfiles_repo"
                    chezmoi init --source="$CHEZMOI_SOURCE_DIR" "$dotfiles_repo"
                fi
                
                # Apply dotfiles with special flag to keep local changes by default
                chezmoi apply --keep-going
            else
                print_warning "No repository provided, using empty local repository"
            fi
        fi
    else
        print_step "Chezmoi already initialized"
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
    
    print_success "Chezmoi setup completed with custom source directory: $CHEZMOI_SOURCE_DIR"
    return 0
}

# Setup Zsh shell with Oh My Zsh
setup_zsh() {
    print_header "Setting up Zsh with Oh My Zsh"
    
    # Install zsh if not already installed
    if ! command_exists zsh; then
        print_step "Installing Zsh..."
        sudo apt install -y zsh
        if [ $? -ne 0 ]; then
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
    
    # Create a temporary file with our zshrc content
    TEMP_ZSHRC=$(mktemp)
    
    cat > "$TEMP_ZSHRC" << 'EOL'
# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

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

source $ZSH/oh-my-zsh.sh

# Environment setup
export EDITOR='nvim'
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH"
export CHEZMOI_SOURCE_DIR="$HOME/dev-env/dotfiles"

# NVM setup if it exists
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# FZF Configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Run neofetch and show quick reference at startup
if [ -f "/usr/bin/neofetch" ]; then
  /usr/bin/neofetch --backend ascii --disable disk --disk_show '/' --cpu_speed on --cpu_cores logical
  
  # Display a brief helpful summary after neofetch
  echo ""
  echo "🚀 WSL Dev Environment - Quick Reference"
  echo "───────────────────────────────────────"
  echo "📝 Edit config files: chezmoi edit --source=\"$HOME/dev-env/dotfiles\" ~/.zshrc"
  echo "🔄 Apply dotfile changes: chezmoi apply --source=\"$HOME/dev-env/dotfiles\""
  echo "📊 Check dotfile status: chezmoi status --source=\"$HOME/dev-env/dotfiles\""
  echo "💻 Editor: nvim | Multiplexer: tmux | Shell: zsh"
  echo "📋 Docs: ~/dev-env/docs/ (try: cat ~/dev-env/docs/quick-reference.md)"
  echo "🔨 Update environment: ~/dev-env/update.sh"
  echo ""
fi

# Aliases - focused on productivity
alias vim='nvim'
alias v='nvim'
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'
alias c='clear'

# Git aliases
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gl='git pull'

# Tmux aliases
alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux ls'

# Use Linux versions of tools
if [ -f /usr/bin/git ]; then
    alias git='/usr/bin/git'
fi

if [ -f /usr/bin/python3 ]; then
    alias python3='/usr/bin/python3'
fi

# Make sure we always use Linux version of neofetch
if [ -f /usr/bin/neofetch ]; then
    alias neofetch='/usr/bin/neofetch'
fi

# Set npm to use Linux mode if available
if command -v npm >/dev/null 2>&1; then
    npm config set os linux >/dev/null 2>&1
fi

# Chezmoi aliases with source directory
alias cz='chezmoi --source="$HOME/dev-env/dotfiles"'
alias cza='chezmoi add --source="$HOME/dev-env/dotfiles"'
alias cze='chezmoi edit --source="$HOME/dev-env/dotfiles"'
alias czd='chezmoi diff --source="$HOME/dev-env/dotfiles"'
alias czap='chezmoi apply --source="$HOME/dev-env/dotfiles"'
EOL
    
    if [ $? -ne 0 ]; then
        print_error "Failed to create temporary Zsh configuration file"
        rm -f "$TEMP_ZSHRC"
        return 1
    fi
    
    # Add to chezmoi
    print_step "Adding zshrc to chezmoi..."
    
    # Check if ~/.zshrc already exists and backup if needed
    backup_file "$HOME/.zshrc"
    
    # Copy our template to home directory first
    cp "$TEMP_ZSHRC" "$HOME/.zshrc"
    
    # Add to chezmoi using the safe function
    safe_add_to_chezmoi "$HOME/.zshrc" "Zsh configuration"
    local result=$?
    
    # Cleanup
    rm -f "$TEMP_ZSHRC"
    
    if [ $result -ne 0 ]; then
        print_error "Failed to add zshrc to chezmoi"
        return 1
    fi
    
    print_success "Zsh configuration created and added to chezmoi"
    return 0
}

# Setup tmux 
setup_tmux() {
    print_header "Setting up tmux configuration with Chezmoi"
    
    # Check if tmux is installed
    if ! command_exists tmux; then
        print_step "Installing tmux..."
        sudo apt install -y tmux
        if [ $? -ne 0 ]; then
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
    
    print_success "tmux configuration created and added to chezmoi"
    return 0
}

# Setup WSL utilities
setup_wsl_utilities() {
    print_header "Setting up WSL utilities with Chezmoi"
    
    # Temporary directory for WSL utility scripts
    TEMP_DIR=$(mktemp -d)
    
    # Create VS Code wrapper
    print_step "Creating VS Code wrapper script..."
    cat > "$TEMP_DIR/code-wrapper.sh" << 'EOL'
#!/bin/bash
# VS Code wrapper script for WSL

# If run with no arguments, open current directory
if [ $# -eq 0 ]; then
    cmd.exe /c "code" "$(wslpath -w "$(pwd)")" > /dev/null 2>&1
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

# Launch VS Code via cmd.exe to avoid permission issues
cmd.exe /c "code" "${args[@]}" > /dev/null 2>&1
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
    
    # Make scripts executable
    chmod +x "$TEMP_DIR/code-wrapper.sh"
    chmod +x "$TEMP_DIR/winopen"
    chmod +x "$TEMP_DIR/clip-copy"
    
    # Create bin directory if it doesn't exist
    ensure_dir ~/bin || return 1
    
    # Backup existing scripts if needed
    for script in "code-wrapper.sh" "winopen" "clip-copy"; do
        if [ -f "$HOME/bin/$script" ]; then
            print_step "Backing up existing $script..."
            mv "$HOME/bin/$script" "$HOME/bin/${script}.backup.$(date +%Y%m%d%H%M%S)"
        fi
    done
    
    # Copy scripts to bin directory
    cp "$TEMP_DIR/code-wrapper.sh" "$HOME/bin/"
    cp "$TEMP_DIR/winopen" "$HOME/bin/"
    cp "$TEMP_DIR/clip-copy" "$HOME/bin/"
    
    # Add bin directory to chezmoi using the safe function
    print_step "Adding WSL utility scripts to chezmoi..."
    local result=0
    safe_add_to_chezmoi "$HOME/bin/code-wrapper.sh" "VS Code wrapper" || result=1
    safe_add_to_chezmoi "$HOME/bin/winopen" "Windows path opener" || result=1
    safe_add_to_chezmoi "$HOME/bin/clip-copy" "Clipboard utility" || result=1
    
    # Update bashrc with code alias via chezmoi
    if ! grep -q "alias code=" ~/.bashrc; then
        print_step "Adding code alias to .bashrc..."
        echo 'alias code="$HOME/bin/code-wrapper.sh"' >> ~/.bashrc
        
        # Update bashrc in chezmoi
        if chezmoi managed --source="$CHEZMOI_SOURCE_DIR" ~/.bashrc &>/dev/null; then
            safe_add_to_chezmoi "$HOME/.bashrc" "Bash configuration with code alias" --force
        fi
    fi
    
    # Cleanup temporary directory
    rm -rf "$TEMP_DIR"
    
    if [ $result -ne 0 ]; then
        print_warning "Some WSL utilities may not have been added properly"
        return 1
    fi
    
    print_success "WSL utilities setup completed and added to chezmoi"
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
export CHEZMOI_SOURCE_DIR="$HOME/dev-env/dotfiles"

# Display helpful quick reference after neofetch
if [ -f "/usr/bin/neofetch" ]; then
  # Display a brief helpful summary
  echo ""
  echo "🚀 WSL Dev Environment - Quick Reference"
  echo "───────────────────────────────────────"
  echo "📝 Edit config files: chezmoi edit --source=\"$HOME/dev-env/dotfiles\" ~/.bashrc"
  echo "🔄 Apply dotfile changes: chezmoi apply --source=\"$HOME/dev-env/dotfiles\""
  echo "📊 Check dotfile status: chezmoi status --source=\"$HOME/dev-env/dotfiles\""
  echo "💻 Editor: nvim | Multiplexer: tmux"
  echo "📋 Docs: ~/dev-env/docs/ (try: cat ~/dev-env/docs/quick-reference.md)"
  echo "🔨 Update environment: ~/dev-env/update.sh"
  echo ""
fi

# Chezmoi aliases with source directory
alias cz='chezmoi --source="$HOME/dev-env/dotfiles"'
alias cza='chezmoi add --source="$HOME/dev-env/dotfiles"'
alias cze='chezmoi edit --source="$HOME/dev-env/dotfiles"'
alias czd='chezmoi diff --source="$HOME/dev-env/dotfiles"'
alias czap='chezmoi apply --source="$HOME/dev-env/dotfiles"'
EOL
    
    # Check if neofetch alias exists, add if not
    if ! grep -q "alias neofetch='/usr/bin/neofetch'" "$HOME/.bashrc"; then
        print_step "Adding neofetch alias to .bashrc..."
        echo "alias neofetch='/usr/bin/neofetch'" >> "$HOME/.bashrc"
    fi
    
    # Check if quick reference already exists, add if not
    if ! grep -q "WSL Dev Environment - Quick Reference" "$HOME/.bashrc"; then
        print_step "Adding quick reference to .bashrc..."
        cat "$QUICK_REF" >> "$HOME/.bashrc"
    else
        print_step "Quick reference already exists in .bashrc"
    fi
    
    # Important: Add .bashrc to chezmoi AFTER all modifications
    print_step "Adding .bashrc to chezmoi..."
    if chezmoi managed --source="$CHEZMOI_SOURCE_DIR" ~/.bashrc &>/dev/null; then
        # Already managed by chezmoi, update it
        print_step "Updating .bashrc in chezmoi..."
        safe_add_to_chezmoi "$HOME/.bashrc" "Bash configuration" --force
    else
        # First time adding to chezmoi
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
        sudo apt install -y git
        if [ $? -ne 0 ]; then
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
    
    # Check if we already have a dotfiles repository
    if [ -d "$CHEZMOI_SOURCE_DIR/.git" ]; then
        print_step "Dotfiles repository already initialized"
        
        # Change to the source directory
        cd "$CHEZMOI_SOURCE_DIR" || return 1
        
        # Make sure we're on the main branch
        git checkout main 2>/dev/null || git checkout -b main
        
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
        git commit -m "batman"
        
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
        sudo apt install -y git
        if [ $? -ne 0 ]; then
            print_error "Failed to install Git"
            return 1
        fi
    fi
    
    # Prompt for Git configuration
    print_step "Setting up Git user configuration..."
    
    # Check if user already has Git config
    if [ -f "$HOME/.gitconfig" ]; then
        print_step "Existing Git configuration found. Adding to chezmoi..."
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
        print_step "Adding Git configuration to chezmoi..."
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
        sudo apt install -y build-essential libssl-dev
        
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
        print_step "Adding NVM configuration to .bashrc..."
        cat >> "$HOME/.bashrc" << 'EOL'

# NVM configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
EOL
    fi
    
    # Update .bashrc in chezmoi if it's already being managed
    if chezmoi managed --source="$CHEZMOI_SOURCE_DIR" ~/.bashrc &>/dev/null; then
        print_step "Updating .bashrc in chezmoi to include NVM configuration..."
        safe_add_to_chezmoi "$HOME/.bashrc" "Bash configuration with NVM" --force
        if [ $? -ne 0 ]; then
            print_warning "Failed to update .bashrc in chezmoi"
        else
            print_success "Updated .bashrc in chezmoi with NVM configuration"
        fi
    fi
    
    print_success "Node.js environment configured successfully"
    return 0
}

# Setup Claude Code from Anthropic with chezmoi integration
setup_claude_code() {
    print_header "Installing Claude Code with Chezmoi integration"
    
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
    
    # Apply WSL-specific workarounds as mentioned in the Claude Code docs
    print_step "Setting npm config for WSL compatibility..."
    npm config set os linux
    
    # Install Claude Code
    print_step "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code --no-os-check
    if [ $? -ne 0 ]; then
        print_error "Failed to install Claude Code"
        print_warning "This may be due to internet connectivity or npm configuration issues"
        return 1
    fi
    
    # Check for Claude Code config directory
    CLAUDE_CONFIG_DIR="$HOME/.config/claude-code"
    # Create config directory if it doesn't exist
    if [ ! -d "$CLAUDE_CONFIG_DIR" ]; then
        mkdir -p "$CLAUDE_CONFIG_DIR"
    fi
    
    print_success "Claude Code installed successfully"
    return 0
}

# Setup GitHub authentication and information
setup_github_info() {
    print_header "Setting up GitHub Integration"
    
    # Check if GitHub CLI is installed, install if not
    if ! command_exists gh; then
        print_step "Installing GitHub CLI..."
        
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        sudo apt update
        sudo apt install -y gh
        
        if [ $? -ne 0 ]; then
            print_error "Failed to install GitHub CLI"
            print_warning "GitHub integration features will be disabled"
            USE_GITHUB=false
            return 0
        fi
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
    cat > "$SETUP_DIR/docs/chezmoi/getting-started.md" << 'EOL'
# Getting Started with Chezmoi

Chezmoi is a dotfile manager that helps you manage your configuration files across multiple machines.

## Basic Commands

Our setup uses a custom source directory at `~/dev-env/dotfiles`. Always use the `--source` flag as shown below:

```bash
# Add a file to be managed by chezmoi
chezmoi add --source="$HOME/dev-env/dotfiles" ~/.zshrc

# Edit a file
chezmoi edit --source="$HOME/dev-env/dotfiles" ~/.zshrc

# Apply changes
chezmoi apply --source="$HOME/dev-env/dotfiles"

# See what changes would be made
chezmoi diff --source="$HOME/dev-env/dotfiles"
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
```

## Working with Templates

Chezmoi supports templates for managing differences between machines:

```
{{- if eq .chezmoi.os "linux" }}
# Linux-specific configuration
{{- else if eq .chezmoi.os "windows" }}
# Windows-specific configuration
{{- end }}
```

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
    
    # Create a quick reference file
    cat > "$SETUP_DIR/docs/quick-reference.md" << 'EOL'
# Quick Reference Guide

## Core Tools

| Tool | Purpose | Basic Commands |
|------|---------|----------------|
| Neovim | Text editor | `nvim <filename>` |
| Tmux | Terminal multiplexer | `tmux new -s <session>`, `tmux attach -t <session>` |
| Zsh | Enhanced shell | Enabled by default |
| Chezmoi | Dotfile manager | `cza <file>`, `czap` |
| Node.js | JavaScript runtime | Managed with NVM: `nvm install <version>` |
| Claude Code | AI coding assistant | `claude` |

## Useful Aliases

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
cz         # Chezmoi command with source directory
cza        # Add file to chezmoi
cze        # Edit file in chezmoi
czap       # Apply changes
czd        # Show differences
```

## WSL-Specific Utilities

- `winopen`: Open current directory in Windows Explorer
- `clip-copy`: Copy text to Windows clipboard
- `code-wrapper.sh`: VS Code launcher for WSL paths

## Directory Structure

- `~/dev-env`: Main environment directory
  - `/dotfiles`: Chezmoi source directory
  - `/docs`: Documentation
  - `/bin`: Custom scripts
  - `/projects`: Project storage (recommended)

## Updates

Run `~/dev-env/update.sh` to update your environment.
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

echo -e "${CYAN}==== WSL Development Environment Update ====${NC}"
echo -e "${BLUE}→ Updating system packages...${NC}"

# Update system packages
sudo apt update
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to update package lists${NC}"
    exit 1
fi

sudo apt upgrade -y
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Failed to upgrade packages${NC}"
    exit 1
fi

echo -e "${GREEN}✓ System packages updated${NC}"

# Update Oh My Zsh if installed
if [ -d "$HOME/.oh-my-zsh" ]; then
    echo -e "${BLUE}→ Updating Oh My Zsh...${NC}"
    cd "$HOME" || exit 1
    
    # Run the upgrade directly using bash to avoid 'local' command not in function error
    if [ -f "$HOME/.oh-my-zsh/tools/upgrade.sh" ]; then
        bash "$HOME/.oh-my-zsh/tools/upgrade.sh"
    fi
    
    echo -e "${GREEN}✓ Oh My Zsh updated${NC}"
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
    
    echo -e "${GREEN}✓ NVM and Node.js updated${NC}"
fi

# Update Claude Code if installed
if command -v claude > /dev/null; then
    echo -e "${BLUE}→ Updating Claude Code...${NC}"
    npm update -g @anthropic-ai/claude-code
    echo -e "${GREEN}✓ Claude Code updated${NC}"
fi

# Update Chezmoi dotfiles if configured
if command -v chezmoi > /dev/null; then
    CHEZMOI_SOURCE_DIR="$HOME/dev-env/dotfiles"
    
    if [ -d "$CHEZMOI_SOURCE_DIR" ]; then
        echo -e "${BLUE}→ Updating Chezmoi and dotfiles...${NC}"
        
        # Update Chezmoi itself
        chezmoi upgrade
        
        # Check for remote updates if git configured
        if [ -d "$CHEZMOI_SOURCE_DIR/.git" ]; then
            echo -e "${BLUE}→ Checking for remote dotfile updates...${NC}"
            
            # Check if remote is properly set up
            cd "$CHEZMOI_SOURCE_DIR" || exit 1
            if git remote -v | grep -q origin; then
                # Check if we have a tracking branch set up
                if git symbolic-ref -q HEAD &>/dev/null; then
                    BRANCH=$(git symbolic-ref --short HEAD)
                    if git config --get "branch.$BRANCH.remote" &>/dev/null; then
                        # Pull updates
                        git pull --quiet
                        echo -e "${GREEN}✓ Dotfiles updated from remote${NC}"
                    else
                        echo -e "${YELLOW}! No tracking branch configured. To set it up:${NC}"
                        echo -e "${YELLOW}! cd $CHEZMOI_SOURCE_DIR && git branch --set-upstream-to=origin/$BRANCH $BRANCH${NC}"
                    fi
                fi
            else
                echo -e "${YELLOW}! No remote repository configured for dotfiles${NC}"
            fi
            
            # Apply any updates
            chezmoi apply --source="$CHEZMOI_SOURCE_DIR"
        fi
        
        echo -e "${GREEN}✓ Chezmoi and dotfiles updated${NC}"
    fi
fi

echo -e "${CYAN}==== Update Complete ====${NC}"
echo -e "${GREEN}The WSL development environment has been updated successfully!${NC}"
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
        echo -e "chezmoi init --source=~/dev-env/dotfiles https://github.com/$GITHUB_USERNAME/dotfiles.git"
    elif $USE_GITHUB; then
        echo -e "${YELLOW}GitHub repository setup was not completed.${NC}"
        echo -e "${BLUE}To create it later, run:${NC}"
        echo -e "cd ~/dev-env/dotfiles && gh repo create dotfiles --private && git push -u origin main"
    fi
    
    # Show tools installed
    echo -e "\n${CYAN}Installed Tools:${NC}"
    echo -e "• Neovim (editor): ${GREEN}nvim${NC}"
    echo -e "• Tmux (terminal multiplexer): ${GREEN}tmux${NC}"
    echo -e "• Zsh (shell): ${GREEN}zsh${NC}"
    echo -e "• Chezmoi (dotfile manager): ${GREEN}chezmoi${NC}"
    echo -e "• Node.js (JavaScript runtime): ${GREEN}node${NC}"
    echo -e "• Claude Code (AI assistant): ${GREEN}claude${NC}"
    
    # Show quick reference and documentation location
    echo -e "\n${CYAN}Documentation:${NC}"
    echo -e "Quick reference guide: ${GREEN}cat $QUICK_REF_PATH${NC}"
    echo -e "All documentation: ${GREEN}ls ~/dev-env/docs/${NC}"
    
    # Show update script location
    echo -e "\n${CYAN}Updates:${NC}"
    echo -e "To update your environment: ${GREEN}~/dev-env/update.sh${NC}"
    
    echo -e "\n${YELLOW}Enjoy your new development environment!${NC}"
    return 0
}

# --- Main Script Execution ---
echo -e "${PURPLE}===============================================${NC}"
echo -e "${PURPLE}| WSL Development Environment Setup v${SCRIPT_VERSION} |${NC}"
echo -e "${PURPLE}===============================================${NC}"
echo -e "${GREEN}This script will set up a development environment optimized for WSL Debian${NC}"

# Set up GitHub information first
setup_github_info || exit 1

# Step 1: Initial setup
setup_workspace || exit 1
update_system || exit 1
install_core_deps || exit 1

# Step 2: Set up chezmoi early for dotfile management
setup_chezmoi || exit 1

# Step 3: Install basic tools
install_neofetch || exit 1
install_neovim || exit 1
setup_git_config || exit 1
setup_zsh || exit 1

# Step 4: Install Node.js before configuring bashrc
setup_nodejs || exit 1

# Step 5: Configure dotfiles with chezmoi
setup_zshrc || exit 1
setup_nvim_config || exit 1
setup_tmux || exit 1
setup_wsl_utilities || exit 1
setup_bashrc_helper || exit 1

# Step 6: Dev tools and documentation
setup_claude_code || exit 1
create_claude_code_docs || exit 1
create_chezmoi_docs || exit 1
create_component_docs || exit 1
create_update_script || exit 1
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
