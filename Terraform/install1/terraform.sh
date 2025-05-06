#!/bin/bash
# Update and upgrade the OS
set -e
# Install Terraform
install_terraform() {
# Install Terraform
set -e
echo "📦 Installing Terraform..."
echo "🔐 Adding HashiCorp GPG key..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "📁 Adding HashiCorp repo..."
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

echo "📥 Updating package list again..."
sudo apt update -y

echo "📦 Installing Terraform..."
sudo apt install -y terraform

echo "✅ Terraform installed!"
terraform version
}