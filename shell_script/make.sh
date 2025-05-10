#!/bin/bash
set -euo pipefail

echo "🔍 Checking if Make is already installed..."
if command -v make &>/dev/null; then
    echo "✅ Make is already installed."
    make --version
    exit 0
fi

echo "⚙️ Make not found. Proceeding with installation..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ Unsupported OS: Unable to detect."
    exit 1
fi

# Install Make with debug output
case "$OS" in
    ubuntu|debian)
        echo "📦 Updating apt and installing Make..."
        sudo apt-get update -y
        sudo apt-get install -y make
        ;;
    rhel|centos|fedora)
        echo "📦 Installing Make via yum/dnf..."
        if command -v dnf &>/dev/null; then
            sudo dnf install -y make
        else
            sudo yum install -y make
        fi
        ;;
    *)
        echo "❌ Unsupported OS: $OS"
        exit 1
        ;;
esac

# Post-install check
echo "✅ Make installed successfully."
make --version
