#!/bin/bash
# Update and upgrade the OS
set -e
install_wget() {
# Install wget
set -e
echo "📦 Installing wget..."
sudo apt install wget -y
echo "✅ Wget installation completed!"
}