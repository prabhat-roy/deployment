#!/bin/bash
set -euo pipefail

echo "🔍 Checking if Git is already installed..."
if command -v git &>/dev/null; then
    echo "✅ Git is already installed."
    git --version
    exit 0
fi

echo "⚙️ Git not found. Proceeding with installation..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ Unsupported OS: Unable to detect."
    exit 1
fi

# Install Git with debug output
case "$OS" in
    ubuntu|debian)
        echo "📦 Updating apt and installing Git..."
        sudo apt-get update -y
        sudo apt-get install -y git
        ;;
    rhel|centos|fedora)
        echo "📦 Installing Git via yum/dnf..."
        if command -v dnf &>/dev/null; then
            sudo dnf install -y git
        else
            sudo yum install -y git
        fi
        ;;
    *)
        echo "❌ Unsupported OS: $OS"
        exit 1
        ;;
esac

# Post-install check
echo "✅ Git installed successfully."
git --version
