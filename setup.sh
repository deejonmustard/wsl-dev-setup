#!/bin/bash

# Ultimate WSL Development Environment Setup
# A beginner-friendly, modular development environment for WSL Debian

# Color definitions
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'

# Fancy title function
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

# Print colored section headers
print_header() {
  echo -e "\n${CYAN}==== $1 ====${NC}"
}

# Print step information
print_step() {
    echo -e "${BLUE}→ $1${NC}"
}

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

# Check if a command exists
command_exists() {
  command -v "$1" &> /dev/null
}

# Refresh PATH and available commands
refresh_path() {
  export PATH="$HOME/.local/bin:/usr/local/bin:$HOME/bin:$PATH"
  hash -r
}

SCRIPT_VERSION="0.1.0"
print_title "Ultimate WSL Development Environment Setup v$SCRIPT_VERSION"
echo -e "${GREEN}This script will set up a developer environment optimized for WSL Debian${NC}"
echo -e "${GREEN}You can easily modify any part of this setup later${NC}"

# Create our workspace structure first - before any other operations
print_header "Creating Workspace Structure"
print_step "Setting up directory structure..."

# Main directory structure
ensure_dir ~/dev-env
ensure_dir ~/.local/bin
ensure_dir ~/bin
ensure_dir ~/tools

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

# Update system
print_header "Updating System Packages"
print_step "Updating package lists..."
sudo apt update
check_error "Failed to update package lists"

print_step "Upgrading packages..."
sudo apt upgrade -y
check_error "Failed to upgrade packages"

# Ensure basic dependencies are installed
print_header "Installing core dependencies"
print_step "Installing essential packages..."
sudo apt install -y curl wget git python3 python3-pip unzip build-essential
check_error "Failed to install core dependencies"

# Make sure PATH includes our local bin directories
refresh_path

# Install Neovim
print_header "Installing Neovim"
if ! command_exists nvim; then
  print_step "Downloading Neovim..."
  
  # Create temporary directory for installation
  TEMP_DIR=$(mktemp -d)
  check_error "Failed to create temporary directory for Neovim installation"
  
  cd "$TEMP_DIR" || { echo -e "${RED}Failed to change directory to $TEMP_DIR${NC}"; exit 1; }
  
  # Download Neovim AppImage
  wget -q https://github.com/neovim/neovim/releases/download/v0.10.0/nvim.appimage
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
    echo -e "${RED}Neovim installation verification failed. Path may not be updated.${NC}"
    echo -e "${YELLOW}Please try running: hash -r${NC}"
    hash -r
    if ! command_exists nvim; then
      echo -e "${RED}Neovim still not found. Will continue but you may need to restart your terminal.${NC}"
    fi
  else
    nvim --version
    echo -e "${GREEN}Neovim installed successfully${NC}"
  fi
else
  print_step "Neovim is already installed"
  nvim --version
fi

# Install Kickstart Neovim configuration
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

-- ================= COMMENTS =================
-- This is a good place to add your own customizations as you learn
-- -- For example:
-- -- 1. Add custom plugin configurations
-- -- 2. Define new keymappings for your workflow
-- -- 3. Set up language-specific settings
-- 
-- -- Try adding a line below to see the effect:
-- -- vim.cmd('colorscheme tokyonight-night')
EOL
check_error "Failed to create custom Neovim configuration file"

# Copy the custom configuration to Neovim
cp "$SETUP_DIR/configs/nvim/custom/init.lua" ~/.config/nvim/lua/custom/init.lua
check_error "Failed to copy custom Neovim configuration"

echo -e "${GREEN}Custom Neovim configuration updated${NC}"

# Install Ansible (as recommended by ThePrimeagen for reproducible environments)
print_header "Setting up Ansible"
if ! command_exists ansible; then
  print_step "Installing Ansible..."
  sudo apt install -y ansible
  check_error "Failed to install Ansible"
  echo -e "${GREEN}Ansible installed successfully!${NC}"
else
  print_step "Ansible is already installed"
fi

# Download our Ansible playbooks
print_header "Creating configuration files"
print_step "Setting up configuration files and directories..."

# Create README explaining the setup
cat > "$SETUP_DIR/README.md" << 'EOL'
# WSL Development Environment

This directory contains your development environment setup:

- `ansible/`: Playbooks for installing and configuring tools
- `configs/`: Configuration files for your development tools
- `bin/`: Useful scripts and utilities
- `docs/`: Documentation and guides

## How to Use This Setup

### Installing/Updating Tools
Run: `./update.sh`

### Customizing Your Environment
1. Edit files in the `configs/` directory
2. Run `./update.sh` to apply changes

### Adding New Tools
1. Edit the playbooks in `ansible/`
2. Run `./update.sh` to apply changes
EOL
check_error "Failed to create README file"

# Create main playbook
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

# Create update script with fixed paths
cat > "$SETUP_DIR/update.sh" << 'EOL'
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
  export PATH="$HOME/.local/bin:/usr/local/bin:$HOME/bin:$PATH"
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

# Run our Ansible playbook
echo -e "${BLUE}Updating your development environment...${NC}"
ansible-playbook -i localhost, "$SCRIPT_DIR/ansible/setup.yml"
check_error "Ansible playbook execution failed"

echo -e "${GREEN}Environment updated successfully!${NC}"
echo -e "${YELLOW}Remember: You can customize any aspect by editing files in the configs/ directory${NC}"
EOL
check_error "Failed to create update script"
chmod +x "$SETUP_DIR/update.sh"
check_error "Failed to make update script executable"

# Create core-tools role
ensure_dir "$SETUP_DIR/ansible/roles/core-tools/tasks"
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
      - ripgrep          # Better grep (rg)
      - fd-find          # Better find (fd)
      - fzf              # Fuzzy finder
      - tmux             # Terminal multiplexer
      - zsh              # Better shell
      
      # Development essentials
      - build-essential  # Compilation tools
      - git              # Version control
      - curl             # Transfer data
      - wget             # Download files
      - unzip            # Extract archives
      - python3-pip      # Python package manager
      
      # Additional useful tools
      - jq               # JSON processor
      - bat              # Better cat with syntax highlighting
      - htop             # Interactive process viewer
      - stow             # Symlink farm manager for configs
      - ninja-build      # Build system
      - gettext          # Internationalization utilities
      - cmake            # Cross-platform build system
      - pkg-config       # Package compiler/linker metadata tool
    state: present

- name: Ensure local bin directory exists
  file:
    path: ~/.local/bin
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
EOL
check_error "Failed to create core-tools role"

# Create shell role with fixed paths
ensure_dir "$SETUP_DIR/ansible/roles/shell/tasks"
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

# Create tmux role with fixed paths
ensure_dir "$SETUP_DIR/ansible/roles/tmux/tasks"
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

# Create WSL-specific role with fixed paths
ensure_dir "$SETUP_DIR/ansible/roles/wsl-specific/tasks"
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

# Create git-config role with fixed paths
ensure_dir "$SETUP_DIR/ansible/roles/git-config/tasks"
cat > "$SETUP_DIR/ansible/roles/git-config/tasks/main.yml" << 'EOL'
---
# Git configuration setup

- name: Check if git user name is already configured
  command: git config --global --get user.name
  register: git_user_name
  ignore_errors: true
  changed_when: false

- name: Check if git user email is already configured
  command: git config --global --get user.email
  register: git_user_email
  ignore_errors: true
  changed_when: false

- name: Get user info for Git configuration
  block:
    - name: Ask for git username
      pause:
        prompt: "Enter your Git username"
      register: git_username_input
      when: git_user_name.rc != 0

    - name: Ask for git email
      pause:
        prompt: "Enter your Git email"
      register: git_email_input
      when: git_user_email.rc != 0
  when: git_user_name.rc != 0 or git_user_email.rc != 0

- name: Configure Git
  block:
    - name: Set git username
      command: git config --global user.name "{{ git_username_input.user_input }}"
      when: git_user_name.rc != 0

    - name: Set git email
      command: git config --global user.email "{{ git_email_input.user_input }}"
      when: git_user_email.rc != 0
  when: git_user_name.rc != 0 or git_user_email.rc != 0

- name: Configure helpful Git defaults
  command: "{{ item }}"
  loop:
    - git config --global core.editor "nvim"
    - git config --global init.defaultBranch main
    - git config --global pull.rebase false
    - git config --global color.ui auto
    - git config --global push.default simple
    - git config --global core.autocrlf input

- name: Copy gitignore_global file
  copy:
    src: "{{ playbook_dir }}/../configs/git/gitignore_global"
    dest: ~/.gitignore_global
    mode: '0644'
  ignore_errors: yes

- name: Set global gitignore
  command: git config --global core.excludesfile ~/.gitignore_global
EOL
check_error "Failed to create git-config role"

# Create nodejs role
ensure_dir "$SETUP_DIR/ansible/roles/nodejs/tasks"
cat > "$SETUP_DIR/ansible/roles/nodejs/tasks/main.yml" << 'EOL'
---
# Node.js and npm setup

- name: Check if Node.js is installed
  command: which node
  register: node_installed
  ignore_errors: true
  changed_when: false

- name: Install Node.js using nvm
  block:
    - name: Download nvm
      shell: >
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
      args:
        creates: "{{ ansible_env.HOME }}/.nvm/nvm.sh"

    - name: Install latest LTS version of Node.js
      shell: >
        export NVM_DIR="$HOME/.nvm" && 
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && 
        nvm install --lts
      args:
        executable: /bin/bash
  when: node_installed.rc != 0

- name: Install global npm packages
  shell: >
    export NVM_DIR="$HOME/.nvm" && 
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && 
    npm install -g {{ item }}
  loop:
    - typescript
    - eslint
    - prettier
  args:
    executable: /bin/bash
EOL
check_error "Failed to create nodejs role"

# Create Zsh configuration file
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
export PATH="$HOME/.local/bin:/usr/local/bin:$HOME/bin:$PATH"

# NVM setup
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Initialize zoxide (smart cd command)
if command -v zoxide >/dev/null; then
  eval "$(zoxide init zsh)"
fi

# FZF Configuration
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

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
EOL
check_error "Failed to create zsh configuration"

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

# Create WSL utilities
# Path fix script
cat > "$SETUP_DIR/configs/wsl/wsl-path-fix.sh" << 'EOL'
#!/bin/bash
# Optimize PATH in WSL to prioritize Linux binaries and improve performance

# Clean PATH to remove unnecessary Windows paths
clean_path=$(echo $PATH | tr ':' '\n' | grep -v "/mnt/" | tr '\n' ':' | sed 's/:$//')

# Add only essential Windows paths (at the end)
clean_path="$clean_path:/mnt/c/Windows/System32"

# Export the optimized PATH
export PATH="$clean_path"

# Also unset any Windows variables that might cause issues
unset PYTHONPATH
unset CLASSPATH
EOL
check_error "Failed to create wsl-path-fix.sh"
chmod +x "$SETUP_DIR/configs/wsl/wsl-path-fix.sh"

# Windows open script
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
cat > "$SETUP_DIR/configs/wsl/wslconfig" << 'EOL'
[wsl2]
memory=6GB
processors=4
swap=2GB
localhostForwarding=true
kernelCommandLine=sysctl.vm.swappiness=10
EOL
check_error "Failed to create wslconfig file"

# Create Git config template
cat > "$SETUP_DIR/configs/git/gitconfig" << 'EOL'
# This is a template gitconfig that will be customized by the Ansible playbook
# You can add additional Git configurations here

[core]
  editor = nvim
  autocrlf = input
  whitespace = trailing-space,space-before-tab
  excludesfile = ~/.gitignore_global

[color]
  ui = auto

[init]
  defaultBranch = main

[pull]
  rebase = false

[push]
  default = simple

[alias]
  st = status
  co = checkout
  br = branch
  ci = commit
  unstage = reset HEAD --
  last = log -1 HEAD
  visual = !gitk
  hist = log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short
EOL
check_error "Failed to create Git config template"

# Create a gitignore_global file
cat > "$SETUP_DIR/configs/git/gitignore_global" << 'EOL'
# Global gitignore file

# OS specific
.DS_Store
Thumbs.db
desktop.ini

# Editor files
.vscode/
.idea/
*.swp
*.swo
*~

# Logs and databases
*.log
*.sqlite

# Build directories
/build/
/dist/
/out/

# Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Python
__pycache__/
*.py[cod]
*$py.class
.env
.venv
env/
venv/
ENV/

# Compiled files
*.o
*.out
*.class
EOL
check_error "Failed to create global gitignore file"

# Create a guide for editing configs
ensure_dir "$SETUP_DIR/docs"
cat > "$SETUP_DIR/docs/editing-configs.md" << 'EOL'
# How to Edit Your Development Environment

This guide shows you how to customize your WSL development environment using the terminal.

## The Quick Way: Using the `ec` Command

The easiest way to edit your configurations is using the built-in `ec` (edit config) command:

1. Open your terminal
2. Type `ec` and press Enter
3. Select the configuration you want to edit from the menu
4. Make your changes and save
5. Run `~/dev-env/update.sh` to apply your changes

## Manual Editing

All configuration files are stored in the `~/dev-env/configs/` directory:

### Editing Zsh Configuration
```bash
nvim ~/dev-env/configs/zsh/zshrc
```

### Editing Git Configuration
```bash
nvim ~/dev-env/configs/git/gitconfig
```

### Editing Neovim Configuration
```bash
nvim ~/dev-env/configs/nvim/custom/init.lua
```

### Editing Tmux Configuration
```bash
nvim ~/dev-env/configs/tmux/tmux.conf
```

## Applying Changes

After making changes to any configuration file, run the update script:

```bash
~/dev-env/update.sh
```

This will copy your configurations to the appropriate locations and run the Ansible playbooks.
EOL
check_error "Failed to create editing-configs.md"

# Create a development cheatsheet
cat > "$SETUP_DIR/docs/dev-cheatsheet.md" << 'EOL'
# WSL Development Environment Cheatsheet

## Common Commands

### Navigation
- `z [keyword]` - Jump to frequently accessed directory
- `..` - Go up one directory
- `...` - Go up two directories
- `proj` - Browse and select projects in ~/dev

### File Operations
- `vim` or `v` - Open Neovim
- `fd [pattern]` - Find files (better alternative to find)
- `rg [pattern]` - Search within files (better grep)
- `ll` - List files with details

### Git
- `gs` - Git status
- `ga` - Git add
- `gc "message"` - Git commit with message
- `gp` - Git push
- `gl` - Git pull
- `glog` - Pretty git log with graph

### Tmux
- `t` - Start tmux
- `ta [name]` - Attach to session
- `tn [name]` - New session
- `tl` - List sessions

### WSL-Windows Integration
- `winopen` - Open current directory in Windows Explorer
- `clip` - Copy to Windows clipboard

## Neovim Shortcuts
- `<Space>` - Leader key for commands
- `<Space>w` - Save file 
- `<Space>q` - Quit
- `<Space>e` - File explorer
- `<Space>ff` - Find files
- `<Space>fg` - Find text in files
- `<C-h/j/k/l>` - Navigate between windows

## Tmux Shortcuts
- `Ctrl+a` - Prefix key
- `Prefix |` - Split vertically
- `Prefix -` - Split horizontally
- `Prefix c` - New window
- `Prefix h/j/k/l` - Navigate panes
- `Prefix d` - Detach from session
- `Prefix r` - Reload config
EOL
check_error "Failed to create dev-cheatsheet.md"

# Make scripts in ~/bin executable immediately
cp "$SETUP_DIR/configs/wsl/wsl-path-fix.sh" ~/bin/
cp "$SETUP_DIR/configs/wsl/winopen" ~/bin/
cp "$SETUP_DIR/configs/wsl/clip-copy" ~/bin/
chmod +x ~/bin/wsl-path-fix.sh ~/bin/winopen ~/bin/clip-copy
check_error "Failed to copy and make WSL utilities executable"

print_title "Initial Setup Complete!"
echo -e "${GREEN}Your WSL developer environment is ready to use!${NC}"
echo -e "\n${BLUE}Next steps:${NC}"
echo -e "1. Run the update script to install additional tools: ${YELLOW}~/dev-env/update.sh${NC}"
echo -e "2. After installation completes, restart your terminal"
echo -e "3. Consider changing your default shell to Zsh: ${YELLOW}chsh -s $(which zsh)${NC}"
echo -e "4. Read the cheatsheet at: ${YELLOW}~/dev-env/docs/dev-cheatsheet.md${NC}"
echo -e "\n${GREEN}Happy coding!${NC}"
