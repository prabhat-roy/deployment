#!/bin/bash
set -euo pipefail

# Check if Node.js is installed
if command -v node &>/dev/null; then
    echo "Node.js is already installed."
    node --version
    exit 0
else
    echo "Node.js is not installed, proceeding with installation..."
fi

# Check distribution and install Node.js accordingly
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu based
    echo "Detected Debian/Ubuntu based system"
    
    # Update package list and install curl if not already installed
    sudo apt-get update -y
    sudo apt-get install -y curl

    # Fetch the setup script for LTS Node.js
    curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -

    # Install Node.js
    sudo apt-get install -y nodejs

elif [ -f /etc/redhat-release ]; then
    # RHEL/CentOS/Fedora based
    echo "Detected RHEL/CentOS/Fedora based system"
    
    # Install curl if not already installed
    sudo yum install -y curl

    # Fetch the setup script for Node.js
    curl -sL https://rpm.nodesource.com/setup_lts.x | sudo -E bash -

    # Install Node.js
    sudo yum install -y nodejs

else
    echo "Unsupported OS. Exiting."
    exit 1
fi

# Verify installation
node --version
