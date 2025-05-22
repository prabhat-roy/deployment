#!/bin/bash
set -euo pipefail

echo "🔍 Checking if Node.js is already installed..."

if command -v node &>/dev/null; then
    echo "✅ Node.js is already installed. Version: $(node -v)"
    exit 0
fi

echo "📦 Installing Node.js LTS..."

if [ -f /etc/debian_version ]; then
    echo "🔧 Detected Debian/Ubuntu system"
    sudo apt-get update -y
    curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
    sudo apt-get install -y nodejs

elif [ -f /etc/redhat-release ]; then
    echo "🔧 Detected RHEL/CentOS/Fedora system"
    curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo -E bash -
    sudo yum install -y nodejs

else
    echo "❌ Unsupported OS"
    exit 1
fi

echo "✅ Node.js installation completed. Version: $(node -v)"
