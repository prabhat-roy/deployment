#!/bin/bash
set -e
install_curl() {
# Install curl
echo "📦 Installing curl..."
sudo apt install curl -y
echo "✅ Curl installation completed!"
}