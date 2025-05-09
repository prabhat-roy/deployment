#!/bin/bash

set -e

# Check if unzip is already installed
if command -v unzip >/dev/null 2>&1; then
    echo "✅ unzip is already installed."
    exit 0
fi

echo "Installing unzip..."

# Detect package manager and install unzip
if [ -f /etc/redhat-release ]; then
    echo "Detected RHEL/CentOS-based system"
    sudo yum install -y unzip
elif [ -f /etc/debian_version ]; then
    echo "Detected Debian/Ubuntu-based system"
    sudo apt-get update -qq
    sudo apt-get install -y unzip
else
    echo "Unsupported OS. Please install unzip manually."
    exit 1
fi

echo "✅ unzip installation complete."
