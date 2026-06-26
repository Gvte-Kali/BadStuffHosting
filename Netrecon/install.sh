#!/bin/bash

# NetRecon - Automatic Installation Script
# This script will:
# 1. Install all required dependencies
# 2. Clone the NetRecon repository
# 3. Add netrecon to your PATH
# 4. Make the script executable

echo "[+] Starting NetRecon installation..."

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "[!] This script must be run as root. Use sudo."
    exit 1
fi

# Install dependencies
echo "[+] Installing dependencies..."
apt-get update -qq >/dev/null 2>&1
apt-get install -y -qq tcpdump arp-scan nmap bind9-host git >/dev/null 2>&1
echo "[+] Dependencies installed successfully."

# Clone the repository
echo "[+] Cloning NetRecon repository..."
REPO_URL="https://github.com/Gvte-Kali/BadStuffHosting.git"
INSTALL_DIR="/opt/netrecon"

# Create installation directory
mkdir -p "$INSTALL_DIR"

# Clone the repository (only the NetRecon directory)
if ! git clone --depth 1 --filter=blob:none --sparse "$REPO_URL" "$INSTALL_DIR" 2>/dev/null; then
    echo "[!] Failed to clone repository. Trying alternative method..."
    git clone "$REPO_URL" "$INSTALL_DIR" 2>/dev/null
fi

# Checkout only the NetRecon directory
cd "$INSTALL_DIR" || exit 1
git sparse-checkout init --cone 2>/dev/null
git sparse-checkout set Netrecon 2>/dev/null

# Make the script executable
echo "[+] Setting up NetRecon..."
chmod +x "$INSTALL_DIR/Netrecon/netrecon.sh"

# Add to PATH
echo "[+] Adding NetRecon to your PATH..."
SHELL_CONFIG="$HOME/.bashrc"

# Check if the user is using zsh
if [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
fi

# Add the PATH line if not already present
if ! grep -q "export PATH="$INSTALL_DIR/Netrecon:"$PATH" "$SHELL_CONFIG"; then
    echo "" >> "$SHELL_CONFIG"
    echo "# NetRecon" >> "$SHELL_CONFIG"
    echo "export PATH="$INSTALL_DIR/Netrecon:"$PATH"" >> "$SHELL_CONFIG"
    echo "[+] Added NetRecon to $SHELL_CONFIG"
else
    echo "[+] NetRecon is already in your PATH."
fi

# Source the shell config to update PATH in current session
source "$SHELL_CONFIG"

echo ""
echo "[+] NetRecon installation complete!"
echo "[+] You can now run 'netrecon.sh' from anywhere."
echo "[+] To start using it, run: sudo netrecon.sh"
