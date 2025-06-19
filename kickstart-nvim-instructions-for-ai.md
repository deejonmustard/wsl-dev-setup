# Kickstart.nvim Instructions for AI Implementation

## Core Ethos

The user wants to go from "1-100" with their Neovim setup, starting with kickstart.nvim as the foundation. Key principles:

1. **Incremental Enhancement**: Start minimal, add features based on actual need
2. **Personal Aesthetics**: Rose Pine theme with transparency is non-negotiable
3. **Maintainability**: Must be able to pull upstream updates without breaking custom configs
4. **Learning-Focused**: User is new to Neovim/Lua, needs clear explanations

## Research Findings

### Modern Neovim Ricing Trends (2025)
- **Themes**: Rose Pine, Catppuccin, Tokyo Night dominate
- **UI Philosophy**: "Functional beauty" over pure aesthetics
- **Performance**: Lazy loading and modular configs are standard
- **Transparency**: 0.85-0.95 opacity with blur effects

### Popular Enhancement Patterns
1. **File Trees**: nvim-tree or neo-tree (VSCode users expect this)
2. **Status Lines**: lualine with matching theme
3. **Git Integration**: gitsigns, fugitive
4. **Fuzzy Finding**: Telescope (already in kickstart)
5. **Terminal**: Built-in terminal with toggleterm or similar

### User's Specific Context
- Coming from VS Code
- Uses Windows with GlazeWM/YASB
- Wants transparency to work with their tiling setup
- Prefers Rose Pine aesthetics

## Implementation Guidelines

### Phase 1: Initial Setup (Current)
The script correctly:
- Installs latest Neovim from Arch repos
- Sets up kickstart.nvim
- Prompts for user's fork

### Phase 2: Required Enhancements
Add to the script:

```bash
setup_nvim_rose_pine() {
    print_header "Setting up Rose Pine theme for Neovim"
    
    # Create custom plugin directory
    ensure_dir "$HOME/.config/nvim/lua/custom/plugins"
    
    # Create Rose Pine config
    cat > "$HOME/.config/nvim/lua/custom/plugins/theme.lua" << 'EOF'
return {
  {
    'rose-pine/neovim',
    name = 'rose-pine',
    priority = 1000,
    config = function()
      require('rose-pine').setup({
        variant = 'moon',
        styles = { transparency = true },
      })
      vim.cmd('colorscheme rose-pine')
      vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
      vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
    end,
  },
}
EOF
    
    # Add to init.lua
    print_step "Adding custom plugins to init.lua..."
    # This needs careful insertion to not break kickstart structure
}
```

### Teaching Approach
When helping the user customize:

1. **Explain Line Numbers**: "Around line 300" helps them navigate
2. **Show Context**: Include surrounding code in examples
3. **Explain Why**: Each setting should have a purpose
4. **Incremental**: One plugin at a time

### Common Pitfalls to Avoid
1. Don't overwhelm with too many plugins initially
2. Don't break kickstart's update mechanism
3. Don't assume Lua knowledge - explain syntax
4. Don't forget terminal transparency requirements

## Script Integration Points

The current script's `setup_nvim_config` function should be enhanced to:

1. Detect if user wants customization immediately
2. Offer Rose Pine setup as an option
3. Create modular structure from the start
4. Add helper comments in the config

## Success Metrics

The user should be able to:
1. See transparent Rose Pine theme working immediately
2. Understand how to add one plugin
3. Know how to update from upstream
4. Feel confident to explore further

Remember: The goal is empowerment, not just configuration. Every addition should teach the user something about Neovim.