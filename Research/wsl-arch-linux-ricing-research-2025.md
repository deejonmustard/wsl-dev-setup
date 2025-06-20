# Neovim Ricing: From Kickstart to Aesthetic Perfection

### Understanding Kickstart-Modular.nvim

Kickstart-modular.nvim is an improved version of kickstart.nvim that splits configuration into logical modules, making it perfect for ricing because:
- **Modular structure**: Each aspect (keymaps, options, plugins) in separate files
- **Easier customization**: Add new features without touching core files
- **Cleaner updates**: Merge conflicts are rare since your customizations are isolated
- **Better organization**: Find and modify specific settings quickly

### Complete Guide to Customizing Your Kickstart-Modular.nvim Fork

#### Why Fork Kickstart-Modular.nvim?

When you fork kickstart-modular.nvim, you create your own copy that you can modify without affecting the original. The modular structure makes this even more powerful:
1. Core functionality stays in the base files
2. Your customizations go in separate plugin files
3. Updates from upstream rarely conflict with your changes
4. Easy to share specific modules with others

#### Step-by-Step: Setting Up Your Fork

**1. Fork the Repository on GitHub**
   - Go to https://github.com/dam9000/kickstart-modular.nvim
   - Click the "Fork" button in the top right
   - This creates a copy under your GitHub account

**2. Clone YOUR Fork to WSL**
```bash
# First, backup any existing config
mv ~/.config/nvim ~/.config/nvim.backup

# Clone your fork (replace YOUR_GITHUB_USERNAME)
git clone https://github.com/YOUR_GITHUB_USERNAME/kickstart-modular.nvim.git ~/.config/nvim

# Enter the directory
cd ~/.config/nvim

# Add the original kickstart-modular as "upstream" for updates
git remote add upstream https://github.com/dam9000/kickstart-modular.nvim.git
```

**3. Understanding the Modular Structure**
```
~/.config/nvim/
├── init.lua               # Entry point, loads all modules
├── lua/
│   ├── keymaps.lua       # All key mappings
│   ├── options.lua       # Vim options
│   ├── lazy-bootstrap.lua # Plugin manager setup
│   ├── lazy-plugins.lua  # Plugin list
│   └── plugins/          # Your custom plugin configs go here
│       ├── colorscheme.lua
│       ├── ui.lua
│       └── editor.lua
└── lazy-lock.json        # Lock file for consistent plugin versions
```

#### Making Your First Customizations

**1. Create a Custom Branch**
```bash
# Create and switch to your custom branch
git checkout -b my-rice

# This keeps your changes separate from the main branch
```

**2. Set Your Options (lua/options.lua)**

```lua
-- Add these to the existing options
vim.opt.relativenumber = true    -- Relative line numbers
vim.opt.scrolloff = 8           -- Keep 8 lines visible when scrolling
vim.opt.wrap = false            -- Don't wrap lines
vim.opt.termguicolors = true    -- Enable 24-bit colors
vim.opt.pumblend = 10          -- Popup menu transparency
vim.opt.winblend = 10          -- Window transparency
vim.opt.fillchars = {
  eob = " ",                    -- Hide ~ at end of buffer
  fold = " ",
  foldopen = "",
  foldsep = " ",
  foldclose = "",
}
```

**3. Adding the Rose Pine Theme**

Create `lua/plugins/colorscheme.lua`:

```lua
-- Rose Pine theme with full transparency support
return {
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    priority = 1000,  -- Load before other plugins
    config = function()
      require('rose-pine').setup({
        variant = 'moon', -- 'auto', 'main', 'moon', or 'dawn'
        dark_variant = 'moon',
        dim_inactive_windows = false,
        extend_background_behind_borders = true,
        
        enable = {
          terminal = true,
          legacy_highlights = true,
          migrations = true,
        },
        
        styles = {
          bold = true,
          italic = true,
          transparency = true,  -- Enable transparency
        },
        
        highlight_groups = {
          -- Make everything transparent
          Normal = { bg = 'none' },
          NormalNC = { bg = 'none' },
          NormalFloat = { bg = 'none' },
          FloatBorder = { bg = 'none', fg = 'highlight_med' },
          FloatTitle = { bg = 'none' },
          
          -- UI elements
          StatusLine = { bg = 'none' },
          StatusLineNC = { bg = 'none' },
          TabLine = { bg = 'none' },
          TabLineFill = { bg = 'none' },
          
          -- Pmenu
          Pmenu = { bg = 'none' },
          PmenuSel = { bg = 'highlight_low' },
          
          -- Telescope
          TelescopeNormal = { bg = 'none' },
          TelescopeBorder = { bg = 'none', fg = 'highlight_high' },
          TelescopePromptNormal = { bg = 'none' },
          TelescopePromptBorder = { bg = 'none', fg = 'rose' },
          TelescopePromptTitle = { bg = 'none', fg = 'rose' },
          
          -- NvimTree
          NvimTreeNormal = { bg = 'none' },
          NvimTreeNormalNC = { bg = 'none' },
          NvimTreeWinSeparator = { bg = 'none', fg = 'highlight_med' },
          
          -- Neo-tree
          NeoTreeNormal = { bg = 'none' },
          NeoTreeNormalNC = { bg = 'none' },
        },
      })
      
      vim.cmd('colorscheme rose-pine')
      
      -- Additional transparency overrides
      vim.api.nvim_set_hl(0, "SignColumn", { bg = "none" })
      vim.api.nvim_set_hl(0, "EndOfBuffer", { bg = "none" })
      vim.api.nvim_set_hl(0, "FoldColumn", { bg = "none" })
    end,
  },
}
```

**4. UI Enhancements Module**

Create `lua/plugins/ui.lua`:

```lua
return {
  -- Status line with rose-pine theme
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = {
          theme = 'rose-pine',
          component_separators = '',
          section_separators = { left = '', right = '' },
          globalstatus = true,
        },
        sections = {
          lualine_a = { 'mode' },
          lualine_b = { 'branch', 'diff', 'diagnostics' },
          lualine_c = { { 'filename', path = 1 } },
          lualine_x = { 'encoding', 'fileformat', 'filetype' },
          lualine_y = { 'progress' },
          lualine_z = { 'location' }
        },
      })
    end,
  },
  
  -- File tree with icons
  {
    'nvim-neo-tree/neo-tree.nvim',
    branch = 'v3.x',
    dependencies = {
      'nvim-lua/plenary.nvim',
      'nvim-tree/nvim-web-devicons',
      'MunifTanjim/nui.nvim',
    },
    config = function()
      require('neo-tree').setup({
        window = {
          width = 35,
          mappings = {
            ['<space>'] = 'none',
          },
        },
        filesystem = {
          follow_current_file = {
            enabled = true,
          },
          use_libuv_file_watcher = true,
        },
      })
    end,
  },
  
  -- Indent guides
  {
    'lukas-reineke/indent-blankline.nvim',
    main = 'ibl',
    opts = {
      indent = {
        char = '│',
        tab_char = '│',
      },
      scope = { 
        enabled = true,
        show_start = true,
        show_end = false,
      },
      exclude = {
        filetypes = {
          'help',
          'dashboard',
          'neo-tree',
          'lazy',
          'mason',
        },
      },
    },
  },
  
  -- Better UI for notifications
  {
    'folke/noice.nvim',
    event = 'VeryLazy',
    dependencies = {
      'MunifTanjim/nui.nvim',
      'rcarriga/nvim-notify',
    },
    config = function()
      require('noice').setup({
        lsp = {
          override = {
            ['vim.lsp.util.convert_input_to_markdown_lines'] = true,
            ['vim.lsp.util.stylize_markdown'] = true,
            ['cmp.entry.get_documentation'] = true,
          },
        },
        presets = {
          bottom_search = true,
          command_palette = true,
          long_message_to_split = true,
          inc_rename = false,
          lsp_doc_border = false,
        },
      })
    end,
  },
  
  -- Dashboard
  {
    'goolord/alpha-nvim',
    event = 'VimEnter',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local alpha = require('alpha')
      local dashboard = require('alpha.themes.dashboard')
      
      -- Set header
      dashboard.section.header.val = {
        [[                                                    ]],
        [[     ██████╗  ██████╗ ███████╗███████╗             ]],
        [[     ██╔══██╗██╔═══██╗██╔════╝██╔════╝             ]],
        [[     ██████╔╝██║   ██║███████╗█████╗               ]],
        [[     ██╔══██╗██║   ██║╚════██║██╔══╝               ]],
        [[     ██║  ██║╚██████╔╝███████║███████╗             ]],
        [[     ╚═╝  ╚═╝ ╚═════╝ ╚══════╝╚══════╝             ]],
        [[                                                    ]],
        [[     ██████╗ ██╗███╗   ██╗███████╗                 ]],
        [[     ██╔══██╗██║████╗  ██║██╔════╝                 ]],
        [[     ██████╔╝██║██╔██╗ ██║█████╗                   ]],
        [[     ██╔═══╝ ██║██║╚██╗██║██╔══╝                   ]],
        [[     ██║     ██║██║ ╚████║███████╗                 ]],
        [[     ╚═╝     ╚═╝╚═╝  ╚═══╝╚══════╝                 ]],
        [[                                                    ]],
      }
      
      -- Set menu
      dashboard.section.buttons.val = {
        dashboard.button('f', '  Find file', ':Telescope find_files <CR>'),
        dashboard.button('e', '  New file', ':ene <BAR> startinsert <CR>'),
        dashboard.button('r', '  Recently used files', ':Telescope oldfiles <CR>'),
        dashboard.button('t', '  Find text', ':Telescope live_grep <CR>'),
        dashboard.button('c', '  Configuration', ':e ~/.config/nvim/init.lua <CR>'),
        dashboard.button('q', '  Quit Neovim', ':qa<CR>'),
      }
      
      alpha.setup(dashboard.opts)
    end,
  },
}
```

**5. Update Plugin Loading**

Edit `lua/lazy-plugins.lua` to include your custom modules:

```lua
require('lazy').setup({
  -- ... existing plugins ...
  
  -- Import all plugin files from lua/plugins/
  { import = 'plugins' },
}, {
  ui = {
    border = 'rounded',
  },
})
```

#### Keeping Your Fork Updated

The modular structure makes updates much easier:

```bash
# Fetch updates from original repo
git fetch upstream

# Switch to main branch
git checkout main

# Merge updates
git pull upstream main

# Switch back to your rice branch
git checkout my-rice

# Merge main into your branch
git merge main

# Conflicts are rare because your changes are in separate files!
```

### Neovim Ricing Best Practices for Modular Setup

1. **One Feature Per File**: Create separate files in `lua/plugins/` for different features
2. **Meaningful Names**: Use descriptive filenames like `telescope-config.lua`, `lsp-setup.lua`
3. **Document Your Rice**: Add comments explaining why you chose specific settings
4. **Version Control**: Commit each feature separately for easy rollback
5. **Performance Monitoring**: Use `:Lazy profile` to check plugin load times

## Terminal Customization for WSL

### WezTerm: The Ultimate Terminal for WSL Ricing

WezTerm has become the go-to terminal for modern ricing due to its:
- **Native GPU acceleration** with WebGPU support
- **True transparency** with blur effects on Windows 11
- **Lua configuration** (same language as Neovim!)
- **Built-in multiplexing** (can replace tmux)
- **Excellent WSL integration**

#### WezTerm Installation

**On Windows (Recommended for WSL)**:
```powershell
# Using winget
winget install wez.wezterm

# Or using Scoop
scoop bucket add extras
scoop install wezterm

# Or using Chocolatey
choco install wezterm
```

**Direct in WSL** (if you prefer native Linux WezTerm):
```bash
# For Arch Linux
yay -S wezterm

# Or build from source
sudo pacman -S --needed base-devel rustup cmake
rustup default stable
git clone --depth=1 --branch=main --recursive https://github.com/wez/wezterm.git
cd wezterm
cargo build --release
sudo cp target/release/wezterm /usr/local/bin/
```

#### Advanced WezTerm Configuration for Rose Pine

Create `~/.config/wezterm/wezterm.lua`:

```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Color Scheme: Rose Pine Moon with proper colors
config.color_schemes = {
  ['rose-pine-moon'] = {
    foreground = '#e0def4',
    background = '#232136',
    cursor_bg = '#56526e',
    cursor_fg = '#e0def4',
    cursor_border = '#56526e',
    
    selection_fg = '#e0def4',
    selection_bg = '#44415a',
    
    scrollbar_thumb = '#56526e',
    split = '#56526e',
    
    ansi = {
      '#393552', -- black
      '#eb6f92', -- red
      '#3e8fb0', -- green (fixed)
      '#f6c177', -- yellow
      '#9ccfd8', -- blue
      '#c4a7e7', -- magenta
      '#ea9a97', -- cyan (fixed)
      '#e0def4', -- white
    },
    
    brights = {
      '#6e6a86', -- bright black
      '#eb6f92', -- bright red
      '#3e8fb0', -- bright green
      '#f6c177', -- bright yellow
      '#9ccfd8', -- bright blue
      '#c4a7e7', -- bright magenta
      '#ea9a97', -- bright cyan
      '#e0def4', -- bright white
    },
    
    -- Extended colors for better integration
    indexed = {
      [16] = '#f6c177',
      [17] = '#eb6f92',
    },
    
    -- Tab bar colors
    tab_bar = {
      background = '#191724',
      active_tab = {
        bg_color = '#232136',
        fg_color = '#e0def4',
      },
      inactive_tab = {
        bg_color = '#191724',
        fg_color = '#6e6a86',
      },
      inactive_tab_hover = {
        bg_color = '#232136',
        fg_color = '#e0def4',
      },
      new_tab = {
        bg_color = '#191724',
        fg_color = '#6e6a86',
      },
      new_tab_hover = {
        bg_color = '#232136',
        fg_color = '#e0def4',
      },
    },
  },
}

config.color_scheme = 'rose-pine-moon'

-- Font Configuration
config.font = wezterm.font_with_fallback({
  {
    family = 'JetBrainsMono Nerd Font',
    weight = 'Regular',
    harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }, -- Disable ligatures
  },
  'JetBrains Mono',
  'Cascadia Code',
  'Consolas',
})

config.font_size = 11.0
config.line_height = 1.2
config.cell_width = 1.0

-- Window Configuration
config.window_background_opacity = 0.85
config.macos_window_background_blur = 20
config.win32_system_backdrop = 'Acrylic'
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.integrated_title_button_style = 'Windows'
config.integrated_title_buttons = { 'Hide', 'Maximize', 'Close' }

config.window_padding = {
  left = 20,
  right = 20,
  top = 20,
  bottom = 20,
}

-- Tab Bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = false
config.tab_max_width = 32
config.show_tab_index_in_tab_bar = true
config.switch_to_last_active_tab_when_closing_tab = true

-- Cursor
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500
config.cursor_thickness = 2
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

-- Scrolling
config.scrollback_lines = 10000
config.enable_scroll_bar = false
config.min_scroll_bar_height = '2cell'
config.colors = {
  scrollbar_thumb = '#56526e',
}

-- Performance
config.front_end = 'WebGpu'
config.webgpu_power_preference = 'HighPerformance'
config.max_fps = 120
config.animation_fps = 60
config.enable_wayland = false -- Better performance on WSL

-- Bell
config.audible_bell = 'Disabled'
config.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_in_duration_ms = 150,
  fade_out_function = 'EaseOut',
  fade_out_duration_ms = 300,
  target = 'CursorColor',
}

-- Key Bindings
config.keys = {
  -- Pane Management (Tmux-like)
  { key = '%', mods = 'CTRL|SHIFT', action = wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
  { key = '"', mods = 'CTRL|SHIFT', action = wezterm.action.SplitVertical({ domain = 'CurrentPaneDomain' }) },
  { key = 'h', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection('Left') },
  { key = 'j', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection('Down') },
  { key = 'k', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection('Up') },
  { key = 'l', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection('Right') },
  { key = 'x', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentPane({ confirm = true }) },
  { key = 'z', mods = 'CTRL|SHIFT', action = wezterm.action.TogglePaneZoomState },
  
  -- Tab Management
  { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab('CurrentPaneDomain') },
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentTab({ confirm = true }) },
  { key = 'Tab', mods = 'CTRL', action = wezterm.action.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(-1) },
  
  -- Copy/Paste
  { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo('Clipboard') },
  { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom('Clipboard') },
  
  -- Font Size
  { key = '=', mods = 'CTRL', action = wezterm.action.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = wezterm.action.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = wezterm.action.ResetFontSize },
  
  -- Search
  { key = 'f', mods = 'CTRL|SHIFT', action = wezterm.action.Search({ CaseSensitiveString = '' }) },
  
  -- Quick Actions
  { key = 'p', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateCommandPalette },
  { key = 'l', mods = 'CTRL|SHIFT|ALT', action = wezterm.action.ShowDebugOverlay },
}

-- Mouse Bindings
config.mouse_bindings = {
  {
    event = { Up = { streak = 1, button = 'Right' } },
    mods = 'NONE',
    action = wezterm.action.PasteFrom('Clipboard'),
  },
}

-- Launch Menu for Windows
if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  config.launch_menu = {
    { label = 'PowerShell 7', args = { 'pwsh.exe', '-NoLogo' } },
    { label = 'Windows PowerShell', args = { 'powershell.exe', '-NoLogo' } },
    { label = 'Command Prompt', args = { 'cmd.exe' } },
    { label = 'Arch Linux', args = { 'wsl.exe', '-d', 'archlinux' } },
    { label = 'Arch Linux (home)', args = { 'wsl.exe', '-d', 'archlinux', '--cd', '~' } },
  }
  
  -- Default to WSL
  config.default_prog = { 'wsl.exe', '-d', 'archlinux' }
else
  config.default_prog = { 'zsh' }
end

return config
```

#### WezTerm + Neovim Integration Tips

1. **Seamless Navigation**: Add to your Neovim config:
```lua
-- Smart split navigation that works with WezTerm
vim.keymap.set('n', '<C-h>', function()
  if vim.fn.winnr() == vim.fn.winnr('h') then
    vim.fn.system('wezterm cli activate-pane-direction Left')
  else
    vim.cmd('wincmd h')
  end
end)
```

2. **True Color Support**: Already enabled with `termguicolors`

3. **Clipboard Integration**: Works out of the box with WezTerm

4. **Performance Optimization**: WezTerm's GPU acceleration makes Neovim incredibly smooth
```

## Script Improvement Suggestions

### Current Script Analysis

Your script provides a solid foundation (0-1), but here are improvements to reach 100:

### 1. Add WezTerm Setup
```bash
# Add to setup.sh after terminal emulator configurations
setup_wezterm() {
    print_header "Installing and Configuring WezTerm"
    
    # WezTerm is installed on Windows side, so we just configure it
    print_step "Creating WezTerm configuration..."
    
    # Create config directory
    ensure_dir "$HOME/.config/wezterm"
    
    # Create WezTerm config with Rose Pine Moon
    cat > "$HOME/.config/wezterm/wezterm.lua" << 'EOF'
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

-- Rose Pine Moon color scheme
config.color_scheme = 'rose-pine-moon'

-- Font configuration
config.font = wezterm.font_with_fallback({
  'JetBrainsMono Nerd Font',
  'JetBrains Mono',
  'Cascadia Code',
})
config.font_size = 11.0

-- Window appearance with transparency
config.window_background_opacity = 0.9
config.win32_system_backdrop = 'Acrylic'
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_padding = {
  left = 20,
  right = 20,
  top = 20,
  bottom = 20,
}

-- Tab bar
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false

-- Performance
config.front_end = 'WebGpu'
config.max_fps = 120

-- Default to WSL
if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  config.default_prog = { 'wsl.exe', '-d', 'archlinux' }
  config.launch_menu = {
    { label = 'PowerShell 7', args = { 'pwsh.exe' } },
    { label = 'Arch Linux', args = { 'wsl.exe', '-d', 'archlinux' } },
  }
end

return config
EOF
    
    # Add config to chezmoi
    safe_add_to_chezmoi "$HOME/.config/wezterm/wezterm.lua" "WezTerm configuration" || true
    
    print_success "WezTerm configuration created"
    print_step "Install WezTerm on Windows: winget install wez.wezterm"
}
```

### 2. Enhanced Neovim Setup with Kickstart-Modular
```bash
# Replace setup_nvim_config with modular version
setup_nvim_modular_config() {
    print_header "Setting up Neovim with Kickstart-Modular"
    print_step "Setting up modular Kickstart Neovim configuration..."

    # Create a temporary directory for cloning kickstart-modular
    TEMP_NVIM_DIR=$(mktemp -d)
    
    # Check if user has a fork
    if $USE_GITHUB && [ -n "$GITHUB_USERNAME" ]; then
        echo -e "\n${BLUE}Do you have your own fork of kickstart-modular.nvim? (y/n)${NC}"
        read -r has_fork
        
        if [[ "$has_fork" =~ ^[Yy]$ ]]; then
            print_step "Cloning from your fork..."
            git clone --depth=1 "https://github.com/$GITHUB_USERNAME/kickstart-modular.nvim.git" "$TEMP_NVIM_DIR"
        else
            print_step "Cloning official kickstart-modular.nvim..."
            git clone --depth=1 https://github.com/dam9000/kickstart-modular.nvim.git "$TEMP_NVIM_DIR"
        fi
    else
        git clone --depth=1 https://github.com/dam9000/kickstart-modular.nvim.git "$TEMP_NVIM_DIR"
    fi
    
    # Create custom plugin directories
    mkdir -p "$TEMP_NVIM_DIR/lua/plugins"
    
    # Create Rose Pine theme config
    cat > "$TEMP_NVIM_DIR/lua/plugins/colorscheme.lua" << 'EOF'
return {
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    priority = 1000,
    config = function()
      require('rose-pine').setup({
        variant = 'moon',
        styles = {
          transparency = true,
        },
      })
      vim.cmd('colorscheme rose-pine')
    end,
  },
}
EOF
    
    # Move to nvim config directory
    if [ -d "$HOME/.config/nvim" ]; then
        backup_file "$HOME/.config/nvim"
    fi
    cp -r "$TEMP_NVIM_DIR" "$HOME/.config/nvim"
    
    # Add to chezmoi
    chezmoi add "$HOME/.config/nvim"
    
    rm -rf "$TEMP_NVIM_DIR"
    
    print_success "Modular Neovim configuration installed"
    return 0
}
```

### 3. Add Modern CLI Tools
```bash
# Enhanced modern tools installation
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
    return 0
}
```

### 4. Add Development Environment Enhancements
```bash
# New function for enhanced shell setup
setup_enhanced_shell() {
    print_header "Setting up Enhanced Shell Environment"
    
    # Add modern aliases and functions to zshrc
    cat >> "$HOME/.zshrc" << 'EOF'

# Modern CLI replacements
alias ls='exa --icons --group-directories-first'
alias ll='exa -l --icons --group-directories-first'
alias la='exa -la --icons --group-directories-first'
alias tree='exa --tree --icons'
alias cat='bat'
alias find='fd'
alias grep='rg'
alias top='btop'
alias htop='btop'

# Better cd with zoxide
eval "$(zoxide init zsh)"
alias cd='z'

# Git enhancements with lazygit
alias lg='lazygit'

# Quick edit configs
alias ezsh='chezmoi edit ~/.zshrc'
alias envim='chezmoi edit ~/.config/nvim/init.lua'
alias ewez='chezmoi edit ~/.config/wezterm/wezterm.lua'

# WSL specific
alias windir='cd $(wslpath "$(wslvar USERPROFILE)")'
alias downloads='cd $(wslpath "$(wslvar USERPROFILE)")/Downloads'
EOF
    
    # Update chezmoi
    safe_add_to_chezmoi "$HOME/.zshrc" "Enhanced Zsh configuration" --force || true
    
    print_success "Enhanced shell environment configured"
}
```

### 5. Interactive Theme Selector
```bash
# Add theme selection to make setup more flexible
select_theme() {
    print_header "Select Your Preferred Theme"
    
    echo -e "${BLUE}Choose a theme:${NC}"
    echo "1) Rose Pine (Your preference)"
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

### 6. WSL-Specific Optimizations
```bash
# WSL performance optimizations
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
```

### Script Execution Order Update
```bash
# Updated main execution flow
# ... (after existing setup)

# Add new functions to main execution
select_theme || exit 1
install_modern_cli_tools || exit 1
setup_wezterm || exit 1
setup_nvim_modular_config || exit 1  # Replace old nvim setup
setup_enhanced_shell || exit 1
setup_wsl_optimizations || exit 1

# Update display_completion_message to include new features
```

## Recommended Setup Workflow

### Phase 1: Foundation (Current Script)
1. ✅ WSL Arch Linux installation
2. ✅ Basic development tools
3. ✅ Chezmoi for dotfile management
4. ✅ Zsh + Oh-My-Zsh
5. ✅ Basic Neovim with kickstart-modular

### Phase 2: Terminal Enhancement (0-25)
1. Install WezTerm on Windows
2. Configure transparency and Rose Pine theme
3. Set up Starship prompt with rose-pine theme
4. Install modern CLI tools (exa, bat, ripgrep, etc.)
5. Configure tmux with rose-pine theme (optional with WezTerm)

### Phase 3: Neovim Powerhouse (25-50)
1. Fork kickstart-modular.nvim
2. Add rose-pine with transparency
3. Create custom plugin modules
4. Configure LSP for your languages
5. Add file tree, fuzzy finder, and git integration

### Phase 4: Workflow Optimization (50-75)
1. Set up project templates
2. Configure language-specific tools
3. Add AI integration (GitHub Copilot, Codeium)
4. Create custom keybindings
5. Optimize for your specific workflows

### Phase 5: Advanced Integration (75-100)
1. Seamless Windows/WSL file sharing
2. Unified clipboard management
3. Git credential sharing
4. VS Code integration for when needed
5. Automated environment updates

### Quick Start Commands

```bash
# After running your current script, execute:

# 1. Install WezTerm on Windows
winget install wez.wezterm

# 2. Apply the enhanced configuration
./setup.sh  # With the improvements above

# 3. Install modern CLI tools
cargo install exa bat fd-find ripgrep bottom

# 4. Clone your modular Neovim config
cd ~/.config
git clone https://github.com/YOUR_USERNAME/kickstart-modular.nvim.git nvim

# 5. Update shell configuration
source ~/.zshrc
```

## Conclusion

Your journey from 0-100 in WSL Arch Linux ricing is about building a cohesive, beautiful, and functional development environment. The key principles:

1. **Consistency**: Rose Pine theme across all tools
2. **Performance**: GPU-accelerated WezTerm, fast tools
3. **Modularity**: Kickstart-modular for easy Neovim customization
4. **Integration**: Seamless WSL-Windows interaction
5. **Functionality**: Every aesthetic choice should improve workflow

With your current Windows setup (GlazeWM, YASB, Flow Launcher) and this enhanced WSL environment with WezTerm and kickstart-modular.nvim, you'll have a development setup that rivals any native Linux or macOS configuration while maintaining the benefits of Windows.

Remember: ricing is iterative. Start with WezTerm and kickstart-modular, then gradually enhance based on your actual usage patterns. The modular approach makes it easy to experiment without breaking your core setup!