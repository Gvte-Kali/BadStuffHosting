#!/bin/bash

# PharmaScan Installer
# Network discovery tool by b1g_ph4rm4

# Check root privileges
if [ "$(id -u)" -ne 0 ]; then
    echo "This installer requires root privileges. Please use sudo."
    exit 1
fi

# Banner
echo -e "\n\033[1;36mPharmaScan Network Discovery Tool Installer\033[0m"
echo -e "Created by b1g_ph4rm4\n"
echo -e "Features:"
echo -e "  - Passive/aggressive network scanning"
echo -e "  - Automatic interface configuration"
echo -e "  - IP range detection"
echo -e "  - Detailed help system (-h/--help)\n"

# ... [Le reste du script d'installation reste inchangé] ...

# Completion message
echo -e "\n\033[1;32mInstallation successful!\033[0m"
echo -e "\033[1mUsage:\033[0m"
echo -e "  pharmascan --passive    # Passive detection (default)"
echo -e "  pharmascan --aggressive # Active probing"
echo -e "  pharmascan --interface eth0 # Specify interface"
echo -e "  pharmascan -h           # Show detailed help\n"

if [ -n "$alias_file" ]; then
    echo -e "\033[1;33mNote:\033[0m Start a new terminal or run:"
    echo -e "  source $alias_file"
fi

# Version check
echo -e "\n\033[1;34mChecking latest version...\033[0m"
current_version=$(grep "^# Version:" "$install_path" | cut -d: -f2)
echo "Installed version: ${current_version:-1.0}"
