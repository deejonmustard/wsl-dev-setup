**Usage Guide**
# Initial Setup

### **Uninstall Previous Installs**
```bash
wsl --unregister Debian
```

### **List Local Distro Installs w Version**
```bash
wsl -l -v
# List official distros 
wsl -l -o 
```

### **Install From Store (More Updates)**
```bash
wsl.exe --install -d Debian
```

### **launch Debian**
```bash
wsl.exe -d Debian
```

### *Set username and password*


### **Basic commands**

```bash
sudo apt update
sudo apt upgrade
sudo apt install curl
```

**Run The Script**
```bash
curl -o setup.sh https://raw.githubusercontent.com/deejonmustard/wsl-dev-setup/main/setup.sh && chmod +x setup.sh && ./setup.sh
```
**Extra**
```bash
# Download the script
curl -O https://raw.githubusercontent.com/deejonmustard/wsl-dev-setup/main/setup.sh

# Make it executable
chmod +x setup.sh

# Run the script
./setup.sh

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
