#!/bin/bash
# Update and upgrade the OS
set -e
update_upgrade_os() {
echo "📦 Updating package index..."
sudo apt update -y

echo "⬆️ Upgrading installed packages..."
sudo apt upgrade -y

echo "✅ OS update and upgrade completed!"
}