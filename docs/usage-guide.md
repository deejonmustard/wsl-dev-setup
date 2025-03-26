# Usage Guide
Initial Setup

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

*set username and password*

# Basic commands
sudo apt update
sudo apt upgrade
sudo apt install curl


# Run the script with:
curl -o setup.sh https://raw.githubusercontent.com/deejonmustard/wsl-dev-setup/main/setup.sh && chmod +x setup.sh && ./setup.sh
