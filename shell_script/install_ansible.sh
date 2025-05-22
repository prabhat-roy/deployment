#!/bin/bash
set -euo pipefail

# Function to check if ansible is already installed
check_installed() {
  if command -v ansible &> /dev/null; then
    echo "✅ Ansible is already installed."
    ansible --version
    return 0
  else
    return 1
  fi
}

# Function to install Ansible on Debian/Ubuntu-based systems
install_debian() {
  echo "📦 Installing Ansible on Debian/Ubuntu-based system..."
  sudo apt update
  sudo apt install -y software-properties-common
  sudo add-apt-repository --yes --update ppa:ansible/ansible
  sudo apt install -y ansible
  ansible --version
}

# Function to install Ansible on RHEL/CentOS/Fedora-based systems
install_rhel() {
  echo "📦 Installing Ansible on RHEL/CentOS/Fedora-based system..."
  sudo yum install -y epel-release || true
  sudo yum install -y ansible || sudo dnf install -y ansible
  ansible --version
}

# Main logic
if check_installed; then
  echo "✅ Ansible is already installed."
else
  if [ -f /etc/debian_version ]; then
    install_debian
  elif [ -f /etc/redhat-release ]; then
    install_rhel
  else
    echo "❌ Unsupported Linux distribution!"
    exit 1
  fi
fi

echo "✅ Ansible installation complete!"
