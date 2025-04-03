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
GITHUB_USERNAME=""
GITHUB_TOKEN=""
USE_GITHUB=false

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

# Create the necessary directory structure
setup_workspace() {
    print_header "Creating Workspace Structure"
    print_step "Setting up directory structure..."

    # Main directory structure
    ensure_dir ~/dev-env || return 1
    ensure_dir ~/.local/bin || return 1
    ensure_dir ~/bin || return 1
    ensure_dir ~/dev || return 1

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

# Setup Neovim with Kickstart configuration
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
    
    chezmoi add "$HOME/.config/nvim"
    
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
    
    # Create a basic chezmoi configuration
    print_step "Creating basic Chezmoi configuration..."
    
    # Initialize chezmoi with empty repo if user doesn't already have a dotfiles repo
    if [ ! -d "$HOME/.local/share/chezmoi" ]; then
        print_step "Initializing Chezmoi with empty repository..."
        chezmoi init
        if [ $? -ne 0 ]; then
            print_error "Failed to initialize Chezmoi"
            return 1
        fi
        
        # Ask if user wants to use an existing dotfiles repository
        echo -e "\n${BLUE}Do you have an existing dotfiles repo on GitHub? (y/n)${NC}"
        read -r has_dotfiles
        
        if [[ "$has_dotfiles" =~ ^[Yy]$ ]]; then
            # Ask for GitHub username or full repo URL
            echo -e "${BLUE}Enter your GitHub username or the full repository URL:${NC}"
            read -r dotfiles_repo
            
            if [ -n "$dotfiles_repo" ]; then
                # Check if it's just a username or a full URL
                if [[ "$dotfiles_repo" != *"/"* && "$dotfiles_repo" != "http"* ]]; then
                    print_step "Using GitHub repository: https://github.com/$dotfiles_repo/dotfiles.git"
                    chezmoi init "https://github.com/$dotfiles_repo/dotfiles.git"
                else
                    print_step "Using repository: $dotfiles_repo"
                    chezmoi init "$dotfiles_repo"
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
    if [ ! -f "$HOME/.local/share/chezmoi/README.md" ]; then
        cat > "$HOME/.local/share/chezmoi/README.md" << 'EOL'
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
    
    print_success "Chezmoi setup completed"
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
  echo "📝 Edit config files: chezmoi edit ~/.zshrc"
  echo "🔄 Apply dotfile changes: chezmoi apply"
  echo "📊 Check dotfile status: chezmoi status"
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
EOL
    
    if [ $? -ne 0 ]; then
        print_error "Failed to create temporary Zsh configuration file"
        rm -f "$TEMP_ZSHRC"
        return 1
    fi
    
    # Add to chezmoi
    print_step "Adding zshrc to chezmoi..."
    
    # Check if ~/.zshrc already exists and backup if needed
    if [ -f "$HOME/.zshrc" ]; then
        print_step "Backing up existing .zshrc file..."
        mv "$HOME/.zshrc" "$HOME/.zshrc.backup.$(date +%Y%m%d%H%M%S)"
    fi
    
    # Copy our template to home directory first
    cp "$TEMP_ZSHRC" "$HOME/.zshrc"
    
    # Add to chezmoi
    chezmoi add "$HOME/.zshrc"
    
    # Cleanup
    rm -f "$TEMP_ZSHRC"
    
    if [ $? -ne 0 ]; then
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
    if [ -f "$HOME/.tmux.conf" ]; then
        print_step "Backing up existing .tmux.conf file..."
        mv "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup.$(date +%Y%m%d%H%M%S)"
    fi
    
    # Copy our template to home directory
    cp "$TEMP_TMUX" "$HOME/.tmux.conf"
    
    # Add to chezmoi
    print_step "Adding tmux.conf to chezmoi..."
    chezmoi add "$HOME/.tmux.conf"
    
    # Cleanup
    rm -f "$TEMP_TMUX"
    
    if [ $? -ne 0 ]; then
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
    
    # Add bin directory to chezmoi
    print_step "Adding WSL utility scripts to chezmoi..."
    chezmoi add "$HOME/bin/code-wrapper.sh" "$HOME/bin/winopen" "$HOME/bin/clip-copy"
    
    # Update bashrc with code alias via chezmoi
    if ! grep -q "alias code=" ~/.bashrc; then
        print_step "Adding code alias to .bashrc..."
        echo 'alias code="$HOME/bin/code-wrapper.sh"' >> ~/.bashrc
        
        # Update bashrc in chezmoi
        if chezmoi managed ~/.bashrc &>/dev/null; then
            chezmoi add ~/.bashrc
        fi
    fi
    
    # Cleanup temporary directory
    rm -rf "$TEMP_DIR"
    
    print_success "WSL utilities setup completed and added to chezmoi"
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
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
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
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
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
    if chezmoi managed ~/.bashrc &>/dev/null; then
        print_step "Updating .bashrc in chezmoi to include NVM configuration..."
        chezmoi add ~/.bashrc --force
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
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
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
    if [ -d "$CLAUDE_CONFIG_DIR" ]; then
        print_step "Adding Claude Code configuration to chezmoi..."
        chezmoi add "$CLAUDE_CONFIG_DIR"
        print_success "Claude Code configuration added to chezmoi"
    else
        print_step "No Claude Code configuration directory found yet."
        print_step "It will be created when you first run 'claude auth login'"
        print_step "After that, add it to chezmoi with: chezmoi add ~/.config/claude-code"
    fi
    
    # Verify installation
    if command_exists claude; then
        print_success "Claude Code installed successfully!"
    else
        print_warning "Claude Code installation might have issues."
        print_warning "Try manually running: npm install -g @anthropic-ai/claude-code --force --no-os-check"
        return 1
    fi
    
    print_success "Claude Code setup completed with chezmoi integration"
    return 0
}

# Create Claude Code documentation
create_claude_code_docs() {
    print_header "Creating Claude Code documentation"
    
    ensure_dir "$SETUP_DIR/docs" || return 1
    
    cat > "$SETUP_DIR/docs/claude-code-guide.md" << 'EOL'
# Claude Code Guide

Claude Code is an AI-assisted coding tool from Anthropic that helps you write, understand, and improve your code.

## Getting Started

### Starting Claude Code

Navigate to your project directory and run:
```bash
claude
```

The first time you run it, you'll need to authenticate:
```bash
claude auth login
```

### Basic Usage

1. **Ask Claude Code to explain code**:
   - Select a piece of code in your project
   - Ask: "What does this code do?"

2. **Generate code**:
   - Describe what you want: "Write a function that sorts a list of dictionaries by their 'date' field"

3. **Fix bugs**:
   - Show Claude some code with an error
   - Ask: "Why doesn't this work?" or "Fix this bug"

## Common Commands

- `claude` - Start Claude Code in your project
- `claude auth login` - Authenticate with Anthropic
- `claude auth logout` - Log out
- `claude --help` - Show help information

## WSL-Specific Issues

If you encounter problems running Claude Code in WSL:

1. Check which Node.js you're using:
   ```bash
   which node
   which npm
   ```
   
   These should point to Linux paths (starting with /home/), not Windows paths (starting with /mnt/c/).

2. Set npm to use Linux:
   ```bash
   npm config set os linux
   ```

3. Reinstall with force flag:
   ```bash
   npm install -g @anthropic-ai/claude-code --force --no-os-check
   ```

For more information, visit the [official Claude Code documentation](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview)
EOL
    
    if [ $? -ne 0 ]; then
        print_error "Failed to create Claude Code documentation"
        return 1
    fi
    
    print_success "Claude Code documentation created"
    return 0
}

# Create documentation for Chezmoi
create_chezmoi_docs() {
    print_header "Creating Chezmoi documentation"
    
    ensure_dir "$SETUP_DIR/docs" || return 1
    
    cat > "$SETUP_DIR/docs/chezmoi-guide.md" << 'EOL'
# Chezmoi Guide for Dotfile Management

Chezmoi is a powerful dotfile manager that helps you keep your configuration files (dotfiles) in sync across multiple machines.

## Getting Started

### Basic Commands

* `chezmoi add <file>` - Add a file to chezmoi
* `chezmoi edit <file>` - Edit a file managed by chezmoi
* `chezmoi apply` - Apply changes to your home directory
* `chezmoi update` - Pull the latest changes from your dotfiles repo and apply them
* `chezmoi diff` - See what changes chezmoi would make to your home directory

### Managing Your Configuration Between Windows and WSL

Chezmoi is perfect for maintaining consistency between your Windows environment and WSL:

1. **Initial Setup**:
   ```bash
   # Initialize chezmoi with your existing dotfiles repository
   chezmoi init https://github.com/yourusername/dotfiles.git
   
   # Or initialize with a new empty repository
   chezmoi init
   ```

2. **Adding Files**:
   ```bash
   # Add your .zshrc
   chezmoi add ~/.zshrc
   
   # Add your .gitconfig
   chezmoi add ~/.gitconfig
   ```

3. **Apply Changes**:
   ```bash
   # Apply all changes
   chezmoi apply
   ```

## Templates and Machine-Specific Configuration

Chezmoi uses templates to handle differences between machines:

### Template Example

```
{{- if eq .chezmoi.os "linux" }}
# Linux-specific configuration
{{- else if eq .chezmoi.os "windows" }}
# Windows-specific configuration
{{- end }}
```

### Data Files

You can store machine-specific data in `.chezmoi.toml`:

```toml
[data]
    email = "your.email@example.com"
    name = "Your Name"
```

Then reference it in templates:

```
[user]
    email = "{{ .email }}"
    name = "{{ .name }}"
```

## Syncing with Git

Chezmoi works seamlessly with Git for version control:

```bash
# Make changes to your dotfiles
chezmoi add ~/.zshrc

# Commit the changes to your local repo
chezmoi git add .
chezmoi git commit -m "Update zshrc"

# Push to your remote repo
chezmoi git push
```

## Windows and WSL Integration

One of the most powerful features of Chezmoi is the ability to manage dotfiles across both Windows and WSL using the same repository.

### Setting Up Chezmoi on Windows

1. **Install Chezmoi on Windows**:
   ```powershell
   # Using winget
   winget install twpayne.chezmoi
   
   # OR using Scoop
   scoop install chezmoi
   
   # OR using Chocolatey
   choco install chezmoi
   ```

2. **Initialize with the Same Repository**:
   ```powershell
   # Initialize Chezmoi with your GitHub repository
   chezmoi init https://github.com/YOUR-USERNAME/dotfiles.git
   ```

3. **Apply Your Dotfiles**:
   ```powershell
   # Check what would change
   chezmoi diff
   
   # Apply the changes
   chezmoi apply
   ```

### Managing Windows-Specific Files

Windows has different paths and configuration files compared to Linux/WSL:

```powershell
# Add PowerShell profile
chezmoi add $PROFILE

# Add Windows Terminal settings
chezmoi add ~/AppData/Local/Packages/Microsoft.WindowsTerminal_*/LocalState/settings.json

# Add other common Windows configs
chezmoi add ~/.gitconfig
chezmoi add ~/.wslconfig
```

### Template Examples for Cross-Platform Compatibility

1. **Conditional Paths**:
   ```
   {{- if eq .chezmoi.os "windows" }}
   C:\Path\to\something
   {{- else }}
   /path/to/something
   {{- end }}
   ```

2. **Different Application Settings**:
   ```
   {{- if eq .chezmoi.os "windows" }}
   # Windows VSCode settings
   {{- else }}
   # Linux VSCode settings
   {{- end }}
   ```

3. **Detecting WSL Specifically**:
   ```
   {{- if and (eq .chezmoi.os "linux") (.chezmoi.kernel.osrelease | lower | contains "microsoft") }}
   # WSL-specific configuration
   {{- end }}
   ```

### Workflow for Managing Both Environments

1. **Make Changes in Either Environment**:
   - Edit files in Windows or WSL as needed
   - Add them to Chezmoi: `chezmoi add <file>`
   - Commit and push: `chezmoi git commit -m "Update config" && chezmoi git push`

2. **Synchronize in the Other Environment**:
   - Pull changes: `chezmoi update`
   - This will pull from git and apply changes in one step

3. **Use a Shared Data File**:
   Create a `.chezmoi.toml` with common settings:
   ```toml
   [data]
   email = "your.email@example.com"
   name = "Your Name"
   editor = "nvim"  # Will be translated appropriately for each OS
   ```

## Common Workflows

### Setting Up a New Machine

```bash
# Install chezmoi
sh -c "$(curl -fsLS get.chezmoi.io)"

# Initialize with your dotfiles repo
chezmoi init https://github.com/yourusername/dotfiles.git

# See what changes would be made
chezmoi diff

# Apply the changes
chezmoi apply
```

### Day-to-Day Usage

1. Make changes to your dotfiles directly with your editor
2. Run `chezmoi add ~/.filename` to update chezmoi's source state
3. Run `chezmoi git commit -m "Description of changes"` to commit the changes
4. Run `chezmoi git push` to push the changes to your remote repository

### Pulling Changes from Another Machine

```bash
chezmoi update
```

## Best Practices

1. **Start Simple**: Begin by adding just a few important dotfiles
2. **Use Templates Sparingly**: Only use templates when necessary
3. **Commit Often**: Make small, regular commits to your dotfiles repository
4. **Document Your Setup**: Keep notes about your configuration choices

## For More Information

Visit the [Chezmoi documentation](https://www.chezmoi.io/) for comprehensive guides and examples.
EOL
    
    if [ $? -ne 0 ]; then
        print_error "Failed to create Chezmoi documentation"
        return 1
    fi
    
    print_success "Chezmoi documentation created"
    return 0
}

# Create update script
create_update_script() {
    print_header "Creating update script"
    print_step "Creating update maintenance script..."
    
    cat > "$SETUP_DIR/update.sh" << 'ENDOFFILE'
#!/bin/bash
# Update script for WSL development environment

# Color definitions
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'

echo -e "${BLUE}Updating System Packages...${NC}"
sudo apt update && sudo apt upgrade -y

echo -e "${BLUE}Updating Node.js packages...${NC}"
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install --lts --reinstall-packages-from=default

# Check for Claude Code updates
if command -v claude >/dev/null 2>&1; then
  echo -e "${BLUE}Updating Claude Code...${NC}"
  npm config set os linux
  npm update -g @anthropic-ai/claude-code --no-os-check
  echo -e "${GREEN}Claude Code updated${NC}"
fi

# Update dotfiles with chezmoi if it's installed
if command -v chezmoi >/dev/null 2>&1; then
  echo -e "${BLUE}Updating dotfiles with Chezmoi...${NC}"
  chezmoi update
  echo -e "${GREEN}Dotfiles updated${NC}"
fi

echo -e "${GREEN}Environment updated successfully!${NC}"
ENDOFFILE
    
    if [ $? -ne 0 ]; then
        print_error "Failed to create update script"
        return 1
    fi
    
    chmod +x "$SETUP_DIR/update.sh"
    if [ $? -ne 0 ]; then
        print_error "Failed to make update script executable"
        return 1
    fi
    
    print_success "Update script created successfully"
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
    
    # Check if we already have a dotfiles repository
    if [ -d "$HOME/.local/share/chezmoi/.git" ]; then
        print_step "Dotfiles repository already initialized"
        
        # If GitHub CLI is available, offer to connect to GitHub
        if $USE_GITHUB && command_exists gh; then
            echo -e "\n${BLUE}Do you want to connect your dotfiles to a GitHub repository? (y/n)${NC}"
            read -r setup_remote
            
            if [[ "$setup_remote" =~ ^[Yy]$ ]]; then
                cd "$HOME/.local/share/chezmoi" || return 1
                
                # Ask if repository should be public
                echo -e "\n${BLUE}Should the repository be public? (y/n, default: n)${NC}"
                read -r repo_public
                is_public="false"
                if [[ "$repo_public" =~ ^[Yy]$ ]]; then
                    is_public="true"
                fi
                
                # Create and connect to GitHub repository
                create_github_repository "dotfiles" "My dotfiles managed by Chezmoi" "$is_public"
                
                # Try pushing to GitHub
                print_step "Pushing dotfiles to GitHub..."
                git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null
                if [ $? -ne 0 ]; then
                    print_warning "Failed to push to GitHub. You can try again later with:"
                    print_warning "cd ~/.local/share/chezmoi && git push -u origin main"
                else
                    print_success "Dotfiles pushed to GitHub successfully"
                fi
            fi
        else
            # Original behavior for non-GitHub CLI workflow
            echo -e "\n${BLUE}Do you want to connect your dotfiles to a GitHub repository? (y/n)${NC}"
            read -r setup_remote
            
            if [[ "$setup_remote" =~ ^[Yy]$ ]]; then
                echo -e "${BLUE}Enter your GitHub username (or full repository URL):${NC}"
                read -r repo_url
                
                if [ -n "$repo_url" ]; then
                    # Check if it's just a username or a full URL
                    if [[ "$repo_url" != *"/"* && "$repo_url" != "http"* ]]; then
                        repo_url="https://github.com/$repo_url/dotfiles.git"
                    fi
                    
                    print_step "Setting up remote origin to $repo_url"
                    cd "$HOME/.local/share/chezmoi" || return 1
                    
                    # Check if remote already exists
                    if git remote | grep -q "origin"; then
                        print_step "Remote 'origin' already exists, updating URL..."
                        git remote set-url origin "$repo_url"
                    else
                        git remote add origin "$repo_url"
                    fi
                    
                    print_step "Pushing dotfiles to remote repository..."
                    print_warning "This will fail if the repository doesn't exist. Create it on GitHub first if needed."
                    
                    git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null
                    if [ $? -ne 0 ]; then
                        print_warning "Failed to push to remote. The repository may not exist or you don't have permissions."
                        print_step "To push later, run: cd ~/.local/share/chezmoi && git push -u origin main"
                    else
                        print_success "Dotfiles pushed to remote repository"
                    fi
                fi
            fi
        fi
    else
        print_step "Initializing dotfiles repository"
        
        # Initialize git in chezmoi source directory
        cd "$HOME/.local/share/chezmoi" || return 1
        git init
        
        # Create initial commit with all files
        git add .
        git commit -m "Initial dotfiles commit"
        
        # If GitHub CLI is available, offer to create and push to GitHub
        if $USE_GITHUB && command_exists gh; then
            echo -e "\n${BLUE}Do you want to push your dotfiles to a GitHub repository? (y/n)${NC}"
            read -r push_to_github
            
            if [[ "$push_to_github" =~ ^[Yy]$ ]]; then
                # Ask if repository should be public
                echo -e "\n${BLUE}Should the repository be public? (y/n, default: n)${NC}"
                read -r repo_public
                is_public="false"
                if [[ "$repo_public" =~ ^[Yy]$ ]]; then
                    is_public="true"
                fi
                
                # Create and connect to GitHub repository
                create_github_repository "dotfiles" "My dotfiles managed by Chezmoi" "$is_public"
                
                # Try pushing to GitHub
                print_step "Pushing to GitHub..."
                git push -u origin main 2>/dev/null || git push -u origin master 2>/dev/null
                if [ $? -ne 0 ]; then
                    print_warning "Failed to push to GitHub. You can try again later with:"
                    print_warning "cd ~/.local/share/chezmoi && git push -u origin main"
                else 
                    print_success "Successfully pushed dotfiles to GitHub"
                fi
            fi
        else
            # Original behavior for non-GitHub CLI workflow
            echo -e "\n${BLUE}Do you want to push your dotfiles to a GitHub repository? (y/n)${NC}"
            read -r push_to_github
            
            if [[ "$push_to_github" =~ ^[Yy]$ ]]; then
                echo -e "${BLUE}Enter your GitHub username:${NC}"
                read -r github_username
                
                if [ -n "$github_username" ]; then
                    repo_url="https://github.com/$github_username/dotfiles.git"
                    
                    print_step "Setting up remote origin to $repo_url"
                    git remote add origin "$repo_url"
                    
                    print_step "To push your dotfiles to GitHub:"
                    print_warning "1. Create a repository named 'dotfiles' on GitHub"
                    print_warning "2. Run: cd ~/.local/share/chezmoi && git push -u origin main"
                fi
            fi
        fi
    fi
    
    print_success "Dotfiles repository setup completed"
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

# Display helpful quick reference after neofetch
if [ -f "/usr/bin/neofetch" ]; then
  # Display a brief helpful summary
  echo ""
  echo "🚀 WSL Dev Environment - Quick Reference"
  echo "───────────────────────────────────────"
  echo "📝 Edit config files: chezmoi edit ~/.bashrc"
  echo "🔄 Apply dotfile changes: chezmoi apply"
  echo "📊 Check dotfile status: chezmoi status"
  echo "💻 Editor: nvim | Multiplexer: tmux"
  echo "📋 Docs: ~/dev-env/docs/ (try: cat ~/dev-env/docs/quick-reference.md)"
  echo "🔨 Update environment: ~/dev-env/update.sh"
  echo ""
fi
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
    if chezmoi managed ~/.bashrc &>/dev/null; then
        # Already managed by chezmoi, update it
        print_step "Updating .bashrc in chezmoi..."
        chezmoi add ~/.bashrc --force
    else
        # First time adding to chezmoi
        chezmoi add ~/.bashrc
    fi
    
    if [ $? -ne 0 ]; then
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
            chezmoi add ~/.bashrc --force
            print_success "NVM configuration restored and added to chezmoi"
        else
            print_warning "No NVM configuration found in .bashrc"
        fi
    fi
    
    # Cleanup
    rm -f "$QUICK_REF"
    
    print_success ".bashrc setup completed and managed by chezmoi"
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
        chezmoi add "$HOME/.gitconfig"
        print_success "Added existing Git configuration to chezmoi"
        return 0
    fi
    
    # Prompt for user information
    echo -e "\n${BLUE}Do you want to configure Git with your user information? (y/n)${NC}"
    read -r setup_git
    
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
        chezmoi add "$HOME/.gitconfig"
        
        # Cleanup
        rm -f "$TEMP_GITCONFIG"
        
        print_success "Git configuration created and added to chezmoi"
    else
        print_step "Skipping Git configuration setup"
    fi
    
    return 0
}

# Display completion message
display_completion_message() {
    echo -e "\n${PURPLE}=======================${NC}"
    echo -e "${PURPLE}|    Setup Complete!   |${NC}"
    echo -e "${PURPLE}=======================${NC}"
    echo -e "${GREEN}Your WSL developer environment is ready to use!${NC}"
    
    echo -e "\n${BLUE}Features installed:${NC}"
    echo -e "- Neovim with Kickstart configuration"
    echo -e "- Zsh with Oh My Zsh"
    echo -e "- Tmux terminal multiplexer"
    echo -e "- Chezmoi for dotfile management"
    echo -e "- Node.js via NVM"
    echo -e "- Claude Code AI assistant"
    
    echo -e "\n${BLUE}To update your environment in the future:${NC}"
    echo -e "- Run ${YELLOW}~/dev-env/update.sh${NC}"
    echo -e "- For dotfiles: ${YELLOW}chezmoi update${NC}"
    
    echo -e "\n${BLUE}Neovim Kickstart Tips:${NC}"
    echo -e "- If you didn't use your own fork, consider forking kickstart.nvim on GitHub:"
    echo -e "  ${YELLOW}https://github.com/nvim-lua/kickstart.nvim/fork${NC}"
    echo -e "- Customize your Neovim setup in ${YELLOW}~/.config/nvim/lua/custom/${NC}"
    
    echo -e "\n${BLUE}Chezmoi Tips:${NC}"
    echo -e "- Add configuration files: ${YELLOW}chezmoi add ~/.zshrc ~/.gitconfig${NC}"
    echo -e "- Edit existing dotfiles: ${YELLOW}chezmoi edit ~/.zshrc${NC}"
    echo -e "- See pending changes: ${YELLOW}chezmoi diff${NC}"
    echo -e "- Apply changes: ${YELLOW}chezmoi apply${NC}"
    echo -e "- Check documentation: ${YELLOW}cat ~/dev-env/docs/chezmoi-guide.md${NC}"
    echo -e "\n${BLUE}Syncing Between Windows and WSL:${NC}"
    echo -e "- Create a GitHub repo for your dotfiles"
    echo -e "- Run: ${YELLOW}chezmoi git remote add origin https://github.com/yourusername/dotfiles.git${NC}"
    echo -e "- Push changes: ${YELLOW}chezmoi git push -u origin main${NC}"
    echo -e "- On another machine: ${YELLOW}chezmoi init https://github.com/yourusername/dotfiles.git${NC}"
    
    echo -e "\n${PURPLE}Happy coding!${NC}"
}

# --- GitHub setup function ---
setup_github_info() {
    print_header "GitHub Setup"
    
    echo -e "\n${BLUE}Do you want to use GitHub for your dotfiles and configurations? (y/n)${NC}"
    read -r use_github_response
    
    if [[ "$use_github_response" =~ ^[Yy]$ ]]; then
        USE_GITHUB=true
        
        # Install wslu for browser integration
        print_step "Installing WSL utilities (wslu) for browser integration..."
        
        # Check if wslu is already installed
        if ! command_exists wslview; then
            print_step "Installing required packages for repository setup..."
            
            # Install required packages first
            sudo apt install -y lsb-release gnupg curl
            
            print_step "Adding Microsoft repository for WSL utilities..."
            
            # Import Microsoft GPG key
            curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-archive-keyring.gpg
            
            # Add the repository
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-archive-keyring.gpg] https://packages.microsoft.com/repos/microsoft-debian-$(lsb_release -cs)-prod $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/microsoft.list > /dev/null
            
            # Update package lists
            sudo apt update
            
            # Install wslu
            sudo apt install -y wslu
            
            if [ $? -eq 0 ] && command_exists wslview; then
                print_success "WSL utilities installed successfully - Windows browser integration enabled"
            else
                print_warning "wslu installation failed - GitHub browser authentication will require manual steps"
            fi
        else
            print_success "WSL utilities already installed - Windows browser integration enabled"
        fi
        
        # Check if GitHub CLI is installed
        if ! command_exists gh; then
            print_step "Installing GitHub CLI..."
            
            # Make sure we have gnupg for key imports
            if ! command_exists gpg; then
                print_step "Installing gnupg for GitHub CLI repository..."
                sudo apt install -y gnupg
            fi
            
            # First add the GitHub CLI repository
            curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
            sudo apt update
            sudo apt install -y gh
            
            if [ $? -ne 0 ]; then
                print_error "Failed to install GitHub CLI"
                print_warning "You can still use GitHub, but you'll need to create repositories manually"
                return 1
            fi
        fi
        
        # Check if already logged in to GitHub
        if ! gh auth status &>/dev/null; then
            print_step "You need to authenticate with GitHub CLI..."
            echo -e "${YELLOW}Please follow the prompts to authenticate with GitHub...${NC}"
            
            # Provide instructions for manual authentication if needed
            echo -e "${BLUE}If browser authentication fails, you can manually visit:${NC}"
            echo -e "${CYAN}https://github.com/login/device${NC}"
            echo -e "${BLUE}and enter the code that will be displayed.${NC}\n"
            
            gh auth login
            
            if [ $? -ne 0 ]; then
                print_error "Failed to authenticate with GitHub"
                print_warning "You can still use GitHub, but you'll need to create repositories manually"
                return 1
            fi
        else
            print_step "Already authenticated with GitHub CLI"
        fi
        
        # Get GitHub username from authenticated session
        GITHUB_USERNAME=$(gh api user -q '.login')
        print_success "GitHub user detected: $GITHUB_USERNAME"
        
        return 0
    else
        print_step "Skipping GitHub integration"
    fi
    
    return 0
}

# Function to create GitHub repository using GitHub CLI
create_github_repository() {
    local repo_name="$1"
    local description="$2"
    local is_public="$3"
    
    if [ -z "$GITHUB_USERNAME" ] || ! command_exists gh; then
        print_warning "GitHub username not available or GitHub CLI not installed. Cannot create repository."
        return 1
    fi
    
    print_step "Creating GitHub repository: $repo_name"
    
    # Set visibility flag
    local visibility_flag="--private"
    if [ "$is_public" = "true" ]; then
        visibility_flag="--public"
    fi
    
    # Create repository using GitHub CLI
    gh repo create "$GITHUB_USERNAME/$repo_name" $visibility_flag --description "$description" --source=. --remote=origin
    
    if [ $? -ne 0 ]; then
        # Try without --source flag if it fails
        print_warning "Repository creation with --source flag failed. Trying without source flag..."
        gh repo create "$GITHUB_USERNAME/$repo_name" $visibility_flag --description "$description"
        
        if [ $? -ne 0 ]; then
            print_error "Failed to create repository on GitHub"
            return 1
        else
            # Manually set up the remote
            print_step "Setting up git remote..."
            git remote add origin "https://github.com/$GITHUB_USERNAME/$repo_name.git"
        fi
    fi
    
    print_success "Repository created successfully: https://github.com/$GITHUB_USERNAME/$repo_name"
    return 0
}

# Create comprehensive documentation for installed components
create_component_docs() {
    print_header "Creating documentation for installed components"
    
    # Make sure the docs directory exists
    ensure_dir "$SETUP_DIR/docs" || return 1
    
    # Create Neovim guide
    cat > "$SETUP_DIR/docs/neovim-guide.md" << 'EOL'
# Neovim Guide

This guide covers the basics of using Neovim with the Kickstart configuration installed by the WSL development environment setup.

## Configuration Location

Your Neovim configuration is located at:
- `~/.config/nvim/init.lua` - Main configuration file
- `~/.config/nvim/lua/custom/` - Directory for your custom configurations

## Key Bindings

### Basic Navigation
- `h`, `j`, `k`, `l` - Move cursor left, down, up, right
- `w` / `b` - Jump to next/previous word
- `gg` / `G` - Go to beginning/end of file
- `Ctrl+u` / `Ctrl+d` - Scroll half page up/down
- `Ctrl+o` / `Ctrl+i` - Jump back/forward in jump list

### File Operations
- `<leader>ff` - Find files
- `<leader>fg` - Live grep (search within files)
- `<leader>fb` - Browse buffers
- `<leader>fh` - Search help tags
- `<leader>fo` - Recent files
- `<leader>/` - Search in current buffer

### Buffer Navigation
- `<leader>b]` - Next buffer
- `<leader>b[` - Previous buffer
- `<leader>bd` - Delete buffer

### Code Navigation
- `gd` - Go to definition
- `gr` - Go to references
- `K` - Show documentation
- `<leader>ca` - Code actions
- `<leader>rn` - Rename symbol

### Window Management
- `<Ctrl+w>s` - Split horizontally
- `<Ctrl+w>v` - Split vertically
- `<Ctrl+w>h/j/k/l` - Navigate splits
- `<Ctrl+w>q` - Close split

### Code Editing
- `gcc` - Comment line
- `gc` - Comment selection (visual mode)
- `Tab` / `Shift+Tab` - Indent/Outdent in visual mode
- `=` - Format selection
- `<leader>cf` - Format file

### LSP Features
- `<leader>cd` - Show line diagnostics
- `[d` / `]d` - Previous/Next diagnostic
- `<leader>cs` - Document symbols
- `<leader>cw` - Workspace symbols

## Managing with Chezmoi

Your Neovim configuration is managed by Chezmoi. To make changes:

1. Edit your configuration:
   ```bash
   chezmoi edit ~/.config/nvim/init.lua
   # Or
   chezmoi edit ~/.config/nvim/lua/custom/YOUR_PLUGIN.lua
   ```

2. Apply changes:
   ```bash
   chezmoi apply
   ```

3. Sync with GitHub:
   ```bash
   chezmoi git add .
   chezmoi git commit -m "Update Neovim config"
   chezmoi git push
   ```

## Adding Plugins

1. Create a new file in the custom directory:
   ```bash
   nvim ~/.config/nvim/lua/custom/plugins/your_plugin.lua
   ```

2. Add your plugin specification:
   ```lua
   return {
     "github-username/plugin-name",
     config = function()
       -- Your configuration here
     end,
   }
   ```

3. Add the file to Chezmoi:
   ```bash
   chezmoi add ~/.config/nvim/lua/custom/plugins/your_plugin.lua
   ```

## More Information

For more details on Kickstart Neovim:
- Run `:help` within Neovim
- View the [Kickstart.nvim GitHub repository](https://github.com/nvim-lua/kickstart.nvim)
EOL
    
    # Create Zsh guide
    cat > "$SETUP_DIR/docs/zsh-guide.md" << 'EOL'
# Zsh Guide

This guide covers the basics of using Zsh with Oh My Zsh in the WSL development environment.

## Configuration Location

Your Zsh configuration is located at:
- `~/.zshrc` - Main configuration file

## Features Installed

- **Oh My Zsh** - Framework for managing Zsh configuration
- **Plugins**:
  - `git` - Git shortcuts and prompt info
  - `zsh-autosuggestions` - Command suggestions as you type
  - `zsh-syntax-highlighting` - Syntax highlighting for commands
  - `fzf` - Fuzzy finder integration
  - `tmux` - Tmux integration

## Useful Aliases

### General
- `c` - Clear terminal
- `..` - Go up one directory
- `...` - Go up two directories
- `ll` - List files (detailed)
- `la` - List all files

### Git
- `gs` - Git status
- `ga` - Git add
- `gc` - Git commit with message (`gc "your message"`)
- `gp` - Git push
- `gl` - Git pull

### Tmux
- `t` - Start tmux
- `ta` - Attach to tmux session (`ta session-name`)
- `tn` - New tmux session (`tn session-name`)
- `tl` - List tmux sessions

### Editor
- `vim` or `v` - Open Neovim

## Oh My Zsh Features

### Autocompletion
- Press `Tab` for completion
- Navigate completion options with arrow keys
- Accept suggestion with `→` (right arrow) or `End`

### Directory Navigation
- `cd -` - Navigate to previous directory
- `cd -<Tab>` - See and select from directory history

### History
- `Ctrl+r` - Search command history
- Arrow up/down - Navigate through history

## Managing with Chezmoi

Your Zsh configuration is managed by Chezmoi. To make changes:

1. Edit your configuration:
   ```bash
   chezmoi edit ~/.zshrc
   ```

2. Apply changes:
   ```bash
   chezmoi apply
   ```

3. Sync with GitHub:
   ```bash
   chezmoi git add .
   chezmoi git commit -m "Update Zsh config"
   chezmoi git push
   ```

## Customizing

### Adding new aliases

Edit your `~/.zshrc` file with Chezmoi and add aliases:

```bash
chezmoi edit ~/.zshrc
```

Then add your aliases:
```bash
# Custom aliases
alias myalias='command'
```

### Installing new Oh My Zsh plugins

1. Edit your `~/.zshrc`:
   ```bash
   chezmoi edit ~/.zshrc
   ```

2. Find the plugins section and add your plugin:
   ```bash
   plugins=(
     git
     zsh-autosuggestions
     zsh-syntax-highlighting
     fzf
     tmux
     your-new-plugin
   )
   ```

3. Apply the changes:
   ```bash
   chezmoi apply
   source ~/.zshrc
   ```

## More Information

For more details on Oh My Zsh:
- [Oh My Zsh GitHub repository](https://github.com/ohmyzsh/ohmyzsh)
- Run `omz help` for built-in help
EOL
    
    # Create Tmux guide
    cat > "$SETUP_DIR/docs/tmux-guide.md" << 'EOL'
# Tmux Guide

This guide covers the basics of using Tmux in the WSL development environment.

## Configuration Location

Your Tmux configuration is located at:
- `~/.tmux.conf` - Main configuration file

## Key Bindings

The prefix key is set to `Ctrl+a` (instead of the default `Ctrl+b`).

### Session Management
- `Ctrl+a c` - Create a new window
- `Ctrl+a ,` - Rename current window
- `Ctrl+a w` - List all windows
- `Ctrl+a n` - Move to next window
- `Ctrl+a p` - Move to previous window
- `Ctrl+a 0-9` - Switch to window by number
- `Ctrl+a d` - Detach from session
- `Ctrl+a r` - Reload tmux configuration

### Window Splitting
- `Ctrl+a |` - Split window horizontally
- `Ctrl+a -` - Split window vertically

### Pane Navigation
- `Ctrl+a h` - Move to left pane
- `Ctrl+a j` - Move to pane below
- `Ctrl+a k` - Move to pane above
- `Ctrl+a l` - Move to right pane
- `Ctrl+a o` - Cycle through panes
- `Ctrl+a x` - Close current pane

### Pane Manipulation
- `Ctrl+a z` - Toggle pane zoom (fullscreen)
- `Ctrl+a {` - Move current pane left
- `Ctrl+a }` - Move current pane right
- `Ctrl+a Space` - Cycle through pane layouts

### Copy Mode
- `Ctrl+a [` - Enter copy mode
- `Space` - Start selection (in copy mode)
- `Enter` - Copy selection (in copy mode)
- `Ctrl+a ]` - Paste copied text

## Common Terminal Commands

- `tmux` - Start a new tmux session
- `tmux new -s name` - Start a new named session
- `tmux attach` or `tmux a` - Attach to the last session
- `tmux attach -t name` - Attach to a specific session
- `tmux ls` - List all sessions
- `tmux kill-session -t name` - Kill a specific session

## Mouse Support

Mouse support is enabled in the configuration. You can:
- Click to select panes
- Scroll to navigate through terminal output
- Drag pane borders to resize
- Select text with click and drag

## Managing with Chezmoi

Your Tmux configuration is managed by Chezmoi. To make changes:

1. Edit your configuration:
   ```bash
   chezmoi edit ~/.tmux.conf
   ```

2. Apply changes:
   ```bash
   chezmoi apply
   ```

3. Reload Tmux configuration:
   ```bash
   tmux source-file ~/.tmux.conf
   # Or from within tmux: Ctrl+a r
   ```

4. Sync with GitHub:
   ```bash
   chezmoi git add .
   chezmoi git commit -m "Update Tmux config"
   chezmoi git push
   ```

## Customizing

### Adding new bindings

Edit your `~/.tmux.conf` file with Chezmoi and add bindings:

```bash
chezmoi edit ~/.tmux.conf
```

Then add your bindings:
```
# Custom binding
bind-key M-x command
```

## More Information

For more details on Tmux:
- Run `man tmux` in your terminal
- [Tmux cheatsheet](https://tmuxcheatsheet.com/)
EOL
    
    # Create WSL Utilities guide
    cat > "$SETUP_DIR/docs/wsl-utilities-guide.md" << 'EOL'
# WSL Utilities Guide

This guide covers the WSL-specific utilities installed by the development environment setup.

## Available Utilities

### VS Code Integration (code)
- Opens VS Code from WSL with correct path translation
- Allows seamless editing of WSL files from Windows VS Code

#### Usage
```bash
# Open current directory in VS Code
code .

# Open specific file
code filename.txt

# Open multiple files
code file1.txt file2.txt
```

### Windows Explorer Integration (winopen)
- Opens Windows Explorer at the current or specified WSL directory

#### Usage
```bash
# Open current directory in Windows Explorer
winopen

# Open specific directory
winopen ~/projects
```

### Windows Clipboard Access (clip-copy)
- Copy text from WSL to Windows clipboard

#### Usage
```bash
# Copy text directly
clip-copy "Text to copy"

# Copy output from another command
echo "Hello World" | clip-copy

# Copy file contents
cat file.txt | clip-copy
```

## File Locations

These utilities are installed in your `~/bin` directory:
- `~/bin/code-wrapper.sh` - VS Code integration
- `~/bin/winopen` - Windows Explorer integration
- `~/bin/clip-copy` - Clipboard utility

## Path Translation

WSL <-> Windows path translation is handled automatically by the utilities, but you can also do it manually:

```bash
# Convert WSL path to Windows path
wslpath -w /home/username/file.txt
# Result: C:\Users\username\AppData\Local\Packages\...\LocalState\rootfs\home\username\file.txt

# Convert Windows path to WSL path
wslpath 'C:\Users\username\Documents'
# Result: /mnt/c/Users/username/Documents
```

## Managing with Chezmoi

Your WSL utilities are managed by Chezmoi. To make changes:

1. Edit a utility:
   ```bash
   chezmoi edit ~/bin/winopen
   ```

2. Apply changes:
   ```bash
   chezmoi apply
   ```

3. Make the script executable if needed:
   ```bash
   chmod +x ~/bin/winopen
   ```

4. Sync with GitHub:
   ```bash
   chezmoi git add .
   chezmoi git commit -m "Update WSL utilities"
   chezmoi git push
   ```

## Customizing

### Creating a new WSL utility

1. Create a new script in your `~/bin` directory:
   ```bash
   chezmoi edit-new ~/bin/my-new-utility
   ```

2. Add your script content, for example:
   ```bash
   #!/bin/bash
   # My new WSL utility
   
   # Your code here
   echo "Hello from WSL!"
   ```

3. Apply the changes and make executable:
   ```bash
   chezmoi apply
   chmod +x ~/bin/my-new-utility
   ```

4. Add to Chezmoi:
   ```bash
   chezmoi add ~/bin/my-new-utility
   ```
EOL
    
    # Create GitHub CLI guide
    cat > "$SETUP_DIR/docs/github-cli-guide.md" << 'EOL'
# GitHub CLI Guide

This guide covers the basics of using GitHub CLI (gh) in the WSL development environment.

## Basic Commands

### Authentication
- `gh auth login` - Log in to GitHub
- `gh auth status` - Check authentication status
- `gh auth logout` - Log out from GitHub

### Repository Management
- `gh repo create <name>` - Create a new repository
- `gh repo clone <repository>` - Clone a repository
- `gh repo view [repository]` - View a repository in the browser
- `gh repo fork [repository]` - Fork a repository

### Issues and Pull Requests
- `gh issue list` - List issues
- `gh issue create` - Create an issue
- `gh issue view <number>` - View an issue
- `gh pr list` - List pull requests
- `gh pr create` - Create a pull request
- `gh pr checkout <number>` - Check out a pull request

### Other Useful Commands
- `gh gist create <file>` - Create a gist
- `gh gist list` - List your gists
- `gh release create <tag>` - Create a release
- `gh release list` - List releases

## Integration with Git

GitHub CLI integrates with Git to provide a more seamless workflow:

```bash
# Clone your repository
gh repo clone your-username/your-repo

# Create and push a branch
git checkout -b feature-branch
git commit -am "Add feature"
git push -u origin feature-branch

# Create a pull request for the branch
gh pr create
```

## Integration with Chezmoi

GitHub CLI works great with Chezmoi for managing dotfiles:

1. Create a dotfiles repository:
   ```bash
   cd ~/.local/share/chezmoi
   gh repo create dotfiles --private
   ```

2. Push your changes:
   ```bash
   chezmoi git add .
   chezmoi git commit -m "Update configuration"
   chezmoi git push
   ```

3. Pull your dotfiles on another machine:
   ```bash
   gh repo clone your-username
   # Or with chezmoi
   chezmoi init your-username
   ```

## Custom Aliases

You can create custom aliases for GitHub CLI commands:

```bash
# Set an alias
gh alias set prs 'pr list --state open --limit 10'

# Now use it
gh prs
```

## More Information

For more details on GitHub CLI:
- Run `gh help` for built-in help
- Visit the [GitHub CLI documentation](https://cli.github.com/manual/)
EOL
    
    # Create Quick Reference Guide
    cat > "$SETUP_DIR/docs/quick-reference.md" << 'EOL'
# Quick Reference

This document provides a quick reference to the tools installed in your WSL development environment.

## Documentation

Detailed guides are available in the `~/dev-env/docs/` directory:
- `neovim-guide.md` - Neovim editor
- `zsh-guide.md` - Zsh shell
- `tmux-guide.md` - Tmux terminal multiplexer
- `chezmoi-guide.md` - Chezmoi dotfile manager
- `wsl-utilities-guide.md` - WSL-specific utilities
- `github-cli-guide.md` - GitHub CLI
- `claude-code-guide.md` - Claude Code AI assistant

## Common Commands

### Neovim
- `nvim file.txt` - Edit a file
- `<leader>ff` - Find files
- `<leader>fg` - Search in files
- `<leader>ca` - Code actions
- `<leader>e` - Toggle file explorer

### Zsh
- `c` - Clear terminal
- `ll` - List files (detailed)
- `gs` - Git status
- `ga` - Git add
- `gc "message"` - Git commit

### Tmux
- `tmux` - Start tmux
- `Ctrl+a c` - Create window
- `Ctrl+a |` - Split vertically
- `Ctrl+a -` - Split horizontally
- `Ctrl+a d` - Detach session

### Chezmoi
- `chezmoi add ~/.zshrc` - Add file to chezmoi
- `chezmoi edit ~/.zshrc` - Edit managed file
- `chezmoi apply` - Apply changes
- `chezmoi update` - Pull and apply changes

### GitHub CLI
- `gh repo create` - Create repository
- `gh pr create` - Create pull request
- `gh issue create` - Create issue

### WSL Utilities
- `code .` - Open VS Code in current directory
- `winopen` - Open Windows Explorer
- `clip-copy "text"` - Copy to Windows clipboard

## Managing Configuration

All configuration files are managed by Chezmoi:

1. Edit a configuration file:
   ```bash
   chezmoi edit ~/.zshrc  # Edit zsh config
   chezmoi edit ~/.tmux.conf  # Edit tmux config
   chezmoi edit ~/.config/nvim/init.lua  # Edit neovim config
   ```

2. Apply changes:
   ```bash
   chezmoi apply
   ```

3. Sync with GitHub:
   ```bash
   chezmoi git add .
   chezmoi git commit -m "Update config"
   chezmoi git push
   ```

4. Sync on another machine:
   ```bash
   chezmoi update
   ```

## Update Environment

To update your entire environment:

```bash
~/dev-env/update.sh
```
EOL
    
    if [ $? -ne 0 ]; then
        print_error "Failed to create component documentation"
        return 1
    fi
    
    print_success "Component documentation created successfully"
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
