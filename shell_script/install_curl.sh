#!/bin/bash
set -euo pipefail
# Function to check if curl is already installed
check_installed() {
  if command -v curl &> /dev/null; then
    echo "curl is already installed."
    curl --version
    return 0
  else
    return 1
  fi
}

# Function to detect and install curl on Debian/Ubuntu-based systems
install_debian() {
    echo "Installing curl on Debian/Ubuntu-based system..."
    sudo apt update
    sudo apt install -y curl
    curl --version
}

# Function to detect and install curl on RHEL/CentOS/Fedora-based systems
install_rhel() {
    echo "Installing curl on RHEL/CentOS/Fedora-based system..."
    sudo yum install -y curl    # For older versions (RHEL 7/CentOS 7)
    sudo dnf install -y curl    # For newer versions (RHEL 8/CentOS 8/Fedora)
    curl --version
}

# Check if curl is installed, if not, detect the distribution and install it
if check_installed "curl"; then
    echo "curl is already installed."
else
    if [ -f /etc/debian_version ]; then
        install_debian
    elif [ -f /etc/redhat-release ]; then
        install_rhel
    else
        echo "Unsupported Linux distribution!"
        exit 1
    fi
fi

echo "curl installation complete!"
