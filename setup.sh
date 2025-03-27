#!/bin/bash

# ===================================
# Ultimate WSL Development Environment Setup v0.3.1
# A beginner-friendly, modular development environment for WSL Debian
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
SCRIPT_VERSION="0.3.1"
NVIM_VERSION="0.10.0"
SETUP_DIR="$HOME/dev-env"

# --- Utility functions ---

# Print a fancy title banner
print_title() {
    local title="$1"
    local border_length=${#title}
    local border=""
    
    for ((i=0; i<border_length+4; i++)); do
        border+="="
    done
    
    echo -e "${PURPLE}"
    echo "$border"
    echo "| $title |"
    echo "$border"
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

# Error handling with option to continue
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}ERROR: $1${NC}"
        echo -e "${YELLOW}Would you like to continue anyway? (y/n)${NC}"
        read -r response
        if [[ "$response" != "y" ]]; then
            echo "Setup aborted."
            exit 1
        fi
    fi
}

# Create directory if it doesn't exist
ensure_dir() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        check_error "Failed to create directory: $1"
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Refresh PATH and available commands
refresh_path() {
    export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
    hash -r
}

# Check if we're already using Zsh
USING_ZSH=0
if [ -n "$ZSH_VERSION" ]; then
    USING_ZSH=1
fi

# --- Main functions ---

# Create the necessary directory structure
setup_workspace() {
    print_header "Creating Workspace Structure"
    print_step "Setting up directory structure..."

    # Main directory structure
    ensure_dir ~/dev-env
    ensure_dir ~/.local/bin
    ensure_dir ~/bin
    ensure_dir ~/tools
    ensure_dir ~/dev

    # Create all config directories first to avoid "No such file or directory" errors
    ensure_dir ~/dev-env/ansible/roles
    ensure_dir ~/dev-env/configs/nvim/custom
    ensure_dir ~/dev-env/configs/zsh
    ensure_dir ~/dev-env/configs/tmux
    ensure_dir ~/dev-env/configs/wsl
    ensure_dir ~/dev-env/configs/git
    ensure_dir ~/dev-env/bin
    ensure_dir ~/dev-env/docs

    SETUP_DIR="$HOME/dev-env"
    cd "$SETUP_DIR" || { echo -e "${RED}Failed to change directory to $SETUP_DIR${NC}"; exit 1; }
    
    print_success "Directory structure created successfully"
}

# Update system packages
update_system() {
    print_header "Updating System Packages"
    print_step "Updating package lists..."
    sudo apt update
    check_error "Failed to update package lists"

    print_step "Upgrading packages..."
    sudo apt upgrade -y
    check_error "Failed to upgrade packages"
    
    print_success "System packages updated successfully"
}

# Install core dependencies
install_core_deps() {
    print_header "Installing core dependencies"
    print_step "Installing essential packages..."
    
    sudo apt install -y curl wget git python3 python3-pip python3-venv unzip \
        build-essential file cmake ripgrep fd-find fzf tmux zsh neofetch ansible
    check_error "Failed to install core dependencies"
    
    print_success "Core dependencies installed successfully"
    
    # Make sure PATH includes our local bin directories
    refresh_path
}

# Install Neofetch for system information display
install_neofetch() {
    print_header "Installing Neofetch"
    if ! command_exists neofetch; then
        print_step "Installing Neofetch..."
        sudo apt install -y neofetch
        check_error "Failed to install Neofetch"
        print_success "Neofetch installed successfully"
    else
        print_step "Neofetch is already installed"
    fi
}

# Install Neovim text editor
install_neovim() {
    print_header "Installing Neovim"
    if ! command_exists nvim; then
        print_step "Downloading Neovim..."
        
        # Create temporary directory for installation
        TEMP_DIR=$(mktemp -d)
        check_error "Failed to create temporary directory for Neovim installation"
        
        cd "$TEMP_DIR" || { echo -e "${RED}Failed to change directory to $TEMP_DIR${NC}"; exit 1; }
        
        # Download Neovim AppImage
        wget -q "https://github.com/neovim/neovim/releases/download/v${NVIM_VERSION}/nvim.appimage"
        check_error "Failed to download Neovim AppImage"
        
        # Make it executable
        chmod u+x nvim.appimage
        check_error "Failed to make Neovim AppImage executable"
        
        # Extract the AppImage
        print_step "Extracting Neovim AppImage..."
        ./nvim.appimage --appimage-extract
        check_error "Failed to extract Neovim AppImage"
        
        # Create the target directory and move files
        print_step "Installing Neovim..."
        sudo mkdir -p /opt/nvim
        check_error "Failed to create /opt/nvim directory"
        
        sudo cp -r squashfs-root/* /opt/nvim/
        check_error "Failed to copy Neovim files to /opt/nvim"
        
        # Create symlinks
        sudo ln -sf /opt/nvim/AppRun /usr/local/bin/nvim
        check_error "Failed to create system-wide Neovim symlink"
        
        ln -sf /usr/local/bin/nvim ~/.local/bin/nvim
        check_error "Failed to create user Neovim symlink"
        
        # Clean up temporary files
        cd "$SETUP_DIR" || { echo -e "${RED}Failed to return to $SETUP_DIR${NC}"; exit 1; }
        rm -rf "$TEMP_DIR"
        check_error "Failed to clean up temporary Neovim installation files"
        
        # Verify installation
        print_step "Verifying Neovim installation..."
        refresh_path
        
        if ! command_exists nvim; then
            print_warning "Neovim installation verification failed. Path may not be updated."
            print_warning "Please try running: hash -r"
            hash -r
            if ! command_exists nvim; then
                print_warning "Neovim still not found. Will continue but you may need to restart your terminal."
            fi
        else
            nvim --version
            print_success "Neovim installed successfully"
        fi
    else
        print_step "Neovim is already installed"
        nvim --version
    fi
}

# Setup Neovim with Kickstart configuration
setup_nvim_config() {
    print_header "Setting up Neovim configuration"
    print_step "Setting up Kickstart Neovim configuration..."

    # Improved approach for kickstart installation that properly handles existing directories
    ensure_dir ~/.config
    ensure_dir ~/.config/nvim

    # First, check if the directory already has a kickstart installation
    if [ -f ~/.config/nvim/init.lua ] && grep -q "kickstart" ~/.config/nvim/init.lua; then
        print_step "Kickstart Neovim configuration already installed, updating..."
        # Just create the custom directory without touching kickstart setup
        ensure_dir ~/.config/nvim/lua/custom
    else
        # Backup existing configuration if any
        if [ -d ~/.config/nvim ] && [ "$(ls -A ~/.config/nvim)" ]; then
            BACKUP_DIR="$HOME/.config/nvim_backup_$(date +%Y%m%d%H%M%S)"
            print_step "Backing up existing Neovim configuration to $BACKUP_DIR"
            mv ~/.config/nvim "$BACKUP_DIR"
            ensure_dir ~/.config/nvim
        fi
        
        # Clone kickstart.nvim - fresh install
        print_step "Installing Kickstart Neovim..."
        git clone --depth=1 https://github.com/nvim-lua/kickstart.nvim.git ~/.config/nvim
        check_error "Failed to clone Kickstart Neovim"
        
        # Make sure custom directory exists
        ensure_dir ~/.config/nvim/lua/custom
    fi

    # Create custom init.lua to extend Kickstart
    print_step "Creating custom Neovim configuration..."
    cat > "$SETUP_DIR/configs/nvim/custom/init.lua" << 'EOL'
-- Custom NeoVim configuration extending Kickstart
-- This is loaded after the main Kickstart configuration

-- ================= DISPLAY SETTINGS =================
vim.opt.relativenumber = true    -- Relative line numbers
vim.opt.scrolloff = 8            -- Keep 8 lines visible when scrolling
vim.opt.sidescrolloff = 8        -- Keep 8 columns left/right of cursor
vim.opt.wrap = true              -- Wrap lines
vim.opt.termguicolors = true     -- Full color support

-- ================= EDITOR BEHAVIOR =================
vim.opt.expandtab = true         -- Use spaces instead of tabs
vim.opt.shiftwidth = 2           -- Size of an indent
vim.opt.tabstop = 2              -- Number of spaces tabs count for
vim.opt.ignorecase = true        -- Ignore case in search patterns
vim.opt.smartcase = true         -- Override ignorecase when pattern has uppercase

-- ================= KEY MAPPINGS =================
-- Use space as leader key
vim.g.mapleader = " "

-- Window navigation
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Move to left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Move to below window' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Move to above window' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Move to right window' })

-- Quick save with leader+w
vim.keymap.set('n', '<leader>w', ':w<CR>', { desc = 'Save file' })

-- Quick quit shortcuts
vim.keymap.set('n', '<leader>q', ':q<CR>', { desc = 'Quit' })
vim.keymap.set('n', '<leader>Q', ':qa!<CR>', { desc = 'Quit without saving' })

-- Buffer navigation
vim.keymap.set('n', '<S-h>', ':bprevious<CR>', { desc = 'Previous buffer' })
vim.keymap.set('n', '<S-l>', ':bnext<CR>', { desc = 'Next buffer' })

-- Better indenting - stay in visual mode
vim.keymap.set('v', '<', '<gv', { desc = 'Outdent line' })
vim.keymap.set('v', '>', '>gv', { desc = 'Indent line' })

-- Move selected text up and down
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv", { desc = 'Move selection down' })
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv", { desc = 'Move selection up' })

-- Terminal escape
vim.keymap.set('t', '<Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- ================= CUSTOM COMMANDS =================
-- Easy access to terminal
vim.api.nvim_create_user_command('T', 'split | terminal', {})

-- ================= AUTOCOMMANDS =================
-- Return to last edit position when opening files
vim.api.nvim_create_autocmd('BufReadPost', {
  pattern = '*',
  callback = function()
    local line = vim.fn.line
    if line("'\"") > 0 and line("'\"") <= line("$") then
      vim.cmd('normal! g`"')
    end
  end
})

-- Auto close certain filetypes with q
vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'help', 'qf', 'man' },
  callback = function()
    vim.keymap.set('n', 'q', ':close<CR>', { buffer = true, silent = true })
  end
})

-- ================= THEME CONFIGURATION =================
-- Add Rose Pine theme with pure black background
table.insert(require('lazy').plugins, {
  'rose-pine/neovim',
  name = 'rose-pine',
  config = function()
    require('rose-pine').setup({
      variant = 'moon', -- moon, dawn, or main
      dark_variant = 'moon',
      disable_background = true,
      disable_float_background = false,
      disable_italics = false,
      highlight_groups = {
        Normal = { bg = "#000000" },
        NormalFloat = { bg = "#000000" },
        StatusLine = { bg = "#000000" },
        StatusLineNC = { bg = "#000000" },
        SignColumn = { bg = "#000000" },
      }
    })
    
    -- Set colorscheme after options
    vim.cmd('colorscheme rose-pine')
    
    -- Set pure black background after colorscheme
    vim.api.nvim_set_hl(0, "Normal", { bg = "#000000" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "#000000" })
    vim.api.nvim_set_hl(0, "NormalNC", { bg = "#000000" })
  end,
  priority = 1000, -- Load theme early
})

-- ================= OTHER PLUGINS =================
-- Configure nvim-treesitter to install without prompts
vim.g.treesitter_auto_install = true
EOL
    check_error "Failed to create custom Neovim configuration file"

    # Copy the custom configuration to Neovim
    cp "$SETUP_DIR/configs/nvim/custom/init.lua" ~/.config/nvim/lua/custom/init.lua
    check_error "Failed to copy custom Neovim configuration"

    print_success "Custom Neovim configuration updated"
}

# Setup Ansible
setup_ansible() {
    print_header "Setting up Ansible"
    if ! command_exists ansible; then
        print_step "Installing Ansible..."
        sudo apt install -y ansible
        check_error "Failed to install Ansible"
        print_success "Ansible installed successfully!"
    else
        print_step "Ansible is already installed"
    fi
    
    # Create Ansible playbooks directory structure
    ensure_dir "$SETUP_DIR/ansible/roles/core-tools/tasks"
    ensure_dir "$SETUP_DIR/ansible/roles/shell/tasks"
    ensure_dir "$SETUP_DIR/ansible/roles/tmux/tasks"
    ensure_dir "$SETUP_DIR/ansible/roles/wsl-specific/tasks"
    ensure_dir "$SETUP_DIR/ansible/roles/git-config/tasks"
    ensure_dir "$SETUP_DIR/ansible/roles/nodejs/tasks"
    
    # Create main playbook
    print_step "Creating Ansible playbooks..."
    cat > "$SETUP_DIR/ansible/setup.yml" << 'EOL'
---
# Main playbook for WSL development environment
- name: Set up WSL development environment
  hosts: localhost
  connection: local
  become: false
  
  roles:
    - core-tools     # Essential development tools
    - shell          # Zsh with useful plugins
    - tmux           # Terminal multiplexer
    - wsl-specific   # WSL-specific optimizations
    - git-config     # Git configuration
    - nodejs         # Node.js and npm
EOL
    check_error "Failed to create main Ansible playbook"
    
    # Create core-tools role
    cat > "$SETUP_DIR/ansible/roles/core-tools/tasks/main.yml" << 'EOL'
---
# Essential development tools installation
- name: Update package cache
  become: true
  apt:
    update_cache: yes
  
- name: Install essential development packages
  become: true
  apt:
    name:
      # Core utilities
      - ripgrep          # Better grep (rg) - CRITICAL for Telescope plugin
      - fd-find          # Better find (fd)
      - fzf              # Fuzzy finder
      - tmux             # Terminal multiplexer
      - zsh              # Better shell
      - file             # Determine file type
      - neofetch         # System info display
      
      # Development essentials
      - build-essential  # Compilation tools
      - git              # Version control
      - curl             # Transfer data
      - wget             # Download files
      - unzip            # Extract archives
      - python3-pip      # Python package manager
      - nodejs           # Node.js for language servers
      
      # Additional useful tools
      - jq               # JSON processor
      - bat              # Better cat with syntax highlighting
      - htop             # Interactive process viewer
    state: present

- name: Ensure local bin directory exists
  file:
    path: ~/.local/bin
    state: directory
    mode: '0755'

- name: Ensure ~/bin directory exists
  file:
    path: ~/bin
    state: directory
    mode: '0755'

- name: Create symbolic links for Debian-specific tool names
  file:
    src: "{{ item.src }}"
    dest: "{{ item.dest }}"
    state: link
    force: yes
  with_items:
    - { src: "/usr/bin/fdfind", dest: "~/.local/bin/fd" }
    - { src: "/usr/bin/batcat", dest: "~/.local/bin/bat" }
  when: >
    (item.src == "/usr/bin/fdfind" and lookup('file', '/usr/bin/fdfind', errors='ignore'))
    or (item.src == "/usr/bin/batcat" and lookup('file', '/usr/bin/batcat', errors='ignore'))

- name: Update .bashrc to include local bin in PATH
  lineinfile:
    path: ~/.bashrc
    line: 'export PATH="$HOME/bin:$HOME/.local/bin:$PATH"'
    regexp: '^export PATH=.*\$HOME/bin.*\$PATH.*$'
    state: present
EOL
    check_error "Failed to create core-tools role"
    
    print_success "Ansible setup completed"
}

# Setup Zsh shell
setup_zsh() {
    print_header "Setting up Zsh configurations"
    
    # Create shell role
    cat > "$SETUP_DIR/ansible/roles/shell/tasks/main.yml" << 'EOL'
---
# Setup Zsh with useful plugins

- name: Check if Oh My Zsh is installed
  stat:
    path: ~/.oh-my-zsh
  register: oh_my_zsh_installed

- name: Install Oh My Zsh
  shell: sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
  when: not oh_my_zsh_installed.stat.exists

- name: Install Zsh plugins
  git:
    repo: "{{ item.repo }}"
    dest: "{{ item.dest }}"
    depth: 1
  loop:
    - { repo: 'https://github.com/zsh-users/zsh-autosuggestions', dest: '~/.oh-my-zsh/custom/plugins/zsh-autosuggestions' }
    - { repo: 'https://github.com/zsh-users/zsh-syntax-highlighting.git', dest: '~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting' }

- name: Install Zoxide (smart cd command)
  shell: curl -sS https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | bash
  args:
    creates: ~/.local/bin/zoxide

- name: Copy Zsh configuration
  copy:
    src: "{{ playbook_dir }}/../configs/zsh/zshrc"
    dest: ~/.zshrc
    backup: yes
EOL
    check_error "Failed to create shell role"

    print_success "Zsh configuration completed"
}

# Setup tmux 
setup_tmux() {
    print_header "Setting up tmux configuration"
    
    # Create tmux role
    cat > "$SETUP_DIR/ansible/roles/tmux/tasks/main.yml" << 'EOL'
---
# Tmux setup with ThePrimeagen-inspired configuration

- name: Check if tmux is installed
  command: which tmux
  register: tmux_installed
  ignore_errors: true
  changed_when: false

- name: Install tmux
  become: true
  apt:
    name: tmux
    state: present
  when: tmux_installed.rc != 0

- name: Copy tmux configuration
  copy:
    src: "{{ playbook_dir }}/../configs/tmux/tmux.conf"
    dest: ~/.tmux.conf
    backup: yes
EOL
    check_error "Failed to create tmux role"
    
    # Create tmux configuration
    cat > "$SETUP_DIR/configs/tmux/tmux.conf" << 'EOL'
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

# Copy mode with vi keys
setw -g mode-keys vi
bind-key -T copy-mode-vi v send -X begin-selection
bind-key -T copy-mode-vi y send -X copy-pipe-and-cancel "clip.exe"

# Fast pane switching
bind -n M-h select-pane -L
bind -n M-j select-pane -D
bind -n M-k select-pane -U
bind -n M-l select-pane -R

# Session management
bind S command-prompt -p "New Session:" "new-session -A -s '%%'"
bind K confirm kill-session

# Status bar - clean and informative
set -g status-position top
set -g status-style bg=default
set -g status-left "#[fg=green]Session: #S #[fg=yellow]#I #[fg=cyan]#P "
set -g status-left-length 40
set -g status-right "#[fg=cyan]%d %b %R"
set -g status-interval 60
EOL
    check_error "Failed to create tmux configuration"
    
    print_success "tmux configuration completed"
}

# Setup WSL utilities
setup_wsl_utilities() {
    print_header "Setting up WSL utilities"
    
    # Create WSL-specific role
    cat > "$SETUP_DIR/ansible/roles/wsl-specific/tasks/main.yml" << 'EOL'
---
# WSL-specific optimizations and integrations

- name: Create bin directory
  file:
    path: ~/bin
    state: directory
    mode: '0755'

- name: Copy WSL utility scripts
  copy:
    src: "{{ playbook_dir }}/../configs/wsl/{{ item }}"
    dest: ~/bin/{{ item }}
    mode: '0755'
  with_items:
    - wsl-path-fix.sh
    - winopen
    - clip-copy

- name: Get Windows username
  shell: cmd.exe /c echo %USERNAME% | tr -d '\r\n'
  register: windows_username
  changed_when: false

- name: Ensure .wslconfig exists in Windows home
  copy:
    src: "{{ playbook_dir }}/../configs/wsl/wslconfig"
    dest: "/mnt/c/Users/{{ windows_username.stdout }}/.wslconfig"
    backup: yes
  ignore_errors: yes
EOL
    check_error "Failed to create wsl-specific role"
    
    # Path fix script
    print_step "Creating WSL path fix script..."
    cat > "$SETUP_DIR/configs/wsl/wsl-path-fix.sh" << 'EOL'
#!/bin/bash
# Optimize PATH in WSL with selective path filtering to avoid conflicts

# Save original PATH
original_path="$PATH"

# Filter out problematic Windows paths that cause conflicts
# This is more selective than completely disabling Windows paths
filtered_path=$(echo "$original_path" | \
  sed -e 's%:/mnt/c/Program Files/nodejs[^:]*%%g' \
  -e 's%:/mnt/c/Users/.*/AppData/Roaming/npm%%g' \
  -e 's%:/mnt/c/Program Files (x86)/Microsoft SDKs/TypeScript/[^:]*%%g' \
  -e 's%:/mnt/c/Users/.*/AppData/Roaming/nvm%%g')

# Ensure essential Linux paths are at the front of PATH
essential_paths="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
user_paths="$HOME/bin:$HOME/.local/bin"

# Add Node.js from NVM if available (highest priority)
nvm_path=""
if [ -d "$HOME/.nvm" ]; then
  NVM_BIN=$(find "$HOME/.nvm/versions/node" -maxdepth 2 -name bin -type d 2>/dev/null | sort -r | head -n 1)
  if [ -n "$NVM_BIN" ]; then
    nvm_path="$NVM_BIN:"
  fi
fi

# Rebuild PATH with Linux paths prioritized
export PATH="${nvm_path}${user_paths}:${essential_paths}:${filtered_path}"

# Ensure we use the Linux version of common tools that might be duplicated
# This explicitly overrides any PATH settings for critical commands
alias git='/usr/bin/git'
alias python3='/usr/bin/python3'

# Explicitly handle Node.js and npm to fix Claude Code issues
if [ -d "$HOME/.nvm" ]; then
  # We use nvm, so make sure we're using its version of node/npm
  alias node="$HOME/.nvm/versions/node/$(ls $HOME/.nvm/versions/node/ 2>/dev/null | sort -r | head -n 1)/bin/node 2>/dev/null || /usr/bin/node"
  alias npm="$HOME/.nvm/versions/node/$(ls $HOME/.nvm/versions/node/ 2>/dev/null | sort -r | head -n 1)/bin/npm 2>/dev/null || /usr/bin/npm"
  
  # Also set npm config to ensure it uses Linux
  if command -v npm >/dev/null 2>&1; then
    npm config set os linux >/dev/null 2>&1
  fi
else
  # Fall back to system node if available
  if [ -f "/usr/bin/node" ]; then
    alias node="/usr/bin/node"
    alias npm="/usr/bin/npm"
  fi
fi

# Check for Claude Code path issues
if command -v claude >/dev/null 2>&1; then
  if [[ "$(which claude)" == *"/mnt/c/"* ]]; then
    echo "Warning: Claude is using Windows installation. Use 'npm install -g @anthropic-ai/claude-code --no-os-check' to reinstall."
  fi
fi

# Verify our Node.js is from WSL, not Windows
if command -v node >/dev/null 2>&1; then
  if [[ "$(which node)" == *"/mnt/c/"* ]]; then
    echo "Warning: Using Windows Node.js. This can cause issues with WSL tools like Claude Code."
    echo "Consider running: source $HOME/dev-env/bin/nvm-init.sh"
  fi
fi
EOL
    check_error "Failed to create wsl-path-fix.sh"
    chmod +x "$SETUP_DIR/configs/wsl/wsl-path-fix.sh"

    # Windows open script
    print_step "Creating winopen utility..."
    cat > "$SETUP_DIR/configs/wsl/winopen" << 'EOL'
#!/bin/bash
# Open current directory or specified path in Windows Explorer

path_to_open="${1:-.}"
windows_path=$(wslpath -w "$(realpath "$path_to_open")")
explorer.exe "$windows_path"
EOL
    check_error "Failed to create winopen script"
    chmod +x "$SETUP_DIR/configs/wsl/winopen"

    # Clipboard utility
    print_step "Creating clipboard utility..."
    cat > "$SETUP_DIR/configs/wsl/clip-copy" << 'EOL'
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
    check_error "Failed to create clip-copy script"
    chmod +x "$SETUP_DIR/configs/wsl/clip-copy"

    # WSL config
    print_step "Creating WSL config..."
    cat > "$SETUP_DIR/configs/wsl/wslconfig" << 'EOL'
[wsl2]
memory=6GB
processors=4
swap=2GB
localhostForwarding=true
kernelCommandLine=sysctl.vm.swappiness=10
EOL
    check_error "Failed to create wslconfig file"
    
    print_success "WSL utilities setup completed"
}

# Setup Zsh configuration file
setup_zshrc() {
    print_header "Creating Zsh configuration file"
    print_step "Creating Zsh configuration..."
    
    cat > "$SETUP_DIR/configs/zsh/zshrc" << 'EOL'
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

# NVM setup - using our custom script for consistency
if [ -f "$HOME/dev-env/bin/nvm-init.sh" ]; then
  source "$HOME/dev-env/bin/nvm-init.sh"
else
  # Fallback to direct NVM setup if the script doesn't exist yet
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
fi

# Initialize zoxide (smart cd command)
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
fi

# FZF Configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Run neofetch at startup - explicitly use the full path to ensure Linux version is used
if [ -f "/usr/bin/neofetch" ]; then
  /usr/bin/neofetch
else
  echo "Neofetch not found at /usr/bin/neofetch"
fi

# Show welcome message with helpful links
if [ -f "$HOME/dev-env/bin/welcome-message.sh" ]; then
  source "$HOME/dev-env/bin/welcome-message.sh"
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
alias glog='git log --oneline --graph'

# Tmux aliases
alias t='tmux'
alias ta='tmux attach -t'
alias tn='tmux new -s'
alias tl='tmux ls'

# Project navigation
alias proj='cd ~/dev && cd $(find . -maxdepth 2 -type d -not -path "*/\.*" | fzf)'

# WSL-specific aliases
alias explorer='explorer.exe'
alias winopen='~/bin/winopen'
alias clip='~/bin/clip-copy'

# Fix WSL path issues (use our script)
if [ -f ~/bin/wsl-path-fix.sh ]; then
  source ~/bin/wsl-path-fix.sh
fi

# Edit config function - makes it easy to edit your configs
editconfig() {
  local configs=(
    "zsh:$HOME/dev-env/configs/zsh/zshrc"
    "tmux:$HOME/dev-env/configs/tmux/tmux.conf"
    "nvim:$HOME/dev-env/configs/nvim/custom/init.lua"
    "ansible:$HOME/dev-env/ansible/setup.yml"
    "git:$HOME/dev-env/configs/git/gitconfig"
  )
  
  local selected=$(printf "%s\n" "${configs[@]}" | cut -d ':' -f 1 | fzf --prompt="Select config to edit: ")
  
  if [[ -n $selected ]]; then
    local file=$(printf "%s\n" "${configs[@]}" | grep "^$selected:" | cut -d ':' -f 2)
    if [ -f "$file" ]; then
      $EDITOR "$file"
      echo "Don't forget to run ~/dev-env/update.sh to apply changes"
    else
      echo "Config file not found: $file"
    fi
  fi
}

# Add the editconfig function to your command palette
alias ec='editconfig'

# Create a new project with a standard structure
newproject() {
  if [ -z "$1" ]; then
    echo "Usage: newproject <project-name> [<template>]"
    echo "Available templates: node, python, web (default: basic)"
    return 1
  fi
  
  local project_name="$1"
  local template="${2:-basic}"
  local project_dir="$HOME/dev/$project_name"
  
  if [ -d "$project_dir" ]; then
    echo "Error: Project directory $project_dir already exists"
    return 1
  fi
  
  mkdir -p "$project_dir"
  cd "$project_dir" || return
  
  # Create basic structure
  mkdir -p src docs tests
  touch README.md
  
  # Create template-specific files
  case "$template" in
    node)
      echo "Creating Node.js project: $project_name"
      echo '{"name":"'$project_name'","version":"1.0.0","description":"","main":"index.js","scripts":{"test":"echo \"Error: no test specified\" && exit 1"},"keywords":[],"author":"","license":"ISC"}' > package.json
      mkdir -p src/{controllers,models,routes}
      touch src/index.js
      touch .gitignore
      echo -e "node_modules/\ndist/\n.env\n" > .gitignore
      ;;
      
    python)
      echo "Creating Python project: $project_name"
      mkdir -p "$project_name"
      touch "$project_name/__init__.py"
      touch setup.py
      echo -e "import setuptools\n\nsetuptools.setup(\n    name=\"$project_name\",\n    version=\"0.1.0\",\n    packages=setuptools.find_packages(),\n)" > setup.py
      touch .gitignore
      echo -e "__pycache__/\n*.py[cod]\n*$py.class\n.env\nvenv/\n.pytest_cache/\n" > .gitignore
      ;;
      
    web)
      echo "Creating web project: $project_name"
      mkdir -p src/{css,js,assets}
      touch src/index.html
      touch src/css/style.css
      touch src/js/main.js
      echo -e "<!DOCTYPE html>\n<html lang=\"en\">\n<head>\n    <meta charset=\"UTF-8\">\n    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">\n    <title>$project_name</title>\n    <link rel=\"stylesheet\" href=\"css/style.css\">\n</head>\n<body>\n    <h1>$project_name</h1>\n    \n    <script src=\"js/main.js\"></script>\n</body>\n</html>" > src/index.html
      ;;
      
    *)
      echo "Creating basic project: $project_name"
      ;;
  esac
  
  # Initialize git
  git init
  
  echo "Project created at: $project_dir"
  echo "To get started:"
  echo "  cd $project_dir"
  echo "  nvim ."
}
EOL
    check_error "Failed to create Zsh configuration file"
    
    print_success "Zsh configuration file created"
}

# Setup Node.js and npm via NVM (properly configured for WSL)
setup_nodejs() {
    print_header "Setting up Node.js via NVM"
    
    if [ ! -d "$HOME/.nvm" ]; then
        print_step "Installing NVM (Node Version Manager)..."
        # Install development tools needed for building Node.js
        sudo apt install -y build-essential libssl-dev
        # Install NVM
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
        check_error "Failed to install NVM"
        
        # Initialize NVM in current shell
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        print_step "Installing latest LTS version of Node.js..."
        nvm install --lts
        check_error "Failed to install Node.js"
        
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
            check_error "Failed to install Node.js"
            nvm alias default node
        else
            print_step "Node.js is already installed: $(node --version)"
        fi
    fi
    
    # Create NVM initialization script for consistent access
    print_step "Creating NVM initialization script..."
    cat > "$SETUP_DIR/bin/nvm-init.sh" << 'EOFINNER'
#!/bin/bash
# Initialize NVM and set up Node.js path
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Make sure Node.js is properly configured
if command -v nvm >/dev/null 2>&1; then
  # Ensure a Node.js version is active
  if ! command -v node >/dev/null 2>&1; then
    echo "Activating Node.js..."
    nvm use default >/dev/null 2>&1 || nvm use --lts >/dev/null 2>&1
  fi
fi
EOFINNER
    chmod +x "$SETUP_DIR/bin/nvm-init.sh"
    check_error "Failed to create NVM initialization script"

    # Add specific PATH filter for Node.js to .bashrc instead of changing wsl.conf
    if ! grep -q "Filter out Windows Node.js from PATH" ~/.bashrc; then
        print_step "Adding Node.js path filter to ~/.bashrc..."
        cat >> ~/.bashrc << 'EOFINNER'

# Filter out Windows Node.js from PATH to prevent conflicts
# This is a safer approach than disabling all Windows paths
PATH=$(echo "$PATH" | sed -e 's%:/mnt/c/Program Files/nodejs%%g')
PATH=$(echo "$PATH" | sed -e 's%:/mnt/c/Program Files/nodejs/%%g')
PATH=$(echo "$PATH" | sed -e 's%:/mnt/c/Users/.*/AppData/Roaming/npm%%g')

# Ensure WSL Node.js is used
if [ -d "$HOME/.nvm" ]; then
  NVM_BIN=$(find "$HOME/.nvm/versions/node" -maxdepth 2 -name bin -type d 2>/dev/null | sort -r | head -n 1)
  if [ -n "$NVM_BIN" ]; then
    export PATH="$NVM_BIN:$PATH"
  fi
fi
EOFINNER
        check_error "Failed to update .bashrc with Node.js path filter"
    fi
    
    print_success "Node.js environment configured successfully"
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
    fi
    
    # Verify we're using the correct (WSL) version of Node.js
    NODE_PATH=$(which node)
    if [[ "$NODE_PATH" == *"/mnt/c/"* ]]; then
        print_warning "Using Windows Node.js ($NODE_PATH). This can cause problems."
        print_warning "Will try to fix by ensuring correct WSL Node.js is used..."
        setup_nodejs
        
        # Re-init NVM to ensure we get the right paths
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        
        # Check again
        NODE_PATH=$(which node)
        if [[ "$NODE_PATH" == *"/mnt/c/"* ]]; then
            print_error "Still using Windows Node.js. Applying selective path filter..."
            # Apply path filter directly
            PATH=$(echo "$PATH" | sed -e 's%:/mnt/c/Program Files/nodejs[^:]*%%g')
            PATH=$(echo "$PATH" | sed -e 's%:/mnt/c/Users/.*/AppData/Roaming/npm%%g')
            
            # Try one more time
            NODE_PATH=$(which node)
            if [[ "$NODE_PATH" == *"/mnt/c/"* ]]; then
                print_error "Unable to use WSL Node.js. Please run setup again after a terminal restart."
                return 1
            fi
        fi
    fi
    
    print_step "Using Node.js: $(node --version) at $NODE_PATH"
    print_step "Using npm: $(npm --version) at $(which npm)"
    
    # Apply WSL-specific workarounds as mentioned in the Claude Code docs
    print_step "Setting npm config for WSL compatibility..."
    npm config set os linux
    
    # Install Claude Code
    print_step "Installing Claude Code..."
    npm install -g @anthropic-ai/claude-code --no-os-check
    check_error "Failed to install Claude Code"
    
    # Verify installation
    if command_exists claude; then
        print_success "Claude Code installed successfully!"
        
        # Add note about usage and troubleshooting
        cat << 'EOFHELP'

Claude Code is now installed! Usage:
- In your project directory, run: claude
- For first-time authorization, run: claude auth login

If you encounter issues:
1. Make sure WSL is using Linux Node.js (not Windows): which node
2. If you see "Node not found" errors, run: source ~/dev-env/bin/nvm-init.sh 
3. Try reinstalling with: npm install -g @anthropic-ai/claude-code --force --no-os-check

For more information, visit: https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview
EOFHELP
    else
        print_warning "Claude Code installation might have issues. Please see troubleshooting steps below:"
        cat << 'EOFTROUBLE'

Troubleshooting Claude Code in WSL:

1. Check your Node.js path:
   - Run: which node
   - It should show a Linux path like /home/username/.nvm/... not a Windows path (/mnt/c/).

2. OS/platform detection issues:
   - Run: npm config set os linux 
   - Install with: npm install -g @anthropic-ai/claude-code --force --no-os-check

3. Path conflicts:
   - Run: source ~/dev-env/bin/nvm-init.sh
   - This script prioritizes the Linux Node.js installation in your PATH

See documentation: https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview
EOFTROUBLE
    fi
    
    # Add tab completion to zshrc if not already there
    if [ -f ~/.zshrc ] && ! grep -q "claude completion" ~/.zshrc; then
        print_step "Adding Claude Code tab completion to Zsh..."
        echo '# Claude Code tab completion' >> ~/.zshrc
        echo 'if command -v claude >/dev/null; then' >> ~/.zshrc
        echo '  eval "$(claude completion zsh)"' >> ~/.zshrc
        echo 'fi' >> ~/.zshrc
    fi
    
    # Add tab completion to bashrc if not already there
    if [ -f ~/.bashrc ] && ! grep -q "claude completion" ~/.bashrc; then
        print_step "Adding Claude Code tab completion to Bash..."
        echo '# Claude Code tab completion' >> ~/.bashrc
        echo 'if command -v claude >/dev/null; then' >> ~/.bashrc
        echo '  eval "$(claude completion bash)"' >> ~/.bashrc
        echo 'fi' >> ~/.bashrc
    fi
    
    print_success "Claude Code setup completed"
}

# Create Claude Code documentation
create_claude_code_docs() {
    print_header "Creating Claude Code documentation"
    
    ensure_dir "$SETUP_DIR/docs"
    
    cat > "$SETUP_DIR/docs/claude-code-guide.md" << 'EOL'
# Claude Code Guide

Claude Code is an AI-assisted coding tool from Anthropic that helps you write, understand, and improve your code. This guide covers basic usage and troubleshooting in WSL.

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

4. **Improve code**:
   - Ask: "How can I make this code more efficient?"
   - Or: "Refactor this to follow best practices"

## Common Commands

- `claude` - Start Claude Code in your project
- `claude auth login` - Authenticate with Anthropic
- `claude auth logout` - Log out
- `claude --help` - Show help information

## WSL-Specific Issues

If you encounter problems running Claude Code in WSL:

### Node.js Path Issues

If you see "exec: node: not found" when running claude:

1. Check which Node.js you're using:
   ```bash
   which node
   which npm
   ```
   
   These should point to Linux paths (starting with /usr/ or ~/.nvm/), not Windows paths (starting with /mnt/c/).

2. If using Windows Node.js:
   ```bash
   # Initialize NVM to use WSL Node.js
   source ~/dev-env/bin/nvm-init.sh
   ```

3. Apply the path fix script:
   ```bash
   source ~/bin/wsl-path-fix.sh
   ```

### OS Detection Issues

If Claude Code fails to install or run due to platform issues:

1. Set npm to use Linux:
   ```bash
   npm config set os linux
   ```

2. Reinstall with force flag:
   ```bash
   npm install -g @anthropic-ai/claude-code --force --no-os-check
   ```

### WSL Path Configuration

Our setup uses selective path filtering that:
- Keeps Windows tools accessible (like `code .` for VS Code)
- Prevents conflicts with Node.js by filtering Windows Node.js paths
- Prioritizes Linux tools over Windows equivalents

You don't need to restart WSL after installation, and Windows tools will still work!

## For More Information

Visit the [official Claude Code documentation](https://docs.anthropic.com/en/docs/agents-and-tools/claude-code/overview)
EOL
    check_error "Failed to create Claude Code documentation"
    
    print_success "Claude Code documentation created"
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

# Error handling function
check_error() {
  if [ $? -ne 0 ]; then
    echo -e "${RED}ERROR: $1${NC}"
    echo -e "${YELLOW}Would you like to continue anyway? (y/n)${NC}"
    read -r response
    if [[ "$response" != "y" ]]; then
      echo "Setup aborted."
      exit 1
    fi
  fi
}

# Create directory if it doesn't exist
ensure_dir() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    check_error "Failed to create directory: $1"
  fi
}

# Refresh PATH
refresh_path() {
  export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
  hash -r
}

# Make sure PATH includes local bin directory
refresh_path

# Get directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Navigate to our environment directory
cd "$SCRIPT_DIR" || { echo -e "${RED}Failed to change directory${NC}"; exit 1; }

# Check for custom variables
if [ -f "config.env" ]; then
  source config.env
fi

# Update Neovim configuration
echo -e "${BLUE}Updating Neovim configuration...${NC}"
# Ensure directory exists
ensure_dir ~/.config/nvim/lua/custom
cp "$SCRIPT_DIR/configs/nvim/custom/init.lua" ~/.config/nvim/lua/custom/init.lua
check_error "Failed to update Neovim configuration"

# Update WSL utilities
echo -e "${BLUE}Updating WSL utilities...${NC}"
# Ensure bin directory exists
ensure_dir ~/bin

# Copy and make executable
cp "$SCRIPT_DIR/configs/wsl/wsl-path-fix.sh" ~/bin/
cp "$SCRIPT_DIR/configs/wsl/winopen" ~/bin/
cp "$SCRIPT_DIR/configs/wsl/clip-copy" ~/bin/
chmod +x ~/bin/wsl-path-fix.sh ~/bin/winopen ~/bin/clip-copy
check_error "Failed to update WSL utilities"

# Install Neovim providers using virtual environment
echo -e "${BLUE}Installing Neovim providers...${NC}"
ensure_dir ~/.config/nvim/venv

# Check if python3-venv is installed
if ! dpkg -l | grep -q python3-venv; then
  echo -e "${YELLOW}Python3-venv package is required but not installed${NC}"
  echo -e "${YELLOW}Installing python3-venv...${NC}"
  sudo apt update
  sudo apt install -y python3-venv python3-pip
  check_error "Failed to install python3-venv"
fi
  
# Check if we need to create a virtual environment
if [ ! -f ~/.config/nvim/venv/bin/python ]; then
  # Create virtual environment
  python3 -m venv ~/.config/nvim/venv
  check_error "Failed to create Python virtual environment"
fi

# Install Python provider in the virtual environment
~/.config/nvim/venv/bin/pip install pynvim
check_error "Failed to install Python provider for Neovim"

# Configure Neovim to use the virtual environment
mkdir -p ~/.config/nvim/after/plugin
cat > ~/.config/nvim/after/plugin/python-provider.lua << 'EOFINNER'
-- Configure Neovim Python provider to use virtual environment
vim.g.python3_host_prog = vim.fn.expand('~/.config/nvim/venv/bin/python')
EOFINNER

# Install Node.js provider if nvm is available
if [ -f "$HOME/.nvm/nvm.sh" ]; then
  echo -e "${BLUE}Installing Node.js provider...${NC}"
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  npm install -g neovim
else
  echo -e "${YELLOW}NVM not found, skipping Node.js provider installation${NC}"
fi

# Configure nvim-treesitter
mkdir -p ~/.config/nvim/after/plugin
cat > ~/.config/nvim/after/plugin/treesitter-config.lua << 'EOFINNER'
-- Configure nvim-treesitter to install without prompts
require('nvim-treesitter.configs').setup({
  auto_install = true,
  ensure_installed = { "lua", "vim", "vimdoc", "javascript", "typescript", "python", "rust" },
  sync_install = false,
})
EOFINNER

echo -e "${GREEN}Neovim providers and language parsers configuration completed${NC}"
echo -e "${YELLOW}You can verify the installation by running :checkhealth in Neovim${NC}"

# Update the PATH in current shell and .bashrc if not already set
if ! grep -q 'PATH="$HOME/bin:$HOME/.local/bin:$PATH"' ~/.bashrc; then
  echo 'export PATH="$HOME/bin:$HOME/.local/bin:$PATH"' >> ~/.bashrc
  echo -e "${YELLOW}Added PATH update to ~/.bashrc${NC}"
  echo -e "${YELLOW}Run 'source ~/.bashrc' to apply changes to current session${NC}"
fi

# Run our Ansible playbook
echo -e "${BLUE}Updating your development environment...${NC}"
ansible-playbook -i localhost, "$SCRIPT_DIR/ansible/setup.yml"
check_error "Ansible playbook execution failed"

# Run the fix-neovim script to ensure all Neovim components are properly set up
if [ -f "$SCRIPT_DIR/bin/fix-neovim.sh" ]; then
  echo -e "${BLUE}Ensuring Neovim is properly configured...${NC}"
  "$SCRIPT_DIR/bin/fix-neovim.sh"
  check_error "Failed to run Neovim fix script"
fi

# Check for Claude Code updates
if command -v claude >/dev/null 2>&1; then
  echo -e "${BLUE}Updating Claude Code...${NC}"
  
  # Make sure we're using the correct Node.js
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  
  # Set npm config for WSL compatibility
  npm config set os linux
  
  # Update Claude Code
  npm update -g @anthropic-ai/claude-code --no-os-check
  echo -e "${GREEN}Claude Code updated${NC}"
else
  echo -e "${YELLOW}Claude Code not found, skipping update${NC}"
  echo -e "${YELLOW}You can install it with: npm install -g @anthropic-ai/claude-code --no-os-check${NC}"
fi

echo -e "${GREEN}Environment updated successfully!${NC}"
echo -e "${YELLOW}Remember: You can customize any aspect by editing files in the configs/ directory${NC}"
echo -e "\n${BLUE}To use the custom commands:${NC}"
echo -e "  - Make sure to restart your terminal or run: source ~/.bashrc"
echo -e "  - Then try commands like 'winopen', 'clip', etc."
echo -e "  - Read the documentation at ~/dev-env/docs/ for more information"
ENDOFFILE
    check_error "Failed to create update script"
    chmod +x "$SETUP_DIR/update.sh"
    check_error "Failed to make update script executable"
    
    print_success "Update script created successfully"
}

# Create final completion message
display_completion_message() {
    print_title "Setup Complete!"
    echo -e "${GREEN}Your WSL developer environment is ready to use!${NC}"
    echo -e "\n${BLUE}To make the custom commands immediately available:${NC}"
    echo -e "  ${YELLOW}source ~/.bashrc${NC}"
    
    echo -e "\n${BLUE}Path Compatibility:${NC}"
    echo -e "  ${CYAN}We've used a selective path filtering approach that keeps Windows commands${NC}"
    echo -e "  ${CYAN}accessible while preventing conflicts with Node.js and npm.${NC}"
    echo -e "  ${CYAN}This means 'code .' and other Windows commands will still work!${NC}"
    
    echo -e "\n${BLUE}Beginner-Friendly Features:${NC}"
    echo -e "1. ${CYAN}Interactive startup screen${NC} - Just type ${YELLOW}nvim${NC} to see it"
    echo -e "2. ${CYAN}Press F1 in Neovim${NC} for a quick reference guide"
    echo -e "3. ${CYAN}Create new projects easily${NC} with ${YELLOW}newproject name template${NC}"
    echo -e "4. ${CYAN}Read the beginner's guide:${NC} ${YELLOW}nvim ~/dev-env/docs/beginners-guide.md${NC}"
    echo -e "5. ${CYAN}Claude Code AI assistant${NC} - Just type ${YELLOW}claude${NC} in your project directory"
    
    echo -e "\n${BLUE}Next steps:${NC}"
    echo -e "1. Run the update script to install additional tools: ${YELLOW}~/dev-env/update.sh${NC}"
    echo -e "2. Read the getting started guide: ${YELLOW}nvim ~/dev-env/docs/getting-started.md${NC}"
    echo -e "3. Consider changing your default shell to Zsh: ${YELLOW}chsh -s \$(which zsh)${NC}"
    echo -e "4. Explore the Neovim guides: ${YELLOW}nvim ~/dev-env/docs/neovim-guide.md${NC}"
    echo -e "5. Authorize Claude Code: ${YELLOW}claude auth login${NC}"
    
    echo -e "\n${PURPLE}Neovim has been configured with a pure black Rose Pine theme!${NC}"
    echo -e "\n${GREEN}Happy learning and coding!${NC}"
}

# --- Script execution ---
print_title "Beginner-Friendly WSL Development Environment Setup v$SCRIPT_VERSION"
echo -e "${GREEN}This script will set up a complete development environment optimized for WSL Debian${NC}"
echo -e "${GREEN}Perfect for beginners - everything you need to start coding with modern tools${NC}"

# Setup workspace first
setup_workspace

# Update system and install dependencies
update_system
install_core_deps

# Install and configure Neofetch 
install_neofetch

# Install Neovim
install_neovim

# Setup Neovim configuration
setup_nvim_config

# Setup Ansible
setup_ansible

# Setup Zsh and related configs
setup_zsh
setup_zshrc 

# Setup tmux
setup_tmux

# Setup WSL utilities
setup_wsl_utilities

# Setup Node.js and npm via NVM (properly configured for WSL)
setup_nodejs

# Setup Claude Code from Anthropic
setup_claude_code

# Create Claude Code documentation
create_claude_code_docs

# Create update script
create_update_script

# Final setup and display completion message
display_completion_message
