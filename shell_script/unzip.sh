#!/bin/bash

set -e

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
