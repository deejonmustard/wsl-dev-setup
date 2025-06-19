# WSL Arch Linux Ricing Instructions for AI Implementation

## Core Implementation Ethos

The user wants to evolve their WSL Arch Linux setup from "1-100" with these key principles:

1. **Personal Preference**: Rose Pine theme with transparency (0.9 opacity) everywhere
2. **Performance First**: GPU-accelerated terminals, fast tools, native WSL filesystem
3. **Flexibility for Others**: Script should enable users to choose their own themes
4. **Windows Integration**: Seamless with GlazeWM, YASB, Flow Launcher
5. **Developer Focus**: Modern CLI tools, AI integration, efficient workflows

## Critical Script Enhancements Required

### 1. Modern Terminal Setup Function

**Add after `install_core_deps()` in setup.sh:**

```bash
setup_modern_terminal() {
    print_header "Installing Modern Terminal Emulator"
    
    # Install dependencies for terminal emulators
    run_elevated pacman -S --noconfirm --needed \
        cmake freetype2 fontconfig pkg-config \
        2>&1 | grep -v "warning: insufficient columns"
    
    # Create config directories
    ensure_dir "$HOME/.config/wezterm"
    ensure_dir "$HOME/.config/alacritty"
    
    # Create WezTerm config with Rose Pine
    cat > "$HOME/.config/wezterm/wezterm.lua" << 'EOF'
local wezterm = require 'wezterm'
local config = {}

config.color_scheme = 'rose-pine-moon'
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

    # Create Alacritty config
    cat > "$HOME/.config/alacritty/alacritty.toml" << 'EOF'
[window]
opacity = 0.9
padding = { x = 18, y = 18 }
decorations = "full"
dynamic_title = true

[font]
size = 11.0
normal = { family = "JetBrains Mono", style = "Regular" }

[colors.primary]
background = '#232136'
foreground = '#e0def4'

[colors.normal]
black = '#393552'
red = '#eb6f92'
green = '#3e8fb0'
yellow = '#f6c177'
blue = '#9ccfd8'
magenta = '#c4a7e7'
cyan = '#ea9a97'
white = '#e0def4'
EOF
    
    # Add configs to chezmoi
    chezmoi add "$HOME/.config/wezterm/wezterm.lua"
    chezmoi add "$HOME/.config/alacritty/alacritty.toml"
    
    print_success "Terminal emulator configs created"
}
```

### 2. Install Modern CLI Tools

**Add this function to setup.sh:**

```bash
install_modern_cli_tools() {
    print_header "Installing Modern CLI Tools"
    
    # Install Rust if not present
    if ! command_exists cargo; then
        print_step "Installing Rust..."
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
        source "$HOME/.cargo/env"
    fi
    
    # Install modern replacements
    print_step "Installing modern CLI tools..."
    cargo install exa bat fd-find ripgrep bottom zoxide starship
    
    # Install additional tools from pacman
    run_elevated pacman -S --noconfirm --needed \
        lazygit ranger ncdu duf gdu \
        2>&1 | grep -v "warning: insufficient columns"
    
    print_success "Modern CLI tools installed"
}
```

### 3. Enhanced Neovim Setup with Rose Pine

**Replace the current `setup_nvim_config()` with:**

```bash
setup_enhanced_nvim() {
    print_header "Setting up Enhanced Neovim Configuration"
    
    # Install additional dependencies
    run_elevated pacman -S --noconfirm --needed \
        lua luarocks tree-sitter \
        2>&1 | grep -v "warning: insufficient columns"
    
    # Install language support
    pip install --user pynvim
    npm install -g neovim
    
    # Clone kickstart first
    TEMP_NVIM_DIR=$(mktemp -d)
    if $USE_GITHUB && [ -n "$GITHUB_USERNAME" ]; then
        git clone --depth=1 "https://github.com/$GITHUB_USERNAME/kickstart.nvim.git" "$TEMP_NVIM_DIR"
    else
        git clone --depth=1 https://github.com/nvim-lua/kickstart.nvim.git "$TEMP_NVIM_DIR"
    fi
    
    # Add Rose Pine configuration to init.lua
    cat >> "$TEMP_NVIM_DIR/init.lua" << 'EOF'

-- CUSTOM: Rose Pine Theme Configuration
require('lazy').setup({
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
  
  -- UI Enhancements
  {
    'akinsho/bufferline.nvim',
    version = "*",
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require('bufferline').setup({
        options = {
          separator_style = "thin",
          show_buffer_close_icons = false,
        },
      })
    end
  },
  
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
})

-- CUSTOM: Additional settings
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.wrap = false
EOF
    
    # Copy to config directory
    [ -d "$HOME/.config/nvim" ] && mv "$HOME/.config/nvim" "$HOME/.config/nvim.backup.$(date +%Y%m%d%H%M%S)"
    cp -r "$TEMP_NVIM_DIR" "$HOME/.config/nvim"
    
    # Add to chezmoi
    chezmoi add "$HOME/.config/nvim"
    
    rm -rf "$TEMP_NVIM_DIR"
    print_success "Enhanced Neovim configuration installed"
}
```

### 4. Starship Prompt Configuration

**Add this function:**

```bash
setup_starship_prompt() {
    print_header "Setting up Starship Prompt"
    
    # Install if not already installed via cargo
    if ! command_exists starship; then
        print_step "Installing Starship..."
        curl -sS https://starship.rs/install.sh | sh -s -- -y
    fi
    
    # Create Rose Pine themed config
    ensure_dir "$HOME/.config"
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
    
    # Add to chezmoi
    chezmoi add "$HOME/.config/starship.toml"
    
    # Update shell configs to use starship
    echo 'eval "$(starship init zsh)"' >> "$HOME/.zshrc"
    echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
    
    print_success "Starship prompt configured"
}
```

### 5. WSL-Specific Optimizations

**Add this function:**

```bash
setup_wsl_optimizations() {
    print_header "Applying WSL-Specific Optimizations"
    
    # Create WSL configuration
    print_step "Creating WSL configuration..."
    sudo tee /etc/wsl.conf > /dev/null << 'EOF'
[boot]
systemd=true

[interop]
enabled=true
appendWindowsPath=false

[network]
generateHosts=false
generateResolvConf=false
EOF
    
    # Add performance tweaks to shell configs
    cat >> "$HOME/.zshrc" << 'EOF'

# WSL2 Performance Optimizations
export WSL_INTEROP=/run/WSL/$(ls -1 /run/WSL | head -1)
export GIT_DISCOVERY_ACROSS_FILESYSTEM=1
export CHOKIDAR_USEPOLLING=1
export NODE_OPTIONS="--max-old-space-size=4096"

# Better ls with exa
alias ls='exa --icons --group-directories-first'
alias ll='exa -l --icons --group-directories-first'
alias la='exa -la --icons --group-directories-first'
alias tree='exa --tree --icons'

# Better cat with bat
alias cat='bat'

# Better find with fd
alias find='fd'

# Better grep with ripgrep
alias grep='rg'

# Better cd with zoxide
eval "$(zoxide init zsh)"
alias cd='z'
EOF
    
    print_success "WSL optimizations applied"
}
```

### 6. Interactive Theme Selector

**Add this function early in the script:**

```bash
select_theme() {
    print_header "Select Your Preferred Theme"
    
    echo -e "${BLUE}Choose a theme:${NC}"
    echo "1) Rose Pine (User's preference)"
    echo "2) Catppuccin"
    echo "3) Tokyo Night"
    echo "4) Nord"
    echo "5) Dracula"
    
    read -r theme_choice
    
    case $theme_choice in
        1) SELECTED_THEME="rose-pine" ;;
        2) SELECTED_THEME="catppuccin" ;;
        3) SELECTED_THEME="tokyo-night" ;;
        4) SELECTED_THEME="nord" ;;
        5) SELECTED_THEME="dracula" ;;
        *) SELECTED_THEME="rose-pine" ;;
    esac
    
    export SELECTED_THEME
    print_success "Selected theme: $SELECTED_THEME"
}
```

### 7. Enhanced Tmux Configuration

**Update the tmux setup to include Rose Pine theme:**

```bash
# In setup_tmux(), after creating the basic config, add:
cat >> "$TEMP_TMUX" << 'EOL'

# Rose Pine Moon theme
set -g status-style "bg=#232136,fg=#e0def4"
set -g status-left "#[bg=#ea9a97,fg=#232136,bold] #S #[bg=#232136,fg=#ea9a97]"
set -g status-right "#[fg=#3e8fb0]#[bg=#3e8fb0,fg=#232136] %Y-%m-%d #[fg=#c4a7e7,bg=#3e8fb0]#[bg=#c4a7e7,fg=#232136] %H:%M "
set -g window-status-format "#[fg=#6e6a86] #I:#W "
set -g window-status-current-format "#[fg=#232136,bg=#9ccfd8] #I:#W "
EOL
```

## Script Execution Order Updates

**Replace the main execution section with:**

```bash
# After bootstrap and initial setup
select_theme || SELECTED_THEME="rose-pine"
setup_workspace || exit 1
update_system || exit 1
install_core_deps || exit 1
setup_github_info || exit 1
setup_chezmoi || exit 1

# Enhanced installations
install_modern_cli_tools || exit 1
setup_modern_terminal || exit 1
install_fastfetch || print_warning "Fastfetch installation failed, continuing..."
install_neovim || exit 1
setup_enhanced_nvim || exit 1
setup_git_config || print_warning "Git config setup failed, continuing..."
setup_zsh || exit 1
setup_nodejs || exit 1
setup_starship_prompt || exit 1

# Configure dotfiles
setup_zshrc || exit 1
setup_tmux || exit 1
setup_wsl_utilities || exit 1
setup_wsl_optimizations || exit 1
setup_bashrc_helper || exit 1

# Optional tools and final setup
setup_claude_code || print_warning "Claude Code installation skipped or failed, continuing..."
create_component_docs || exit 1
create_update_script || exit 1
setup_dotfiles_repo || exit 1
```

## Font Installation

**Add this to the script:**

```bash
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
    
    print_success "Nerd Fonts installed"
}
```

## Key Implementation Notes

1. **Theme Flexibility**: While Rose Pine is the user's preference, the script should ask users for their choice
2. **Performance**: Avoid symlinks to Windows filesystem for configs
3. **Transparency**: Set to 0.9 opacity consistently across all tools
4. **Modern Tools**: Replace traditional Unix tools with modern alternatives (exa, bat, fd, rg)
5. **GPU Acceleration**: Enable in terminal emulators where possible
6. **Documentation**: Create clear docs for each component

## Testing Requirements

After implementation:
1. Verify Rose Pine theme applies everywhere
2. Check transparency works in terminal
3. Ensure all modern CLI tools are accessible
4. Test WSL performance optimizations
5. Verify chezmoi manages all configs properly
6. Ensure script works for fresh installs AND existing setups

## User Experience Goals

The final setup should:
- Look beautiful with Rose Pine and transparency
- Feel fast and responsive
- Be easy to customize for other users
- Work seamlessly with Windows tools
- Support modern development workflows