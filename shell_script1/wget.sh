#!/bin/bash
set -euo pipefail

# Check if wget is installed
if command -v wget &>/dev/null; then
    echo "wget is already installed."
    wget --version
    exit 0
else
    echo "wget is not installed, proceeding with installation..."
fi

# Check distribution and install wget accordingly
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu based
    echo "Detected Debian/Ubuntu based system"
    
    # Update package list and install wget
    sudo apt-get update -y
    sudo apt-get install -y wget

elif [ -f /etc/redhat-release ]; then
    # RHEL/CentOS/Fedora based
    echo "Detected RHEL/CentOS/Fedora based system"
    
    # Install wget
    sudo yum install -y wget

else
    echo "Unsupported OS. Exiting."
    exit 1
fi

# Verify installation
wget --version
