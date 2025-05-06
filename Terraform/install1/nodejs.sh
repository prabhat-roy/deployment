#!/bin/bash
# Update and upgrade the OS
set -e
install_nodejs() {
# Install Node.js
set -e
echo "📦 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
echo "✅ Node.js installation completed!"
node -v
npm -v
}