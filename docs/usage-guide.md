# WSL Development Environment - Usage Guide

## Initial Setup

### Uninstall Previous WSL Installs (if needed)
```bash
wsl --unregister Debian
```

### List Local Distro Installs
```bash
wsl -l -v
# List official distros 
wsl -l -o 
```

### Install Debian from Store
```bash
wsl.exe --install -d Debian
```

### Launch Debian and Configure
```bash
wsl.exe -d Debian
```
- When prompted, set your username and password

### Basic Setup Commands
```bash
sudo apt update
sudo apt upgrade -y
sudo apt install curl -y
```

### Run The Setup Script
```bash
curl -o setup.sh https://raw.githubusercontent.com/deejonmustard/wsl-dev-setup/main/setup.sh && chmod +x setup.sh && ./setup.sh
```

## After Installation

### Apply Changes
After the script completes, apply changes by either:
```bash
source ~/.bashrc
# or
source ~/.zshrc
```
Or simply restart your terminal.

### Using Neovim
Neovim is configured with the Kickstart configuration:
```bash
nvim
```

### Using Node.js (NVM)
The setup installs Node.js via NVM:
```bash
# Check installed Node versions
nvm ls

# Install a different version
nvm install 16

# Use a specific version
nvm use 14
```

### Using Claude Code
To use the Claude Code AI assistant:
```bash
# Navigate to your project
cd ~/my-project

# Start Claude Code
claude

# First-time authentication
claude auth login
```

### Using WSL Utilities
VS Code integration:
```bash
# Open current directory in VS Code
code-wrapper.sh
```

### Updating Your Environment
Run the update script periodically:
```bash
~/dev-env/update.sh
```
