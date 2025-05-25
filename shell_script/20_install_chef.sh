#!/bin/bash
set -euo pipefail

# Function to check if Chef is already installed
check_installed() {
  if command -v chef-client &> /dev/null; then
    echo "✅ Chef is already installed."
    chef-client --version
    return 0
  else
    return 1
  fi
}

# Function to install Chef on supported distributions
install_chef() {
  echo "📦 Installing Chef Infra Client..."

  curl -L https://omnitruck.chef.io/install.sh -o install_chef_client.sh
  chmod +x install_chef_client.sh
  sudo ./install_chef_client.sh

  chef-client --version
}

# Main logic
if check_installed; then
  echo "✅ Chef is already installed."
else
  install_chef
fi

echo "✅ Chef installation complete!"
