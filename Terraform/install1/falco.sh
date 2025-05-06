#!/bin/bash
set -e

install_falco() {
  echo "🔧 Installing Falco runtime security engine..."

  echo "📦 Adding Falco GPG key and repository..."
  curl -s https://falco.org/repo/falcosecurity-packages.asc | sudo tee /etc/apt/trusted.gpg.d/falco.asc > /dev/null

  echo "📁 Adding Falco APT source list..."
  echo "deb https://download.falco.org/packages/deb stable main" | sudo tee /etc/apt/sources.list.d/falcosecurity.list > /dev/null

  echo "🔄 Updating package index..."
  sudo apt-get update -y > /dev/null

  echo "⬇️ Installing Falco..."
  sudo apt-get install -y falco > /dev/null

  echo -n "✅ Falco version: "
  falco --version
}
