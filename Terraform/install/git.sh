#!/bin/bash
# Update and upgrade the OS
set -e
install_git() {
# Install Git
echo "📦 Installing Git..."
sudo apt install git -y
echo "✅ Git installation completed!"
git --version
}