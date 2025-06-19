# Fixes for WSL Setup Script v0.0.4

## Issues Fixed

### 1. Script Version Update
```bash
# Line 18: Update version number
SCRIPT_VERSION="0.0.4"
```

### 2. Core Dependencies Function Fix
```bash
# Around line 305: Update install_core_deps function
install_core_deps() {
    print_header "Installing Core Dependencies"
    if [ "$INTERACTIVE_MODE" = false ]; then
        print_step "Installing essential packages (auto-accepting prompts)..."
        run_elevated pacman -S --noconfirm --needed curl wget git python python-pip python-virtualenv unzip \
            base-devel file cmake ripgrep fd fzf tmux zsh \
            jq bat htop github-cli 2>&1 | grep -v "warning: insufficient columns"
    else
        print_step "Installing essential packages..."
        run_elevated pacman -S --needed curl wget git python python-pip python-virtualenv unzip \
            base-devel file cmake ripgrep fd fzf tmux zsh \
            jq bat htop github-cli 2>&1 | grep -v "warning: insufficient columns"
    fi
    
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
```

### 3. Fastfetch Function Fix
```bash
# Around line 330: Update install_fastfetch function
install_fastfetch() {
    print_header "Installing Fastfetch"
    if ! command_exists fastfetch; then
        if [ "$INTERACTIVE_MODE" = false ]; then
            print_step "Installing Fastfetch (modern neofetch alternative, auto-accepting prompts)..."
            run_elevated pacman -S --noconfirm --needed fastfetch 2>&1 | grep -v "warning: insufficient columns"
        else
            print_step "Installing Fastfetch (modern neofetch alternative)..."
            run_elevated pacman -S --needed fastfetch 2>&1 | grep -v "warning: insufficient columns"
        fi
        
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
```

### 4. Neovim Function Fix
```bash
# Around line 360: Update install_neovim function
install_neovim() {
    print_header "Installing Neovim"
    if ! command_exists nvim; then
        if [ "$INTERACTIVE_MODE" = false ]; then
            print_step "Installing Neovim from official Arch repository (auto-accepting prompts)..."
            run_elevated pacman -S --noconfirm --needed neovim 2>&1 | grep -v "warning: insufficient columns"
        else
            print_step "Installing Neovim from official Arch repository..."
            run_elevated pacman -S --needed neovim 2>&1 | grep -v "warning: insufficient columns"
        fi
        
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
```

### 5. Setup Zsh Function Fix
```bash
# Around line 580: Update setup_zsh function
setup_zsh() {
    print_header "Setting up Zsh with Oh My Zsh"
    
    # Install zsh if not already installed
    if ! command_exists zsh; then
        if [ "$INTERACTIVE_MODE" = false ]; then
            print_step "Installing Zsh (auto-accepting prompts)..."
            run_elevated pacman -S --noconfirm --needed zsh 2>&1 | grep -v "warning: insufficient columns"
        else
            print_step "Installing Zsh..."
            run_elevated pacman -S --needed zsh 2>&1 | grep -v "warning: insufficient columns"
        fi
        
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
```

### 6. Node.js Setup Function Fix
```bash
# Around line 1350: Update setup_nodejs function
setup_nodejs() {
    print_header "Setting up Node.js via NVM"
    
    if [ ! -d "$HOME/.nvm" ]; then
        print_step "Installing NVM (Node Version Manager)..."
        # Install development tools needed for building Node.js
        if [ "$INTERACTIVE_MODE" = false ]; then
            run_elevated pacman -S --noconfirm --needed base-devel openssl 2>&1 | grep -v "warning: insufficient columns"
        else
            run_elevated pacman -S --needed base-devel openssl 2>&1 | grep -v "warning: insufficient columns"
        fi
        
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
    if chezmoi managed ~/.bashrc &>/dev/null; then
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
```

## Usage

The script now supports both interactive and non-interactive modes:

```bash
# Default non-interactive mode (auto-accepts all prompts)
./setup.sh

# Interactive mode (waits for user input at each prompt)
./setup.sh --interactive

# Show help
./setup.sh --help
```

## What This Fixes

1. **User Confusion**: The script now clearly explains why prompts appear but can't be answered
2. **Control Option**: Users who want to review packages can use `--interactive` mode
3. **Default Behavior**: Keeps the automated installation for most users who just want a quick setup
4. **Documentation**: Clear messaging about which mode is active

The script already has command line argument parsing at the end - this functionality is already implemented in the current version.