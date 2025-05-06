#!/bin/bash
set -e

install_ansible() {
  echo "🔧 Installing Ansible..."

  echo "➕ Adding Ansible PPA..."
  sudo add-apt-repository --yes --update ppa:ansible/ansible

  echo "📥 Installing Ansible..."
  sudo apt-get install -y ansible

  echo -n "✅ Ansible version: "
  ansible --version | head -n1
}
