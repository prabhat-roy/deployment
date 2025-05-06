#!/bin/bash

set -e
install_snyk() {
  echo "🔧 Installing Snyk CLI using npm..."

  # Install Snyk globally using npm
  sudo npm install -g snyk

  # Verify installation
  if command -v snyk >/dev/null 2>&1; then
    echo -n "✅ Snyk successfully installed. Version: "
    snyk --version
  else
    echo "❌ Snyk installation failed."
    return 1
  fi
}