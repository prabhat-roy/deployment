#!/bin/bash
set -euo pipefail

# Check if Python is installed
if command -v python3 &>/dev/null; then
    echo "Python is already installed."
    python3 --version
    exit 0
else
    echo "Python is not installed, proceeding with installation..."
fi

# Check distribution and install Python accordingly
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu based
    echo "Detected Debian/Ubuntu based system"
    
    # Update package list and install dependencies
    sudo apt-get update -y
    sudo apt-get install -y software-properties-common

    # Add the deadsnakes PPA (for latest Python versions)
    sudo add-apt-repository ppa:deadsnakes/ppa -y
    sudo apt-get update -y

    # Install Python 3, development tools, and headers
    sudo apt-get install -y python3 python3-pip python3-dev build-essential

    # Install additional useful Python tools
    sudo apt-get install -y virtualenv python3-venv python3-setuptools python3-wheel

elif [ -f /etc/redhat-release ]; then
    # RHEL/CentOS/Fedora based
    echo "Detected RHEL/CentOS/Fedora based system"
    
    # Install EPEL repository if it's not installed
    sudo yum install -y epel-release

    # Install Python 3, development tools, and headers
    sudo yum install -y python3 python3-pip python3-devel gcc

    # Install additional useful Python tools
    sudo yum install -y python3-virtualenv python3-setuptools python3-wheel

else
    echo "Unsupported OS. Exiting."
    exit 1
fi

# Verify installation
python3 --version
pip3 --version
echo "Python installation completed successfully."