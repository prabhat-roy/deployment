#!/bin/bash
set -e
# Function to detect and install curl on Debian/Ubuntu-based systems
install_debian() {
    echo "Installing curl on Debian/Ubuntu-based system..."
    sudo apt update
    sudo apt install -y curl
}

# Function to detect and install curl on RHEL/CentOS/Fedora-based systems
install_rhel() {
    echo "Installing curl on RHEL/CentOS/Fedora-based system..."
    sudo yum install -y curl    # For older versions (RHEL 7/CentOS 7)
    sudo dnf install -y curl    # For newer versions (RHEL 8/CentOS 8/Fedora)
}

# Check the distribution and call the corresponding installation function
if [ -f /etc/debian_version ]; then
    install_debian
elif [ -f /etc/redhat-release ]; then
    install_rhel
else
    echo "Unsupported Linux distribution!"
    exit 1
fi

echo "curl installation complete!"
