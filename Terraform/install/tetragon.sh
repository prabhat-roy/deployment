#!/bin/bash
set -e

install_tetragon() {
  echo "🔧 Installing Tetragon CLI..."

  echo "🌐 Fetching latest Tetragon release version..."
  local VERSION=$(curl -s https://api.github.com/repos/cilium/tetragon/releases/latest | grep tag_name | cut -d '"' -f 4)
  echo "📦 Latest Tetragon version: $VERSION"

  local URL="https://github.com/cilium/tetragon/releases/download/${VERSION}/tetragon-linux-amd64"
  local DEST="/usr/local/bin/tetragon"

  echo "⬇️ Downloading Tetragon CLI from: $URL"
  curl -sL "$URL" -o /tmp/tetragon

  echo "🔒 Making binary executable..."
  chmod +x /tmp/tetragon

  echo "🚀 Moving binary to $DEST"
  sudo mv /tmp/tetragon "$DEST"

  echo -n "✅ Tetragon installed. Version: "
  tetragon version || echo "⚠️ Tetragon version command may not return output if not supported in CLI."
}