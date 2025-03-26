# Usage Guide

## Initial Setup

Run the script with:

```bash
./setup.sh

or:

curl -o setup.sh https://raw.githubusercontent.com/deejonmustard/wsl-dev-setup/main/setup.sh && chmod +x setup.sh && ./setup.sh

# Help

## uninstall previous installs 
wsl --unregister Debian

## list local distro installs w version
wsl -l -v
## list official distros 
wsl -l -o 

## install from store (more updates)
wsl.exe --install -d Debian

## launch Debian
wsl.exe -d Debian

*put in username and password*

# basic commands
sudp apt update
sudp apt upgrade
sudo apt install curl

# exec

curl -o setup.sh https://raw.githubusercontent.com/deejonmustard/wsl-dev-setup/main/setup.sh && chmod +x setup.sh && ./setup.sh