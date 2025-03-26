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
  export PATH="$HOME/.local/bin:$HOME/bin:/usr/local/bin:$PATH"
  hash -r
}

# Check if we're already using Zsh
USING_ZSH=0
if [ -n "$ZSH_VERSION" ]; then
  USING_ZSH=1
fi

SCRIPT_VERSION="0.2.0"
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
sudo apt install -y curl wget git python3 python3-pip unzip build-essential file cmake
check_error "Failed to install core dependencies"

# Make sure PATH includes our local bin directories
refresh_path

# Install Neofetch
print_header "Installing Neofetch"
print_step "Installing Neofetch..."
if ! command_exists neofetch; then
  sudo apt install -y neofetch
  check_error "Failed to install Neofetch"
  
  echo -e "${GREEN}Neofetch installed successfully${NC}"
else
  print_step "Neofetch is already installed"
fi

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

-- Add to the top of your custom init.lua file
-- Configure nvim-treesitter to install without prompts
vim.g.treesitter_auto_install = true
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
cat > ~/.config/nvim/after/plugin/python-provider.lua << EOF
-- Configure Neovim Python provider to use virtual environment
vim.g.python3_host_prog = vim.fn.expand('~/.config/nvim/venv/bin/python')
EOF

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
cat > ~/.config/nvim/after/plugin/treesitter-config.lua << EOF
-- Configure nvim-treesitter to install without prompts
require('nvim-treesitter.configs').setup({
  auto_install = true,
  ensure_installed = { "lua", "vim", "vimdoc", "javascript", "typescript", "python", "rust" },
  sync_install = false,
})
EOF

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

echo -e "${GREEN}Environment updated successfully!${NC}"
echo -e "${YELLOW}Remember: You can customize any aspect by editing files in the configs/ directory${NC}"
echo -e "\n${BLUE}To use the custom commands:${NC}"
echo -e "  - Make sure to restart your terminal or run: source ~/.bashrc"
echo -e "  - Then try commands like 'winopen', 'clip', etc."
echo -e "  - Read the documentation at ~/dev-env/docs/ for more information"
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
      - file             # Determine file type
      - neofetch         # System info display
      
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

# Create git-config role with simplified credential handling
ensure_dir "$SETUP_DIR/ansible/roles/git-config/tasks"
cat > "$SETUP_DIR/ansible/roles/git-config/tasks/main.yml" << 'EOL'
---
# Git configuration setup

- name: Ask for git username
  pause:
    prompt: "Enter your Git username (or press Enter to skip)"
  register: git_username_input

- name: Ask for git email
  pause:
    prompt: "Enter your Git email (or press Enter to skip)"
  register: git_email_input

- name: Set git username
  command: git config --global user.name "{{ git_username_input.user_input }}"
  when: git_username_input.user_input != ""

- name: Set git email
  command: git config --global user.email "{{ git_email_input.user_input }}"
  when: git_email_input.user_input != ""

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

# Create nodejs role with simplified installation
ensure_dir "$SETUP_DIR/ansible/roles/nodejs/tasks"
cat > "$SETUP_DIR/ansible/roles/nodejs/tasks/main.yml" << 'EOL'
---
# Node.js and npm setup

- name: Download nvm
  shell: >
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
  args:
    creates: "{{ ansible_env.HOME }}/.nvm/nvm.sh"
  ignore_errors: yes

- name: Install latest LTS version of Node.js
  shell: >
    export NVM_DIR="$HOME/.nvm" && 
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" && 
    nvm install --lts
  args:
    executable: /bin/bash
  ignore_errors: yes

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
  ignore_errors: yes
EOL
check_error "Failed to create nodejs role"

# Create Zsh configuration file with neofetch at startup and quick links
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

# Run neofetch at startup
neofetch

# Print quick links to configuration files and documentation
print_dev_links() {
  echo ""
  echo "💻 Development Environment Quick Links:"
  echo "----------------------------------------"
  echo "📚 Guides:"
  echo "  nvim ~/dev-env/docs/getting-started.md   # Getting started"
  echo "  nvim ~/dev-env/docs/neovim-guide.md      # Neovim guide"
  echo "  nvim ~/dev-env/docs/dev-cheatsheet.md    # Development cheatsheet"
  echo ""
  echo "⚙️  Configs:"
  echo "  nvim ~/.config/nvim/lua/custom/init.lua  # Neovim custom config"
  echo "  nvim ~/dev-env/configs/zsh/zshrc         # Zsh config"
  echo "  nvim ~/dev-env/configs/tmux/tmux.conf    # Tmux config"
  echo ""
  echo "🔄 Update environment: ~/dev-env/update.sh"
  echo "🔍 Edit configs menu:  ec"
  echo "----------------------------------------"
}

# Show quick links
print_dev_links

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

# Create enhanced documentation for beginners
# Create a guide for editing configs
ensure_dir "$SETUP_DIR/docs"
cat > "$SETUP_DIR/docs/getting-started.md" << 'EOL'
# Getting Started with Your WSL Development Environment

This guide will help you get familiar with your new development environment.

## First Steps After Installation

1. **Update your environment**:
   ```bash
   ~/dev-env/update.sh
   ```

2. **Make the custom commands available**:
   ```bash
   source ~/.bashrc
   ```

3. **Change your shell to Zsh** (optional but recommended):
   ```bash
   chsh -s $(which zsh)
   ```
   Then log out and back in.

## Essential Tools Overview

### Neovim: Modern Text Editor

Neovim is a powerful text editor. We've set up the "Kickstart" configuration which gives you modern features like:
- File explorer
- Code completion
- Syntax highlighting
- Git integration

**Basic usage**:
```bash
nvim file.txt  # Open a file
```

Inside Neovim:
- Press `i` to enter insert mode
- Press `Esc` to go back to normal mode
- Press `:w` to save
- Press `:q` to quit

Learn more: Type `:help` inside Neovim or run `nvim ~/dev-env/docs/neovim-guide.md`

### Tmux: Terminal Multiplexer

Tmux lets you split your terminal into multiple panes and windows, and keep sessions running even when you disconnect.

**Basic usage**:
```bash
tmux              # Start a new session
tmux ls           # List sessions
tmux attach -t 0  # Reattach to session 0
```

Inside Tmux:
- Press `Ctrl+a` then `|` to split vertically
- Press `Ctrl+a` then `-` to split horizontally
- Press `Ctrl+a` then arrow keys to navigate panes
- Press `Ctrl+a` then `d` to detach

Learn more: Run `nvim ~/dev-env/docs/tmux-guide.md`

### Zsh: Better Shell

Zsh is a powerful shell with features like:
- Better tab completion
- Command highlighting
- Plugin support

**Useful aliases**:
- `gs` - Git status
- `ga` - Git add
- `..` - Go up one directory
- `...` - Go up two directories

### WSL-specific Tools

These tools help bridge Windows and Linux:

- `winopen` - Open the current folder in Windows Explorer
- `clip` - Copy text to Windows clipboard 

Example usage:
```bash
# Copy output of a command to clipboard
ls -la | clip

# Open current directory in Windows Explorer
winopen
```

### Ansible: Environment Management

Ansible is used to manage your development environment. You typically don't need to interact with it directly, but it powers the `update.sh` script.

If you want to add new tools or configurations:
1. Edit the files in `~/dev-env/ansible/`
2. Run `~/dev-env/update.sh`

## Troubleshooting

### Command Not Found

If you get "command not found" errors:

1. Make sure your PATH includes the bin directories:
   ```bash
   echo 'export PATH="$HOME/bin:$HOME/.local/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

2. Check if the command exists:
   ```bash
   which <command-name>
   ```

3. Make sure the file is executable:
   ```bash
   chmod +x ~/bin/<command-name>
   ```

### Other Issues

Check the logs in the terminal for error messages. Most errors include guidance on how to fix them.

## Next Steps

- Read the individual tool guides in the `~/dev-env/docs/` directory
- Try customizing your configurations using the `ec` command
- Explore the cheatsheet at `~/dev-env/docs/dev-cheatsheet.md`
EOL
check_error "Failed to create getting-started.md"

# Create detailed guides for the requested tools
cat > "$SETUP_DIR/docs/tmux-guide.md" << 'EOL'
# Tmux Beginner's Guide

Tmux is a terminal multiplexer that lets you:
- Split your terminal into multiple panes
- Create multiple windows (like tabs)
- Detach from sessions and reconnect later
- Share terminal sessions with others

## Basic Concepts

- **Session**: A collection of windows and panes
- **Window**: Like a tab in your browser
- **Pane**: A split within a window

## Getting Started

### Starting Tmux

```bash
tmux           # Start a new session
t              # Alias for tmux
tn my-session  # Start a named session
```

### Common Prefix Key

All tmux commands start with a prefix key:
- In our setup, the prefix is `Ctrl+a` (press Ctrl and a at the same time)
- After pressing the prefix, you can type a command

### Basic Commands

| Command | Description |
|---------|-------------|
| `prefix + c` | Create a new window |
| `prefix + ,` | Rename the current window |
| `prefix + n` | Go to the next window |
| `prefix + p` | Go to the previous window |
| `prefix + number` | Go to window by number |

### Splitting Panes

| Command | Description |
|---------|-------------|
| `prefix + |` | Split pane vertically |
| `prefix + -` | Split pane horizontally |
| `prefix + arrow key` | Navigate between panes |
| `prefix + z` | Zoom in/out of current pane |

### Session Management

| Command | Description |
|---------|-------------|
| `prefix + d` | Detach from session |
| `tmux ls` or `tl` | List sessions |
| `tmux attach -t 0` or `ta 0` | Reattach to session 0 |
| `prefix + S` | Create a new session |
| `prefix + K` | Kill current session |

## Copy Mode

Tmux has a special mode for scrolling and copying text:

1. Enter copy mode: `prefix + [`
2. Navigate with arrow keys or vim bindings
3. Start selection: `v` (press v while in copy mode)
4. Copy selection: `y` (press y while selection is active)
5. Paste: `prefix + ]`

## Customizing Tmux

The configuration file is at `~/dev-env/configs/tmux/tmux.conf`.

To edit it:
```bash
ec
# Then select "tmux" from the menu
```

After editing, run:
```bash
~/dev-env/update.sh
```

## Practical Workflow Example

1. Start a new session: `tmux`
2. Create a window for editing: `prefix + c`
3. Split the window for running tests: `prefix + -`
4. Navigate to the bottom pane: `prefix + down`
5. Run a long process: `npm test`
6. Detach from the session: `prefix + d`
7. Come back later: `tmux attach`

## Tips and Tricks

- Use `prefix + ?` to see all key bindings
- Use mouse mode (enabled by default in our config)
- Use `prefix + space` to cycle through different pane layouts

## Getting Help

- Type `man tmux` for the manual
- Visit [Tmux Cheat Sheet](https://tmuxcheatsheet.com/)
EOL
check_error "Failed to create tmux-guide.md"

cat > "$SETUP_DIR/docs/zsh-guide.md" << 'EOL'
# Zsh Beginner's Guide

Zsh is a powerful shell with features beyond what's available in Bash.

## Why Use Zsh?

- Better tab completion
- Spelling correction
- Better history management
- Plugin support through Oh My Zsh
- More customizable

## Getting Started

### Switching to Zsh

We've installed Zsh for you. To make it your default shell:

```bash
chsh -s $(which zsh)
```

Then log out and back in.

### Oh My Zsh

Oh My Zsh is a framework for managing your Zsh configuration. It includes:

- Themes for customizing your prompt
- Plugins for additional functionality
- Aliases for common commands

## Basic Features

### Smart Tab Completion

Zsh has context-aware tab completion:

```bash
cd /h[TAB]           # Completes to /home/
git ch[TAB]          # Shows git checkout, cherry-pick, etc.
kill [TAB]           # Shows list of processes
```

### Directory Navigation

Zsh makes directory navigation easier:

```bash
..    # Move up one directory (alias)
...   # Move up two directories (alias)
cd -  # Go to previous directory
```

You also have zoxide installed, which remembers your most used directories:

```bash
z keyword   # Jump to most used directory matching keyword
```

### History Features

Better history management:

```bash
history               # Show command history
!42                   # Run command #42 from history
!-2                   # Run second to last command 
!string               # Run the last command starting with "string"
Ctrl+r                # Search history (type to search)
```

## Useful Plugins (Already Installed)

Our setup includes these plugins:

### Git Plugin
- `gs` - Git status
- `ga` - Git add
- `gc "message"` - Git commit with message
- `gp` - Git push
- `gl` - Git pull

### Autosuggestions
As you type, you'll see suggestions from your history in gray.
- Press right arrow to accept the suggestion

### Syntax Highlighting
Commands will be colored to indicate:
- Green: Valid command
- Red: Invalid command
- Yellow: Valid but potentially dangerous

## Customizing Your Zsh

To edit your Zsh configuration:

```bash
ec
# Then select "zsh" from the menu
```

After editing, run:
```bash
~/dev-env/update.sh
```

## Common Customizations

Add an alias:
```bash
alias mycommand='long command with options'
```

Add a function:
```bash
myfunction() {
  echo "Hello, $1!"
}
```

Change your prompt theme (in ~/.zshrc):
```bash
ZSH_THEME="robbyrussell"  # Change to any theme in ~/.oh-my-zsh/themes
```

## Getting Help

- Type `man zsh` for the manual
- Visit [Oh My Zsh](https://ohmyz.sh/) official website
- Use `ec` to explore the Zsh configuration
EOL
check_error "Failed to create zsh-guide.md"

cat > "$SETUP_DIR/docs/ansible-guide.md" << 'EOL'
# Ansible Beginner's Guide

Ansible is an automation tool that we use to manage your development environment.

## What is Ansible?

- Automation tool for configuring systems
- Uses YAML files to describe desired state
- Doesn't require special software on managed systems
- Executes tasks in order

## How We Use Ansible

In this environment:
- Ansible installs and configures your dev tools
- It's called by the `update.sh` script
- You rarely need to run Ansible directly

## Basic Structure

Our Ansible setup is organized like this:

- `ansible/setup.yml` - The main playbook
- `ansible/roles/` - Contains roles for different tools
  - `core-tools/` - Basic development tools
  - `shell/` - Zsh setup 
  - `tmux/` - Tmux configuration
  - etc.

## Adding a New Tool

If you want to install a new tool across your environments:

1. Edit the appropriate role or create a new one
2. Run `~/dev-env/update.sh`

Example: Adding a new package to core-tools:

1. Edit `~/dev-env/ansible/roles/core-tools/tasks/main.yml`
2. Find the "Install essential development packages" task
3. Add your package to the list
4. Run `~/dev-env/update.sh`

## Creating a New Role

If you want to add a completely new tool:

1. Create a new role directory:
   ```bash
   mkdir -p ~/dev-env/ansible/roles/my-new-tool/tasks
   ```

2. Create a main.yml file:
   ```bash
   nvim ~/dev-env/ansible/roles/my-new-tool/tasks/main.yml
   ```

3. Add your tasks:
   ```yaml
   ---
   - name: Install my new tool
     become: true
     apt:
       name: my-new-tool
       state: present
   
   - name: Configure my new tool
     template:
       src: "{{ playbook_dir }}/../configs/my-new-tool/config"
       dest: ~/.config/my-new-tool/config
       mode: '0644'
   ```

4. Add the role to the main playbook by editing `~/dev-env/ansible/setup.yml`

5. Run `~/dev-env/update.sh`

## Common Ansible Tasks

### Installing Packages

```yaml
- name: Install packages
  become: true
  apt:
    name:
      - package1
      - package2
    state: present
```

### Creating Files

```yaml
- name: Create a configuration file
  copy:
    src: "{{ playbook_dir }}/../configs/tool/config"
    dest: ~/.config/tool/config
    mode: '0644'
```

### Running Commands

```yaml
- name: Run a command
  command: echo "Hello World"
  register: command_output
```

## Getting Help

- For our custom setup, check the existing roles for examples
- Visit [Ansible Documentation](https://docs.ansible.com/)
- Run `ansible-doc module_name` for help on a specific module
EOL
check_error "Failed to create ansible-guide.md"

# Create a comprehensive Neovim guide focused on code creation and navigation
cat > "$SETUP_DIR/docs/neovim-guide.md" << 'EOL'
# Neovim Complete Guide

This guide explains how to effectively use Neovim for coding and navigating codebases.

## Table of Contents
1. [Basic Concepts](#basic-concepts)
2. [Code Navigation](#code-navigation)
3. [Code Creation and Editing](#code-creation-and-editing)
4. [Project Management](#project-management)
5. [Code Intelligence](#code-intelligence)
6. [Terminal Integration](#terminal-integration)
7. [Git Integration](#git-integration)
8. [Keyboard Shortcuts Reference](#keyboard-shortcuts-reference)
9. [Customizing Neovim](#customizing-neovim)

## Basic Concepts

Neovim has different modes:
- **Normal mode** (Esc): For navigation and commands (default)
- **Insert mode** (i): For typing text
- **Visual mode** (v): For selecting text
- **Command mode** (:): For entering commands

### Opening Files

```bash
nvim file.txt          # Open a file
nvim .                 # Open current directory 
nvim file1 file2       # Open multiple files
nvim +10 file.txt      # Open file at line 10
nvim +/pattern file.txt # Open file at first 'pattern' match
```

## Code Navigation

### File Navigation

- **Space+e**: Open file explorer (NvimTree)
  - Navigate with h,j,k,l
  - Press ? for help in the explorer
  - Press Enter to open files
  
- **Space+ff**: Find files by name (Telescope)
  - Type to search file names
  - Up/Down to navigate results
  - Enter to open selected file
  
- **Space+fg**: Find text within files (live grep)
  - Type to search content in files
  - Results update in real-time
  
- **Space+fb**: Browse open buffers
  - See all open files and switch between them

### Within File Navigation

- **gg**: Go to beginning of file
- **G**: Go to end of file
- **10G** or **:10**: Go to line 10
- **w**: Move forward by word
- **b**: Move backward by word
- **0**: Start of line
- **$**: End of line
- **%**: Jump to matching bracket
- **Ctrl+d**: Scroll half-page down
- **Ctrl+u**: Scroll half-page up
- **zz**: Center current line on screen

### Search and Jump

- **/pattern**: Search forward for pattern
- **?pattern**: Search backward for pattern
- **n**: Next occurrence of search pattern
- **N**: Previous occurrence of search pattern
- **f{char}**: Jump to next occurrence of character
- **F{char}**: Jump to previous occurrence of character

### Advanced Navigation

- **gd**: Go to definition (LSP)
- **gr**: Find references (LSP)
- **Space+ds**: Document symbols (outline)
- **[d** and **]d**: Previous/next diagnostic
- **Ctrl+o**: Jump back to previous position
- **Ctrl+i**: Jump forward in jump list

## Code Creation and Editing

### Text Insertion

- **i**: Insert at cursor
- **a**: Insert after cursor
- **I**: Insert at beginning of line
- **A**: Insert at end of line
- **o**: Insert on new line below
- **O**: Insert on new line above

### Text Manipulation

- **x**: Delete character under cursor
- **dd**: Delete line
- **yy**: Yank (copy) line
- **p**: Paste after cursor
- **P**: Paste before cursor
- **u**: Undo
- **Ctrl+r**: Redo

### Block Operations

1. **Visual mode selection**:
   - **v**: Character-wise selection
   - **V**: Line-wise selection
   - **Ctrl+v**: Block selection
   
2. **With text selected**:
   - **d**: Delete selection
   - **y**: Yank (copy) selection
   - **c**: Change (delete and enter insert mode)
   - **>**: Indent
   - **<**: Unindent
   - **~**: Toggle case
   - **J/K**: Move selected lines down/up (custom mapping)

### Multiple Cursors (via block selection)
1. Press **Ctrl+v** to enter visual block mode
2. Select lines (j/k)
3. Press **Shift+i** to insert at the beginning
4. Type your text
5. Press **Esc** to apply to all lines

### Code Formatting

- **=**: Format selected text
- **gg=G**: Format entire file
- **Space+lf**: Format file using LSP formatter (if available)

## Project Management

### Sessions

- **:mksession file.vim**: Save current session
- **:source file.vim**: Load a session
- **:Telescope sessions**: Browse and select saved sessions

### Multiple Files

- **:e file**: Edit a file
- **:bn**: Next buffer
- **:bp**: Previous buffer
- **Space+[**: Previous buffer (custom mapping)
- **Space+]**: Next buffer (custom mapping)
- **Space+c**: Close current buffer
- **Space+fb**: Browse open buffers

### Windows (Splits)

- **:sp file**: Horizontal split
- **:vsp file**: Vertical split
- **Ctrl+h/j/k/l**: Navigate splits
- **Ctrl+w o**: Close all other windows
- **Ctrl+w =**: Make all windows equal size
- **Ctrl+w _**: Maximize height
- **Ctrl+w |**: Maximize width
- **Ctrl+w r**: Rotate windows

## Code Intelligence

### Code Completion

- Start typing to see suggestions
- **Tab/S-Tab**: Navigate completion menu
- **Enter**: Accept completion
- **Ctrl+space**: Force completion menu

### LSP Features

- **gd**: Go to definition
- **gr**: Find references
- **K**: Show documentation
- **Space+ca**: Code actions (fix errors, organize imports, etc.)
- **Space+rn**: Rename symbol (across all files)
- **Space+D**: Type definition
- **Space+ds**: Document symbols (outline)
- **Space+ws**: Workspace symbols

### Diagnostics

- **Space+e**: Show line diagnostics
- **[d** and **]d**: Previous/next diagnostic
- **Space+q**: Send diagnostics to quickfix list

## Terminal Integration

- **:T**: Open terminal in split (custom command)
- **:term**: Open integrated terminal
- **Ctrl+\\ Ctrl+n**: Exit terminal mode (back to normal mode)
- **i** or **a**: Enter terminal mode again (from normal mode)

## Git Integration

Neovim includes Git integration via **gitsigns**:

- **]c** and **[c**: Jump between hunks
- **Space+hs**: Stage hunk
- **Space+hr**: Reset hunk
- **Space+hS**: Stage buffer
- **Space+hu**: Undo stage hunk
- **Space+hb**: Blame line
- **Space+hd**: Diff this

For more Git operations:
- **:Git**: Run git commands 
- **:Gdiff**: Git diff
- **:Gblame**: Git blame

## Keyboard Shortcuts Reference

### Most used shortcuts

- **Space+ff**: Find files
- **Space+fg**: Find text in files
- **Space+e**: Toggle file explorer
- **gd**: Go to definition
- **K**: Show documentation
- **Space+ca**: Code actions
- **Ctrl+h/j/k/l**: Navigate between windows
- **Space+w**: Save file
- **Space+q**: Quit

### Motion Shortcuts

- **w/b/e**: Word navigation
- **f/F**: Jump to character
- **t/T**: Jump until character
- **%**: Jump to matching bracket
- **gg/G**: Top/bottom of file
- **{/}**: Jump paragraphs

### Text Objects

Select or operate on text objects:
- **iw/aw**: Inside/around word
- **i"/a"**: Inside/around quotes
- **i(/a(**: Inside/around parentheses
- **i{/a{**: Inside/around braces
- **it/at**: Inside/around tags

Example: **ci"** = Change inside quotes

## Customizing Neovim

Your custom configuration is in: `~/.config/nvim/lua/custom/init.lua`

To edit:
```bash
ec
# Then select "nvim" from the menu
```

### Adding Plugins

To add a new plugin, edit the custom config and add:

```lua
-- In your custom/init.lua
-- This will run after the Kickstart config loads

-- Add a plugin
table.insert(require('lazy').plugins, {
  'username/plugin-name',
  config = function()
    -- Configuration for the plugin
    require('plugin-name').setup({
      -- options
    })
  end
})
```

### Adding Keymaps

Add custom keymaps in your custom/init.lua:

```lua
vim.keymap.set('n', '<leader>x', function()
  print("Custom command!")
end, { desc = 'My custom command' })
```

### Adding Commands

Create custom commands:

```lua
vim.api.nvim_create_user_command('MyCommand', function()
  print("Running my command")
end, {})
```

## Learning Resources

- `:Tutor` - Interactive Vim tutorial
- `:help` - Comprehensive documentation
- [Learn Vim the Smart Way](https://learnvim.irian.to/)
- [ThePrimeagen's Neovim videos](https://www.youtube.com/c/ThePrimeagen)
- [TJ DeVries' Neovim videos](https://www.youtube.com/c/TJDeVries)
EOL
check_error "Failed to create neovim-guide.md"

# Create a new guide specifically about working with code projects in Neovim
cat > "$SETUP_DIR/docs/neovim-projects.md" << 'EOL'
# Working with Code Projects in Neovim

This guide provides practical workflows for managing code projects in Neovim.

## Setting Up a New Project

### 1. Create a Project Directory Structure

```bash
mkdir -p my-project/{src,tests,docs}
cd my-project
git init
```

### 2. Open the Project in Neovim

```bash
nvim .
```

### 3. Use the File Explorer to Navigate

- Press `<Space>e` to open the file explorer
- Navigate to the folder where you want to create a file
- Press `a` to add a new file

## Efficient Workflow for Existing Projects

### 1. Opening a Project

```bash
cd my-project
nvim .
```

### 2. Finding Files Quickly

- `<Space>ff` - Find files in project
- `<Space>fg` - Search for text in files
- `<Space>fr` - Recent files
- `<Space>fb` - Open buffers

### 3. Navigating Between Files

- `gd` - Go to definition
- `Ctrl+o` - Jump back
- `Ctrl+i` - Jump forward
- `<Space>ds` - Document symbols (function list)

### 4. Using Multiple Windows

For parallel work (e.g. code and tests):
1. Open your main file
2. Open test file in split: `:vsp tests/test_file.py`
3. Navigate between splits with `Ctrl+h/j/k/l`

### 5. Running Commands Without Leaving Neovim

- `:T npm run test` - Run in split terminal
- `:terminal` - Open a terminal buffer
- In terminal mode: `Ctrl+\ Ctrl+n` to return to normal mode

## Language-Specific Features

Your Kickstart Neovim setup includes LSP (Language Server Protocol) support, which provides intelligent features for many languages. When you open a file of a supported language, Neovim will:

1. Automatically connect to the appropriate language server
2. Provide code completion, diagnostics, and navigation

### JavaScript/TypeScript Example

1. Open a JS/TS file: `nvim src/index.js`
2. LSP will automatically activate
3. Get code completion as you type
4. See errors and warnings inline
5. Navigate code with:
   - `gd` - Go to definition
   - `gr` - Find references  
   - `K` - Show documentation

### Python Example

1. Open a Python file: `nvim src/main.py`
2. LSP (Pyright) will automatically activate
3. Use:
   - `<Space>ca` - Code actions (import fixing, etc.)
   - `<Space>rn` - Rename symbols
   - `[d` and `]d` - Navigate between errors

## Working with Multiple Projects

### Using Workspaces

1. Create a workspace file:
   ```lua
   -- ~/.local/share/nvim/workspaces/my-projects.lua
   return {
     {
       name = "Project 1",
       path = "~/dev/project1",
     },
     {
       name = "Project 2", 
       path = "~/dev/project2",
     }
   }
   ```

2. Switch between projects:
   - `<Space>fw` - Search workspaces
   - Select the project to open

## Git Integration

Kickstart Neovim includes git integration:

1. View git changes with gutter signs
2. Navigate changes with `]c` and `[c` 
3. Stage/unstage hunks with `<Space>hs`/`<Space>hu`
4. Stage entire buffer with `<Space>hS`
5. View blame with `<Space>hb`

## Saving and Restoring Sessions

Save your complete working state:

1. Save session: `:mksession ~/sessions/project1.vim` 
2. Restore later: `nvim -S ~/sessions/project1.vim`

## Database Integration

For database work, you can set up the `vim-dadbod` plugin:

1. Edit your custom config:
   ```bash
   ec
   # Select nvim
   ```

2. Add the following to your init.lua:
   ```lua
   table.insert(require('lazy').plugins, {
     'tpope/vim-dadbod',
     dependencies = {
       'kristijanhusak/vim-dadbod-ui',
       'kristijanhusak/vim-dadbod-completion',
     },
     config = function()
       vim.g.db_ui_save_location = vim.fn.stdpath('config') .. '/db_ui'
       
       -- Add key mapping to open DB UI
       vim.keymap.set('n', '<leader>db', ':DBUI<CR>', { desc = 'Open Database UI' })
     end
   })
   ```

3. Run: `:Lazy sync`

## Docker Integration

For Docker-based projects:

1. Install docker.nvim plugin:
   ```lua
   table.insert(require('lazy').plugins, {
     'dgrbrady/nvim-docker',
     dependencies = {
       'nvim-lua/plenary.nvim',
       'MunifTanjim/nui.nvim',
     },
     config = function()
       require('nvim-docker').setup({})
     end
   })
   ```

2. Run: `:Lazy sync`
3. Use: `:Docker` to manage containers

## Practical Tips for Large Projects

1. **Use Project-specific Config**:
   Create `.nvim.lua` in the project root:
   ```lua
   -- Project-specific settings
   vim.opt_local.tabstop = 4
   vim.opt_local.shiftwidth = 4
   
   -- Add project-specific mappings
   vim.keymap.set('n', '<leader>t', ':T npm test<CR>', { buffer = true })
   ```

2. **Set Up Project-specific Commands**:
   ```bash
   echo "local project_cmd = vim.api.nvim_create_user_command
   project_cmd('Test', 'T npm test', {})
   project_cmd('Build', 'T npm run build', {})" > .nvim.lua
   ```

3. **Create Project Snippets**:
   Install the LuaSnip plugin and create project-specific snippets in `~/.config/nvim/snippets/your_language.lua`
EOL
check_error "Failed to create neovim-projects.md"

cat > "$SETUP_DIR/docs/wsl-guide.md" << 'EOL'
# WSL Integration Guide

This guide covers the WSL-specific tools and integrations in your development environment.

## Custom Commands

We've included several commands to make WSL/Windows integration smoother:

### winopen

Opens the current or specified directory in Windows Explorer:

```bash
winopen                  # Open current directory
winopen ~/Documents      # Open Documents folder
```

### clip-copy

Copies text to the Windows clipboard:

```bash
echo "Hello World" | clip     # Pipe output to clipboard
clip "Text to clipboard"      # Direct text to clipboard
cat file.txt | clip           # Copy file contents to clipboard
```

### wsl-path-fix.sh

This script optimizes your PATH to prioritize Linux binaries:

```bash
source ~/bin/wsl-path-fix.sh  # Run manually if needed
```

It's automatically included in your .zshrc

## Accessing Windows Files

Windows drives are mounted at `/mnt/c`, `/mnt/d`, etc.

```bash
cd /mnt/c/Users/YourUsername/Documents
```

## Accessing Linux Files from Windows

You can access your Linux files from Windows Explorer:

1. Open File Explorer in Windows
2. In the address bar, type: `\\wsl$\Debian` (or your distro name)
3. Navigate to your home folder

## Running Windows Programs

You can run Windows programs directly from the WSL terminal:

```bash
explorer.exe .                   # Open current folder in Explorer
cmd.exe /c echo Hello           # Run a cmd command
powershell.exe Get-Date         # Run a PowerShell command
notepad.exe file.txt            # Open file in Notepad
code .                          # Open VS Code (if installed)
```

## WSL Performance Tips

1. Keep projects in the Linux filesystem for better performance
2. Avoid heavy I/O operations across the filesystem boundary
3. Use `wsl-path-fix.sh` to optimize your PATH
4. Consider using Windows Terminal for better experience

## WSL Resource Configuration

We've set up a `.wslconfig` file in your Windows home directory with optimal settings:

```
[wsl2]
memory=6GB
processors=4
swap=2GB
localhostForwarding=true
```

You can adjust these settings by editing:
```bash
nvim ~/dev-env/configs/wsl/wslconfig
```

Then run:
```bash
~/dev-env/update.sh
```

## Troubleshooting

### Command Not Found

If WSL commands aren't found:

1. Make sure ~/bin is in your PATH:
   ```bash
   echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
   source ~/.bashrc
   ```

2. Verify the commands exist:
   ```bash
   ls -la ~/bin
   ```

3. Make sure they're executable:
   ```bash
   chmod +x ~/bin/winopen ~/bin/clip-copy ~/bin/wsl-path-fix.sh
   ```

### Other WSL Issues

- For slow startup: Try `wsl --shutdown` from PowerShell, then restart
- For networking issues: Restart the WSL service from PowerShell: `Restart-Service LxssManager`
- For integration problems: Make sure Windows interoperability is enabled: `wsl.exe --set-default-version 2`
EOL
check_error "Failed to create wsl-guide.md"

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
- `file [filename]` - Determine file type

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
- `explorer.exe .` - Open current directory in Windows Explorer

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

## Environment Management
- `~/dev-env/update.sh` - Update your environment
- `ec` - Edit your configurations interactively
- `neofetch` - Display system information

## Getting Help
- `man [command]` - Show manual for command
- `[command] --help` - Show help for command
- `nvim ~/dev-env/docs/[tool]-guide.md` - Open guide for specific tool
EOL
check_error "Failed to create dev-cheatsheet.md"

# Update .bashrc to use neofetch instead of fastfetch
if ! grep -q "neofetch" ~/.bashrc && grep -q "fastfetch" ~/.bashrc; then
  sed -i 's/fastfetch/neofetch/g' ~/.bashrc
  echo -e "${GREEN}Updated ~/.bashrc to use neofetch instead of fastfetch${NC}"
elif ! grep -q "neofetch" ~/.bashrc && ! grep -q "fastfetch" ~/.bashrc; then
  echo -e "\n# Run neofetch at startup\nneofetch" >> ~/.bashrc
  echo -e "${GREEN}Added neofetch to ~/.bashrc startup${NC}"
fi

# Also add PATH to .bashrc (if not already there) to ensure commands are available without Zsh
if ! grep -q 'PATH="$HOME/bin:$HOME/.local/bin:$PATH"' ~/.bashrc; then
  echo -e '\n# Add ~/bin and ~/.local/bin to PATH\nexport PATH="$HOME/bin:$HOME/.local/bin:$PATH"' >> ~/.bashrc
  echo -e "${GREEN}Added PATH update to ~/.bashrc${NC}"
fi

# Make scripts in ~/bin executable immediately
cp "$SETUP_DIR/configs/wsl/wsl-path-fix.sh" ~/bin/
cp "$SETUP_DIR/configs/wsl/winopen" ~/bin/
cp "$SETUP_DIR/configs/wsl/clip-copy" ~/bin/
chmod +x ~/bin/wsl-path-fix.sh ~/bin/winopen ~/bin/clip-copy
check_error "Failed to copy and make WSL utilities executable"

# Let's source .bashrc to add PATH immediately in this session
source ~/.bashrc

# Create a script to install Neovim providers and Treesitter language parsers
cat > "$SETUP_DIR/bin/fix-neovim.sh" << 'EOF'
#!/bin/bash
# Fix Neovim providers and install language parsers

# Color definitions
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'

# Check if python3-venv is installed
if ! dpkg -l | grep -q python3-venv; then
  echo -e "${YELLOW}Python3-venv package is required but not installed${NC}"
  echo -e "${YELLOW}Installing python3-venv...${NC}"
  sudo apt update
  sudo apt install -y python3-venv python3-pip
fi

# Ensure virtual environment directory exists
mkdir -p ~/.config/nvim/venv

# Create virtual environment if needed
if [ ! -f ~/.config/nvim/venv/bin/python ]; then
  echo -e "${BLUE}=== Creating Python virtual environment ===${NC}"
  python3 -m venv ~/.config/nvim/venv
fi

echo -e "${BLUE}=== Installing Python provider for Neovim ===${NC}"
~/.config/nvim/venv/bin/pip install pynvim

# Configure Neovim to use the virtual environment
mkdir -p ~/.config/nvim/after/plugin
cat > ~/.config/nvim/after/plugin/python-provider.lua << EOF
-- Configure Neovim Python provider to use virtual environment
vim.g.python3_host_prog = vim.fn.expand('~/.config/nvim/venv/bin/python')
EOF

# Install Node.js provider if nvm is available
if [ -f "$HOME/.nvm/nvm.sh" ]; then
  echo -e "${BLUE}=== Installing Node.js provider for Neovim ===${NC}"
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  npm install -g neovim
else
  echo -e "${YELLOW}NVM not found, skipping Node.js provider installation${NC}"
fi

# Configure nvim-treesitter
mkdir -p ~/.config/nvim/after/plugin
cat > ~/.config/nvim/after/plugin/treesitter-config.lua << EOF
-- Configure nvim-treesitter to install without prompts
require('nvim-treesitter.configs').setup({
  auto_install = true,
  ensure_installed = { "lua", "vim", "vimdoc", "javascript", "typescript", "python", "rust" },
  sync_install = false,
})
EOF

echo -e "${GREEN}Neovim providers and language parsers configuration completed${NC}"
echo -e "${YELLOW}You can verify the installation by running :checkhealth in Neovim${NC}"
EOF
chmod +x "$SETUP_DIR/bin/fix-neovim.sh"
check_error "Failed to create fix-neovim.sh script"

print_title "Initial Setup Complete!"
echo -e "${GREEN}Your WSL developer environment is ready to use!${NC}"
echo -e "\n${BLUE}To make the custom commands immediately available:${NC}"
echo -e "  ${YELLOW}source ~/.bashrc${NC}"
echo -e "\n${BLUE}Next steps:${NC}"
echo -e "1. Run the update script to install additional tools: ${YELLOW}~/dev-env/update.sh${NC}"
echo -e "2. Read the getting started guide: ${YELLOW}nvim ~/dev-env/docs/getting-started.md${NC}"
echo -e "3. Consider changing your default shell to Zsh: ${YELLOW}chsh -s $(which zsh)${NC}"
echo -e "4. Explore the Neovim guides: ${YELLOW}nvim ~/dev-env/docs/neovim-guide.md${NC}"
echo -e "   and ${YELLOW}nvim ~/dev-env/docs/neovim-projects.md${NC} to learn about code navigation"
echo -e "5. Check out the cheatsheet: ${YELLOW}nvim ~/dev-env/docs/dev-cheatsheet.md${NC}"
echo -e "\n${GREEN}Happy coding!${NC}"
