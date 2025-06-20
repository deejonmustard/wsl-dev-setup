# Your Kickstart-Modular.nvim Customization Guide

## Why Kickstart-Modular?

Unlike the standard kickstart.nvim with everything in one giant `init.lua`, kickstart-modular splits configuration into logical modules. This makes it easier to:
- Find specific settings
- Avoid merge conflicts when updating
- Add/remove features cleanly
- Understand what each part does

## Quick Start: Rose Pine with Transparency

### 1. Fork and Clone Kickstart-Modular
```bash
# Fork dam9000/kickstart-modular.nvim on GitHub first, then:
cd ~/.config
rm -rf nvim.backup
mv nvim nvim.backup  # Backup existing config
git clone https://github.com/YOUR_USERNAME/kickstart-modular.nvim.git nvim
cd nvim
git remote add upstream https://github.com/dam9000/kickstart-modular.nvim.git
```

### 2. Understanding the Modular Structure
```
~/.config/nvim/
├── init.lua                    # Entry point (loads everything)
├── lua/
│   ├── keymaps.lua            # Key mappings
│   ├── options.lua            # Vim options
│   ├── lazy-bootstrap.lua     # Plugin manager setup
│   └── lazy-plugins.lua       # Plugin configurations
└── lazy-lock.json             # Lock file for plugin versions
```

### 3. Add Rose Pine Theme

Create a new file `lua/plugins/colorscheme.lua`:

```lua
-- Rose Pine theme with transparency for WezTerm
return {
  'rose-pine/neovim',
  name = 'rose-pine',
  priority = 1000,
  config = function()
    require('rose-pine').setup({
      variant = 'moon', -- 'auto', 'main', 'moon', or 'dawn'
      dark_variant = 'moon',
      dim_inactive_windows = false,
      extend_background_behind_borders = true,

      styles = {
        bold = true,
        italic = true,
        transparency = true, -- Essential for your transparent WezTerm
      },

      -- Make certain elements transparent
      highlight_groups = {
        Normal = { bg = 'none' },
        NormalFloat = { bg = 'none' },
        FloatBorder = { bg = 'none' },
        Pmenu = { bg = 'none' },
        Terminal = { bg = 'none' },
        EndOfBuffer = { bg = 'none' },
        FoldColumn = { bg = 'none' },
        Folded = { bg = 'none' },
        SignColumn = { bg = 'none' },
        StatusLine = { bg = 'none' },
        StatusLineNC = { bg = 'none' },
        TelescopeNormal = { bg = 'none' },
        TelescopeBorder = { bg = 'none' },
      },
    })
    
    vim.cmd('colorscheme rose-pine')
  end,
}
```

### 4. Personal Options

Edit `lua/options.lua` and add your preferences:

```lua
-- Your existing options plus:
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.wrap = false
vim.opt.colorcolumn = "80"
vim.opt.termguicolors = true  -- Important for WezTerm colors
vim.opt.pumblend = 10         -- Popup menu transparency
vim.opt.winblend = 10         -- Window transparency
```

### 5. Enhanced UI Plugins

Create `lua/plugins/ui.lua`:

```lua
return {
  -- Status line that matches Rose Pine
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      require('lualine').setup({
        options = {
          theme = 'rose-pine',
          component_separators = '',
          section_separators = { left = '', right = '' },
        },
      })
    end,
  },

  -- File explorer (like VSCode)
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = 'nvim-tree/nvim-web-devicons',
    config = function()
      require('nvim-tree').setup({
        view = {
          width = 35,
          side = 'left',
        },
        renderer = {
          indent_markers = {
            enable = true,
          },
          icons = {
            glyphs = {
              folder = {
                arrow_closed = "",
                arrow_open = "",
              },
            },
          },
        },
      })
    end,
  },

  -- Better syntax highlighting
  {
    'nvim-treesitter/nvim-treesitter',
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter.configs').setup({
        ensure_installed = { 'lua', 'vim', 'vimdoc', 'javascript', 'typescript', 'python', 'bash' },
        highlight = { enable = true },
        indent = { enable = true },
      })
    end,
  },
}
```

### 6. Update Plugin Loading

Edit `lua/lazy-plugins.lua` to load your new plugin files:

```lua
require('lazy').setup({
  -- Existing plugins...
  
  -- Import your custom plugin configs
  { import = 'plugins' },
})
```

## WezTerm Setup for Neovim

### 1. Install WezTerm

**Windows**:
```powershell
# Using winget
winget install wez.wezterm

# Or download from https://wezfurlong.org/wezterm/
```

**WSL** (for native Linux WezTerm):
```bash
# Add repository
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/wezterm-fury.gpg
echo 'deb [signed-by=/etc/apt/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list

# Install
sudo apt update
sudo apt install wezterm
```

### 2. Your Enhanced WezTerm Configuration

Based on your preferences and the configs you like, here's an enhanced version:

Create `~/.config/wezterm/wezterm.lua` (or `%USERPROFILE%\.config\wezterm\wezterm.lua` on Windows):

```lua
local wezterm = require('wezterm')
local config = wezterm.config_builder()

-- Rose Pine Moon color scheme with proper transparency support
config.color_scheme = 'rose-pine-moon'

-- Custom color scheme if the built-in doesn't work perfectly
config.color_schemes = {
  ['rose-pine-moon'] = {
    foreground = '#e0def4',
    background = '#232136',
    cursor_bg = '#56526e',
    cursor_fg = '#e0def4',
    cursor_border = '#56526e',
    selection_fg = '#e0def4',
    selection_bg = '#44415a',
    
    ansi = {
      '#393552', -- black
      '#eb6f92', -- red
      '#3e8fb0', -- green (fixed from original)
      '#f6c177', -- yellow
      '#9ccfd8', -- blue
      '#c4a7e7', -- magenta
      '#ea9a97', -- cyan (fixed from original)
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
  },
}

-- Font configuration
config.font = wezterm.font_with_fallback({
  'JetBrainsMono Nerd Font',
  'JetBrains Mono',
  'Cascadia Code',
})
config.font_size = 11.0

-- Window appearance with transparency
config.window_background_opacity = 0.9  -- More readable than 0.1
config.macos_window_background_blur = 20  -- Works on Windows 11 too
config.win32_system_backdrop = 'Acrylic'  -- Windows 11 acrylic effect
config.window_decorations = 'INTEGRATED_BUTTONS|RESIZE'
config.window_padding = {
  left = 15,
  right = 15,
  top = 15,
  bottom = 15,
}

-- Cursor configuration
config.default_cursor_style = 'BlinkingBar'
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

-- Tab bar (inspired by the configs you liked)
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.use_fancy_tab_bar = false  -- Cleaner look
config.tab_max_width = 32

-- Scrolling
config.scrollback_lines = 10000
config.enable_scroll_bar = false

-- Performance
config.front_end = 'WebGpu'
config.webgpu_power_preference = 'HighPerformance'
config.max_fps = 120

-- Key bindings
config.keys = {
  -- Copy/Paste
  { key = 'c', mods = 'CTRL|SHIFT', action = wezterm.action.CopyTo('Clipboard') },
  { key = 'v', mods = 'CTRL|SHIFT', action = wezterm.action.PasteFrom('Clipboard') },
  
  -- Pane management (tmux-like)
  { key = '%', mods = 'CTRL|SHIFT', action = wezterm.action.SplitHorizontal({ domain = 'CurrentPaneDomain' }) },
  { key = '"', mods = 'CTRL|SHIFT', action = wezterm.action.SplitVertical({ domain = 'CurrentPaneDomain' }) },
  { key = 'h', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection('Left') },
  { key = 'j', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection('Down') },
  { key = 'k', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection('Up') },
  { key = 'l', mods = 'CTRL|SHIFT', action = wezterm.action.ActivatePaneDirection('Right') },
  { key = 'w', mods = 'CTRL|SHIFT', action = wezterm.action.CloseCurrentPane({ confirm = true }) },
  
  -- Tab management
  { key = 't', mods = 'CTRL|SHIFT', action = wezterm.action.SpawnTab('DefaultDomain') },
  { key = 'Tab', mods = 'CTRL', action = wezterm.action.ActivateTabRelative(1) },
  { key = 'Tab', mods = 'CTRL|SHIFT', action = wezterm.action.ActivateTabRelative(-1) },
  
  -- Font size
  { key = '+', mods = 'CTRL', action = wezterm.action.IncreaseFontSize },
  { key = '-', mods = 'CTRL', action = wezterm.action.DecreaseFontSize },
  { key = '0', mods = 'CTRL', action = wezterm.action.ResetFontSize },
  
  -- Search
  { key = 'f', mods = 'CTRL|SHIFT', action = wezterm.action.Search({ CaseSensitiveString = '' }) },
}

-- Default shell
if wezterm.target_triple == 'x86_64-pc-windows-msvc' then
  -- Windows: Use PowerShell 7 if available, otherwise Windows PowerShell
  config.default_prog = { 'pwsh.exe' }
  
  -- WSL integration
  config.launch_menu = {
    { label = 'PowerShell', args = { 'pwsh.exe' } },
    { label = 'Windows PowerShell', args = { 'powershell.exe' } },
    { label = 'Command Prompt', args = { 'cmd.exe' } },
    { label = 'Arch Linux (WSL)', args = { 'wsl.exe', '-d', 'archlinux' } },
  }
else
  -- Linux/macOS
  config.default_prog = { 'zsh' }
end

-- Disable ligatures for better code readability
config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' }

-- Bell
config.audible_bell = 'Disabled'
config.visual_bell = {
  fade_in_function = 'EaseIn',
  fade_in_duration_ms = 150,
  fade_out_function = 'EaseOut',
  fade_out_duration_ms = 150,
}

return config
```

### 3. WezTerm Tips for Neovim Users

**Multiplexing**: WezTerm has built-in pane/tab support, so you might not need tmux:
- `Ctrl+Shift+%`: Split horizontally
- `Ctrl+Shift+"`: Split vertically
- `Ctrl+Shift+h/j/k/l`: Navigate panes

**Neovim Integration**: Add to your `keymaps.lua`:
```lua
-- Terminal mode mappings for WezTerm
vim.keymap.set('t', '<C-h>', '<C-\\><C-n><C-w>h', { desc = 'Terminal: Go to left window' })
vim.keymap.set('t', '<C-j>', '<C-\\><C-n><C-w>j', { desc = 'Terminal: Go to lower window' })
vim.keymap.set('t', '<C-k>', '<C-\\><C-n><C-w>k', { desc = 'Terminal: Go to upper window' })
vim.keymap.set('t', '<C-l>', '<C-\\><C-n><C-w>l', { desc = 'Terminal: Go to right window' })
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Terminal: Enter normal mode' })
```

## Keeping Your Modular Config Updated

```bash
# Update from upstream
git fetch upstream
git checkout main
git merge upstream/main

# Your customizations are in separate files, so conflicts are rare!
# If there are conflicts, they'll likely be in init.lua or lazy-plugins.lua
```

## Troubleshooting

**Rose Pine not transparent?**
1. Ensure WezTerm opacity is set correctly (0.9 recommended)
2. Check that `transparency = true` in rose-pine setup
3. Windows 11 required for acrylic effect

**Fonts not working?**
```bash
# Install JetBrains Mono Nerd Font
# Windows: Download from https://www.nerdfonts.com/
# WSL/Linux:
mkdir -p ~/.local/share/fonts
cd ~/.local/share/fonts
curl -fLo "JetBrains Mono.zip" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip
unzip "JetBrains Mono.zip"
rm "JetBrains Mono.zip"
fc-cache -fv
```

**Performance issues?**
- Ensure WebGpu is working: `:checkhealth` in Neovim
- Try `config.front_end = 'OpenGL'` if WebGpu has issues

## Next Steps

1. Start with this base configuration
2. Use for a week to identify pain points
3. Add plugins to `lua/plugins/` as needed
4. Explore WezTerm's advanced features (SSH, multiplexing)
5. Consider removing tmux if WezTerm's panes work for you

The modular approach makes it easy to experiment - just create a new file in `lua/plugins/` and reload!