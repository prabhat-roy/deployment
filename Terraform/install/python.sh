#!/bin/bash
# Update and upgrade the OS
set -e
install_python() {
# Install Python
set -e
echo "📦 Installing Python..."
sudo apt install python3 -y
echo "✅ Python installation completed!"
python3 --version
echo "📦 Installing pip..."
sudo apt install python3-pip -y
echo "✅ Pip installation completed!"
pip3 --version
echo "📦 Installing virtualenv..."
sudo apt install python3-venv -y
sudo apt install python3-dev -y
sudo apt install build-essential -y
echo "✅ Virtualenv installation completed!"
}