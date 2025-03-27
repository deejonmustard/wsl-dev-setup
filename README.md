# WSL Development Environment Setup

```
__        _______ _      _   _ ______     ______      _____  __  __   ____  _______        __
\ \      / / ____| |    | \ | | ____|   / ___\ \    / /_ _| \ \/ /  | __ )|_   _\ \      / /
 \ \ /\ / /|  _| | |    |  \| |  _|     \___ \\ \  / / | |   \  /   |  _ \  | |  \ \ /\ / / 
  \ V  V / | |___| |___ | |\  | |___     ___) |\ \/ /  | |   /  \   | |_) | | |   \ V  V /  
   \_/\_/  |_____|_____|_| \_|_____|   |____/  \__/  |___| /_/\_\  |____/  |_|    \_/\_/   
                                                                                            

```
__        _______ _     _   _ _______ _____     _____ __  __   ____  _______        __
\ \      / / ____| |   | \ | | ____\ \   / /   | __ )_  \/  | |  _ \__  /\ \      / /
 \ \ /\ / /|  _| | |   |  \| |  _|  \ \ / /    |  _ \| |\/| | | |_) |/ /  \ \ /\ / / 
  \ V  V / | |___| |__ | |\  | |___  \ V /     | |_) | |  | | |  _ </ /_   \ V  V /  
   \_/\_/  |_____|_____|_| \_|_____|  \_/      |____/|_|  |_| |_| \_\____|   \_/\_/   
                                                                                      

A simple script to set up a beginner-friendly development environment for WSL Debian.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## Features

- Neovim with Kickstart configuration
- Zsh with Oh My Zsh and plugins
- Tmux for terminal multiplexing
- Node.js via NVM
- Claude Code AI assistant
- Core development tools and utilities

## Quick Install

For a fresh Debian WSL installation, run:

```bash
# Update system and install curl first
sudo apt update
sudo apt upgrade -y
sudo apt install curl -y

# Download and run the setup script
curl -o setup.sh https://raw.githubusercontent.com/deejonmustard/wsl-dev-setup/main/setup.sh && chmod +x setup.sh && ./setup.sh
```

## What's Included

- **Core Tools**: git, ripgrep, fd-find, fzf, tmux, zsh, and more
- **Neovim**: Modern text editor with Kickstart configuration
- **Zsh**: Enhanced shell with Oh My Zsh and plugins
- **NVM**: Node Version Manager for JavaScript development
- **Claude Code**: AI assistant for coding
- **WSL Utilities**: Helper scripts for Windows integration

## Repository Structure

```
wsl-dev-setup/
├── .gitignore           # Git ignore rules
├── LICENSE              # MIT License
├── README.md            # This file
└── setup.sh             # Main setup script
```

## Updates

After installation, you can update your environment by running:

```bash
~/dev-env/update.sh
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
