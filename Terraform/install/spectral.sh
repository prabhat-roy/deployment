#!/bin/bash
# Update and upgrade the OS
set -e
install_spectral() {
  echo "🔧 Installing Spectral CLI using npm..."

  # Check if Node.js and npm are installed
  if ! command -v npm &>/dev/null; then
    echo "❌ npm is not installed. Please install Node.js and npm first."
    return 1
  fi

  # Install Spectral globally
  sudo npm install -g @stoplight/spectral

  # Verify installation
  if command -v spectral &>/dev/null; then
    echo -n "✅ Spectral installed successfully. Version: "
    spectral --version
  else
    echo "❌ Spectral installation failed."
    return 1
  fi
}