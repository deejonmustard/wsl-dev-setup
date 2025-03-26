**Usage Guide**
# Initial Setup

### **Uninstall Previous Installs:**
```bash
wsl --unregister Debian
```

###### **List Local Distro Installs w Version:**
```bash
wsl -l -v
# List official distros 
wsl -l -o 
```

### **Install From Store (More Updates):**
```bash
wsl.exe --install -d Debian
```

### **Launch Debian:**
```bash
wsl.exe -d Debian
```

##### set username and password

### **Basic Setup Commands:**
```bash
sudo apt update
sudo apt upgrade
sudo apt install curl
```

### **Run The Script:**
```bash
curl -o setup.sh https://raw.githubusercontent.com/deejonmustard/wsl-dev-setup/main/setup.sh && chmod +x setup.sh && ./setup.sh
```
**More Script Execution Info:**
```bash
# Download the script
curl -O https://raw.githubusercontent.com/deejonmustard/wsl-dev-setup/main/setup.sh

# Make it executable
chmod +x setup.sh

# Run the script
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
=======
# OR

# Clone the repository
git clone https://github.com/deejonmustard/wsl-dev-setup.git

# Navigate to the repository directory
cd wsl-dev-setup

# Make the script executable
chmod +x setup.sh

# Run the script
./setup.sh
```
# After Installation
Once the initial setup is complete, run the update script as prompted:
```bash
~/dev-env/update.sh
```
