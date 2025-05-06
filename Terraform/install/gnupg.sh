#!/bin/bash
# Update and upgrade the OS
set -e
install_gnupg() {
# Install gnupg
set -e
echo "📦 Installing gnupg..."
sudo apt install -y gnupg gnupg2
echo "✅ GnuPG installation completed!"
}