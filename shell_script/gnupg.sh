#!/bin/bash
set -euo pipefail

echo "🔍 Checking if GNUPG is already installed..."
if command -v gpg &>/dev/null; then
    echo "✅ GNUPG is already installed."
    gpg --version
    exit 0
fi

echo "⚙️ GNUPG not found. Proceeding with installation..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ Unsupported OS: Unable to detect."
    exit 1
fi

# Install GNUPG with debug output
case "$OS" in
    ubuntu|debian)
        echo "📦 Updating apt and installing GNUPG..."
        sudo apt-get update -y
        sudo apt-get install -y gnupg
        ;;
    rhel|centos|fedora)
        echo "📦 Installing GNUPG via yum/dnf..."
        if command -v dnf &>/dev/null; then
            sudo dnf install -y gnupg
        else
            sudo yum install -y gnupg
        fi
        ;;
    *)
        echo "❌ Unsupported OS: $OS"
        exit 1
        ;;
esac

# Post-install check
echo "✅ GNUPG installed successfully."
gpg --version
