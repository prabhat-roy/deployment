#!/bin/bash

set -e

echo "🔧 Adding 'jenkins' user to sudo group..."

# Check if jenkins user exists
if id "jenkins" &>/dev/null; then
    # Add user to sudo group (Debian/Ubuntu) or wheel group (RHEL/CentOS)
    if [ -f /etc/debian_version ]; then
        sudo usermod -aG sudo jenkins
        echo "✅ 'jenkins' added to sudo group (Debian/Ubuntu)"
    elif [ -f /etc/redhat-release ]; then
        sudo usermod -aG wheel jenkins
        echo "✅ 'jenkins' added to wheel group (RHEL/CentOS)"
    else
        echo "❌ Unsupported OS. Add the user to sudo group manually."
        exit 1
    fi
else
    echo "❌ 'jenkins' user does not exist. Please create the user first."
    exit 1
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
    echo "❌ Unsupported OS. Please install unzip manually."
    exit 1
fi

echo "✅ unzip installation complete."
