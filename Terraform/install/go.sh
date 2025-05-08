#!/bin/bash
set -e

install_go() {
  echo "🔧 Installing Go (Golang)..."

  # Get latest version number from Go's official site
  local VERSION=$(curl -s https://go.dev/VERSION?m=text)
  echo "📦 Latest Go version: $VERSION"

  # Compose download URL
  local DOWNLOAD_URL="https://go.dev/dl/${VERSION}.linux-amd64.tar.gz"
  echo "⬇️ Downloading Go from: $DOWNLOAD_URL"

  # Download Go archive
  curl -sL "$DOWNLOAD_URL" -o /tmp/go.tar.gz

  # Remove any previous Go installation
  echo "🧹 Removing existing Go installation..."
  sudo rm -rf /usr/local/go

  # Extract Go archive
  echo "📦 Extracting Go..."
  sudo tar -C /usr/local -xzf /tmp/go.tar.gz

  # Set environment variables (if not already set)
  if ! grep -q "export PATH=\$PATH:/usr/local/go/bin" ~/.bashrc; then
    echo "🔧 Adding Go to PATH in ~/.bashrc..."
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
  fi

  # Apply the changes to the current session
  export PATH=$PATH:/usr/local/go/bin

  echo -n "✅ Installed Go version: "
  go version
}
