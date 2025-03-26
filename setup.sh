#!/bin/bash

# Ultimate WSL Development Environment Setup
# A beginner-friendly, modular development environment for WSL Debian

# Print colored section headers
print_header() {
  echo -e "\n\033[1;36m==== $1 ====\033[0m"
}

# Error handling function
check_error() {
  if [ $? -ne 0 ]; then
    echo -e "\033[1;31mERROR: $1\033[0m"
    echo "Would you like to continue anyway? (y/n)"
    read -r response
    if [[ "$response" != "y" ]]; then
      echo "Setup aborted."
      exit 1
    fi
  fi
}

print_header "Welcome to the Ultimate WSL Development Environment Setup"
echo "This script will set up a developer environment optimized for WSL Debian"
echo "You can easily modify any part of this setup later"

# Create our workspace structure
mkdir -p ~/dev-env/{ansible,configs,bin,docs}
SETUP_DIR="$HOME/dev-env"
cd "$SETUP_DIR" || { echo "Failed to change directory"; exit 1; }

# Ensure basic dependencies are installed
print_header "Installing core dependencies"
sudo apt update
check_error "Failed to update package lists"

sudo apt install -y curl wget git python3 python3-pip unzip
check_error "Failed to install core dependencies"

# Install Ansible (as recommended by ThePrimeagen for reproducible environments)
print_header "Setting up Ansible"
if ! command -v ansible &> /dev/null; then
  echo "Installing Ansible..."
  sudo apt install -y ansible  # System installation via apt
  check_error "Failed to install Ansible"
  echo "Ansible installed successfully!"
else
  echo "Ansible is already installed"
fi

# Download our Ansible playbooks
print_header "Downloading configuration files"

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

# Create the Ansible playbooks directory
mkdir -p "$SETUP_DIR/ansible/roles"

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
    - editor         # NeoVim setup with Kickstart
    - shell          # Zsh with useful plugins
    - tmux           # Terminal multiplexer
    - wsl-specific   # WSL-specific optimizations
    - git-config     # Git configuration
    - nodejs         # Node.js and npm
EOL

# Create update script
cat > "$SETUP_DIR/update.sh" << 'EOL'
#!/bin/bash
# Update script for WSL development environment

# Error handling function
check_error() {
  if [ $? -ne 0 ]; then
    echo -e "\033[1;31mERROR: $1\033[0m"
    echo "Would you like to continue anyway? (y/n)"
    read -r response
    if [[ "$response" != "y" ]]; then
      echo "Setup aborted."
      exit 1
    fi
  fi
}

# Navigate to our environment directory
cd "$(dirname "$0")" || { echo "Failed to change directory"; exit 1; }

# Check for custom variables
if [ -f "config.env" ]; then
  source config.env
fi

# Run our Ansible playbook
echo "Updating your development environment..."
ansible-playbook -i localhost, ansible/setup.yml
check_error "Ansible playbook execution failed"

echo "Environment updated successfully!"
echo "Remember: You can customize any aspect by editing files in the configs/ directory"
EOL
chmod +x "$SETUP_DIR/update.sh"

# Create editor roles
mkdir -p "$SETUP_DIR/ansible/roles/editor/tasks"
cat > "$SETUP_DIR/ansible/roles/editor/tasks/main.yml" << 'EOL'
---
# NeoVim setup with Kickstart configuration
- name: Ensure NeoVim directories exist
  file:
    path: "{{ item }}"
    state: directory
  with_items:
    - "~/.config/nvim"
    - "~/.config/nvim/lua/custom"

- name: Check if Neovim is installed
  command: which nvim
  register: nvim_installed
  ignore_errors: true
  changed_when: false

- name: Download and install Neovim (if not installed)
  block:
    - name: Get latest Neovim release URL
      uri:
        url: https://api.github.com/repos/neovim/neovim/releases/latest
        return_content: yes
      register: github_response
      when: nvim_installed.rc != 0

    - name: Extract download URL
      set_fact:
        download_url: "{{ github_response.json | json_query('assets[?contains(name, `linux64.tar.gz`)].browser_download_url') | first }}"
      when: nvim_installed.rc != 0

    - name: Download and extract Neovim
      shell: |
        curl -L {{ download_url }} | tar xzf - --strip-components=1 -C ~/.local/bin
      args:
        creates: "~/.local/bin/nvim"
      when: nvim_installed.rc != 0
  when: nvim_installed.rc != 0

- name: Install Kickstart Neovim configuration
  git:
    repo: https://github.com/nvim-lua/kickstart.nvim.git
    dest: ~/.config/nvim
    depth: 1
    force: yes
  when: nvim_custom_config.stat.exists == false

- name: Create custom Neovim configuration
  copy:
    src: "{{ config_dir }}/nvim/custom/init.lua"
    dest: ~/.config/nvim/lua/custom/init.lua
EOL

# Create core-tools role
mkdir -p "$SETUP_DIR/ansible/roles/core-tools/tasks"
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
      # Core utilities recommended by ThePrimeagen
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
    state: present

- name: Create symbolic links for Debian-specific tool names
  block:
    - name: Link fd-find as fd
      file:
        src: /usr/bin/fdfind
        dest: ~/.local/bin/fd
        state: link
        force: yes
      when: ansible_facts.packages['fd-find'] is defined

    - name: Link batcat as bat
      file:
        src: /usr/bin/batcat 
        dest: ~/.local/bin/bat
        state: link
        force: yes
      when: ansible_facts.packages['bat'] is defined
EOL

# Create shell role
mkdir -p "$SETUP_DIR/ansible/roles/shell/tasks"
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
    src: "{{ config_dir }}/zsh/zshrc"
    dest: ~/.zshrc
    backup: yes
EOL

# Create tmux role
mkdir -p "$SETUP_DIR/ansible/roles/tmux/tasks"
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
    src: "{{ config_dir }}/tmux/tmux.conf"
    dest: ~/.tmux.conf
    backup: yes
EOL

# Create WSL-specific role
mkdir -p "$SETUP_DIR/ansible/roles/wsl-specific/tasks"
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
    src: "{{ config_dir }}/wsl/{{ item }}"
    dest: ~/bin/{{ item }}
    mode: '0755'
  with_items:
    - wsl-path-fix.sh
    - winopen
    - clip-copy

- name: Ensure .wslconfig exists in Windows home
  copy:
    src: "{{ config_dir }}/wsl/wslconfig"
    dest: "/mnt/c/Users/{{ lookup('env', 'USER') }}/.wslconfig"
    backup: yes
EOL

# NEW: Create git-config role
mkdir -p "$SETUP_DIR/ansible/roles/git-config/tasks"
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
EOL

# NEW: Create nodejs role
mkdir -p "$SETUP_DIR/ansible/roles/nodejs/tasks"
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
  when: node_installed.rc != 0 or node_installed.rc == 0
EOL

# Create configs directory structure
mkdir -p "$SETUP_DIR/configs/"{nvim/custom,zsh,tmux,wsl,git}

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
export PATH="$HOME/.local/bin:$HOME/bin:$PATH"

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
source ~/bin/wsl-path-fix.sh

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
    $EDITOR "$file"
    
    echo "Don't forget to run ~/dev-env/update.sh to apply changes"
  fi
}

# Add the editconfig function to your command palette
alias ec='editconfig'
EOL

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

# Create NeoVim custom configuration
cat > "$SETUP_DIR/configs/nvim/custom/init.lua" << 'EOL'
-- Custom NeoVim configuration extending Kickstart
-- This is loaded after the main Kickstart configuration

-- ================= DISPLAY SETTINGS =================
vim.opt.relativenumber = true    -- Relative line numbers
vim.opt.scrolloff = 8            -- Keep 8 lines visible when scrolling
vim.opt.sidescrolloff = 8        -- Keep 8 columns left/right of cursor
vim.opt.wrap = false             -- Don't wrap lines
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
-- For example:
-- 1. Add custom plugin configurations
-- 2. Define new keymappings for your workflow
-- 3. Set up language-specific settings

-- Try adding a line below to see the effect:
-- vim.cmd('colorscheme tokyonight')
EOL

# Create WSL utilities
mkdir -p "$SETUP_DIR/configs/wsl"

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

# Windows open script
cat > "$SETUP_DIR/configs/wsl/winopen" << 'EOL'
#!/bin/bash
# Open current directory or specified path in Windows Explorer

path_to_open="${1:-.}"
windows_path=$(wslpath -w "$(realpath "$path_to_open")")
explorer.exe "$windows_path"
EOL

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

# WSL config
cat > "$SETUP_DIR/configs/wsl/wslconfig" << 'EOL'
[wsl2]
memory=6GB
processors=4
swap=2GB
localhostForwarding=true
kernelCommandLine=sysctl.vm.swappiness=10
EOL

# NEW: Create Git config template
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

Here is the corrected version where everything is printed as plain text without splitting into separate code blocks:

```
# Create a guide for editing configs
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
EOL
```
