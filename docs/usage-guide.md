**Usage Guide**
# Initial Setup

### **Uninstall previous installs**
```
wsl --unregister Debian
```

### **List local distro installs w version number**
```
wsl -l -v
```

### **List official distros** 
```
wsl -l -o 
```

### **Install from store (more updates)**
```
wsl.exe --install -d Debian
```

### **launch Debian**
```
wsl.exe -d Debian
```

### *Set username and password*


### **Basic commands**

```
sudo apt update
sudo apt upgrade
sudo apt install curl
```

**Run the script**
```
curl -o setup.sh https://raw.githubusercontent.com/deejonmustard/wsl-dev-setup/main/setup.sh && chmod +x setup.sh && ./setup.sh
```
