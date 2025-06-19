# Your Kickstart.nvim Customization Guide

## Quick Start: Rose Pine with Transparency

Since you want Rose Pine with transparent backgrounds, here's exactly what to do after cloning your kickstart.nvim fork:

### 1. Fork and Clone
```bash
# Fork kickstart.nvim on GitHub first, then:
cd ~/.config/nvim
git clone https://github.com/YOUR_USERNAME/kickstart.nvim.git .
git remote add upstream https://github.com/nvim-lua/kickstart.nvim.git
```

### 2. Add Rose Pine (Line ~300 in init.lua)
Find where other plugins are defined and add:

```lua
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
    vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
    vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
  end,
},
```

### 3. Your Personal Preferences (Line ~100)
Add these settings for a better experience:

```lua
vim.opt.relativenumber = true
vim.opt.scrolloff = 8
vim.opt.wrap = false
vim.opt.colorcolumn = "80"
```

### 4. Keeping Updated
```bash
# Weekly/monthly update routine
git fetch upstream
git checkout main
git pull upstream main
git checkout your-branch
git merge main
# Fix any conflicts, test, commit
```

## Going Further: Making It Yours

### Essential Plugins for Your Workflow

1. **File Explorer** (since you use VS Code, you'll want this):
```lua
{
  'nvim-tree/nvim-tree.lua',
  dependencies = 'nvim-tree/nvim-web-devicons',
  config = function()
    require('nvim-tree').setup({
      view = { width = 30, side = 'left' },
      renderer = { indent_markers = { enable = true } },
    })
  end,
},
```

2. **Better Status Line**:
```lua
{
  'nvim-lualine/lualine.nvim',
  config = function()
    require('lualine').setup({
      options = { theme = 'rose-pine' },
    })
  end,
},
```

3. **Terminal Integration** (like VS Code's integrated terminal):
```lua
-- Add to keymaps section
vim.keymap.set('n', '<leader>t', ':split | terminal<CR>', { desc = 'Open terminal' })
```

### Modular Configuration (When You're Ready)

Instead of one big init.lua:

```
~/.config/nvim/
├── init.lua (loads modules)
├── lua/
│   └── custom/
│       ├── options.lua (your settings)
│       ├── keymaps.lua (your shortcuts)
│       └── plugins/
│           ├── ui.lua (rose-pine, lualine, etc.)
│           └── editor.lua (file tree, etc.)
```

### Your Most Common Tasks

**Quick save**: Add to keymaps
```lua
vim.keymap.set('n', '<C-s>', ':w<CR>', { desc = 'Save file' })
```

**Better window navigation**:
```lua
vim.keymap.set('n', '<C-h>', '<C-w>h', { desc = 'Go to left window' })
vim.keymap.set('n', '<C-j>', '<C-w>j', { desc = 'Go to lower window' })
vim.keymap.set('n', '<C-k>', '<C-w>k', { desc = 'Go to upper window' })
vim.keymap.set('n', '<C-l>', '<C-w>l', { desc = 'Go to right window' })
```

## Troubleshooting

**Rose Pine not loading?**
- Run `:Lazy` and press `I` to install
- Make sure you have `termguicolors` enabled

**Transparency not working?**
- WezTerm/Alacritty required (Windows Terminal has limited support)
- Check terminal opacity settings

**Lost after merge conflict?**
- Your changes are in git: `git reflog`
- Kickstart changes are usually in plugin definitions
- Your changes are usually settings/keymaps

## Next Steps

1. Start with just Rose Pine
2. Use it for a week
3. Add one plugin at a time based on what you miss from VS Code
4. Join r/neovim for inspiration (but don't copy everything!)

Remember: The goal is a config that works for YOU, not the prettiest rice on Reddit.