# WSL Development Environment Setup

```
                _                         _           _       _           
__      ___ __ | |  _ __   ___  _____   _(_)_ __ ___ | |__  | |___      __
\ \ /\ / / '_ \| | | '_ \ / _ \/ _ \ \ / / | '_ ` _ \| '_ \ | __\ \ /\ / /
 \ V  V /| | | | | | | | |  __/ (_) \ V /| | | | | | | |_) || |_ \ V  V / 
  \_/\_/ |_| |_|_| |_| |_|\___|\___/ \_/ |_|_| |_| |_|_.__/  \__| \_/\_/  
                                                                          

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
