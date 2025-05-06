#!/bin/bash
# Update and upgrade the OS
set -e
install_unzip() {
# Install unzip
set -e
echo "📦 Installing unzip..."
sudo apt install unzip -y
echo "✅ Unzip installation completed!"
}