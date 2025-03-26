# WSL Development Environment Setup

A script to set up an optimized development environment in WSL Debian.

## Features

1. **Shell**: Zsh with essential plugins (not overwhelming)
2. **Terminal Multiplexer**: Tmux with intuitive keybindings
3. **Editor**: NeoVim with Kickstart configuration
4. **Navigation**: Zoxide, fzf, and ripgrep for fast movement
5. **WSL Utilities**: Path fixing and Windows integration tools
6. **Git**: Essential aliases and shortcuts

## Usage

See the [usage guide](docs/usage-guide.md) for detailed instructions.

### How to Customize Your Environment

The `editconfig` command (aliased as `ec`) makes it easy to modify your environment:

1. Type `ec` in your terminal
2. Select the configuration you want to edit
3. Make your changes and save
4. Run `~/dev-env/update.sh` to apply changes

### Adding New Tools

To add a new development tool:

1. Edit the appropriate Ansible role:
   ```bash
   nvim ~/dev-env/ansible/roles/core-tools/tasks/main.yml
   ```

### Key Improvements

1. **Fixed Ansible Installation**: Removed the problematic pip-based Ansible installation.

2. **Added 1Password CLI**: Properly integrated the 1Password CLI with their recommended installation method.

3. **Added GitHub Credentials**: Configured Git with your GitHub username and email.

4. **Made It Personal**: Added customizations including welcome messages and personal references.

5. **Fixed Heredoc Issues**: Ensured all heredocs are properly terminated.

6. **Created Better Documentation**: Added comprehensive guides for editors and a learning path.

7. **Added Configuration Editor**: Created an `ec` script for quick edits to config files.

8. **Organized Everything**: Set up a modular structure in `~/dev-env` with configs, docs, and bin directories.

9. **Added Rose Pine Theme**: Configured Neovim to use the Rose Pine theme (falling back gracefully if not available).

10. **Created `config.env`**: Added the environment variable file from your previous chat.
