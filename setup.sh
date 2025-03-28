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
        build-essential file cmake ripgrep fd-find fzf tmux zsh ansible \
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
    print_header "Setting up Neovim configuration"
    print_step "Setting up Kickstart Neovim configuration..."

    # Create necessary directories
    ensure_dir ~/.config || return 1
    ensure_dir ~/.config/nvim || return 1

    # Check if kickstart is already installed
    if [ -f ~/.config/nvim/init.lua ] && grep -q "kickstart" ~/.config/nvim/init.lua; then
        print_step "Kickstart Neovim configuration already installed, updating..."
        # Just create the custom directory without touching kickstart setup
        ensure_dir ~/.config/nvim/lua/custom || return 1
    else
        # Backup existing configuration if any
        if [ -d ~/.config/nvim ] && [ "$(ls -A ~/.config/nvim)" ]; then
            BACKUP_DIR="$HOME/.config/nvim_backup_$(date +%Y%m%d%H%M%S)"
            print_step "Backing up existing Neovim configuration to $BACKUP_DIR"
            mv ~/.config/nvim "$BACKUP_DIR"
            ensure_dir ~/.config/nvim || return 1
        fi
        
        # Ask if user has their own fork
        echo -e "\n${BLUE}Do you have your own fork of kickstart.nvim on GitHub? (y/n)${NC}"
        read -r has_fork
        
        if [[ "$has_fork" =~ ^[Yy]$ ]]; then
            # Ask for GitHub username
            echo -e "${BLUE}Please enter your GitHub username:${NC}"
            read -r github_username
            
            if [ -z "$github_username" ]; then
                print_warning "No username provided, falling back to default repository"
                git clone --depth=1 https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
            else
                # Clone from user's fork
                print_step "Cloning from your fork at https://github.com/$github_username/kickstart.nvim.git"
                git clone --depth=1 "https://github.com/$github_username/kickstart.nvim.git" ~/.config/nvim
                
                # Modify .gitignore to track lazy-lock.json as recommended
                if [ -f ~/.config/nvim/.gitignore ]; then
                    print_step "Modifying .gitignore to track lazy-lock.json..."
                    sed -i '/lazy-lock.json/d' ~/.config/nvim/.gitignore
                    print_success "Modified .gitignore to track lazy-lock.json"
                fi
            fi
        else
            # Clone default kickstart.nvim
            print_step "Installing Kickstart Neovim from official repository..."
            git clone --depth=1 https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
        fi
        
        if [ $? -ne 0 ]; then
            print_error "Failed to clone Kickstart Neovim"
            print_warning "Make sure git is installed and you have internet connectivity"
            return 1
        fi
        
        # Make sure custom directory exists
        ensure_dir ~/.config/nvim/lua/custom || return 1
    fi

    print_success "Neovim Kickstart configuration installed"
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
    print_header "Creating Zsh configuration file"
    print_step "Creating Zsh configuration..."
    
    cat > "$HOME/.zshrc" << 'EOL'
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

# Run neofetch at startup for system info
if [ -f "/usr/bin/neofetch" ]; then
  /usr/bin/neofetch --backend ascii --disable disk --disk_show '/' --cpu_speed on --cpu_cores logical
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
        print_error "Failed to create Zsh configuration file"
        return 1
    fi
    
    print_success "Zsh configuration file created"
    return 0
}

# Setup tmux 
setup_tmux() {
    print_header "Setting up tmux configuration"
    
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
    cat > "$HOME/.tmux.conf" << 'EOL'
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
        print_error "Failed to create tmux configuration"
        return 1
    fi
    
    print_success "tmux configuration completed"
    return 0
}

# Setup WSL utilities
setup_wsl_utilities() {
    print_header "Setting up WSL utilities"
    
    # Create bin directory
    ensure_dir ~/bin || return 1
    
    # Create VS Code wrapper
    print_step "Creating VS Code wrapper script..."
    cat > "$HOME/bin/code-wrapper.sh" << 'EOL'
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
    
    chmod +x "$HOME/bin/code-wrapper.sh"
    
    # Create Windows path opener
    print_step "Creating Windows path opener utility..."
    cat > "$HOME/bin/winopen" << 'EOL'
#!/bin/bash
# Open current directory or specified path in Windows Explorer

path_to_open="${1:-.}"
windows_path=$(wslpath -w "$(realpath "$path_to_open")")
explorer.exe "$windows_path"
EOL
    
    chmod +x "$HOME/bin/winopen"
    
    # Create clipboard utility
    print_step "Creating clipboard utility..."
    cat > "$HOME/bin/clip-copy" << 'EOL'
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
    
    chmod +x "$HOME/bin/clip-copy"
    
    # Create alias for code-wrapper in bashrc
    if ! grep -q "alias code=" ~/.bashrc; then
        echo 'alias code="$HOME/bin/code-wrapper.sh"' >> ~/.bashrc
    fi
    
    print_success "WSL utilities setup completed"
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
    
    print_success "Node.js environment configured successfully"
    return 0
}

# Setup Claude Code from Anthropic
setup_claude_code() {
    print_header "Installing Claude Code"
    
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
    
    # Verify installation
    if command_exists claude; then
        print_success "Claude Code installed successfully!"
    else
        print_warning "Claude Code installation might have issues."
        print_warning "Try manually running: npm install -g @anthropic-ai/claude-code --force --no-os-check"
        return 1
    fi
    
    print_success "Claude Code setup completed"
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
    echo -e "- Node.js via NVM"
    echo -e "- Claude Code AI assistant"
    
    echo -e "\n${BLUE}To update your environment in the future:${NC}"
    echo -e "- Run ${YELLOW}~/dev-env/update.sh${NC}"
    
    echo -e "\n${BLUE}Neovim Kickstart Tips:${NC}"
    echo -e "- If you didn't use your own fork, consider forking kickstart.nvim on GitHub:"
    echo -e "  ${YELLOW}https://github.com/nvim-lua/kickstart.nvim/fork${NC}"
    echo -e "- Customize your Neovim setup in ${YELLOW}~/.config/nvim/lua/custom/${NC}"
    
    echo -e "\n${PURPLE}Happy coding!${NC}"
}

# --- Main Script Execution ---
echo -e "${PURPLE}===============================================${NC}"
echo -e "${PURPLE}| WSL Development Environment Setup v${SCRIPT_VERSION} |${NC}"
echo -e "${PURPLE}===============================================${NC}"
echo -e "${GREEN}This script will set up a development environment optimized for WSL Debian${NC}"

# Execute setup functions in sequence, but stop if any fails
setup_workspace || exit 1
update_system || exit 1
install_core_deps || exit 1
install_neofetch || exit 1
install_neovim || exit 1
setup_nvim_config || exit 1
setup_ansible || exit 1
setup_zsh || exit 1
setup_zshrc || exit 1
setup_tmux || exit 1
setup_wsl_utilities || exit 1
setup_nodejs || exit 1
setup_claude_code || exit 1
create_claude_code_docs || exit 1
create_update_script || exit 1

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
