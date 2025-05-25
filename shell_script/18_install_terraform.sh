#!/bin/bash
set -euo pipefail

# Check if Terraform is already installed
if command -v terraform &>/dev/null; then
    echo "✅ Terraform is already installed."
    terraform -version
    exit 0
else
    echo "📦 Terraform is not installed, proceeding with installation..."
fi

# Detect OS and version
if [[ -f /etc/debian_version ]]; then
    echo "🔍 Detected Debian/Ubuntu based system"

    # Install dependencies
    sudo apt-get update -y
    sudo apt-get install -y gnupg software-properties-common curl unzip lsb-release

    # Add HashiCorp GPG key and repo
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
        | sudo tee /etc/apt/sources.list.d/hashicorp.list

    # Install Terraform
    sudo apt-get update -y
    sudo apt-get install -y terraform

elif [[ -f /etc/redhat-release ]]; then
    echo "🔍 Detected RHEL/CentOS/Fedora based system"

    # Install dependencies
    sudo yum install -y yum-utils

    # Add HashiCorp YUM repo
    sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/RHEL/hashicorp.repo

    # Install Terraform
    sudo yum install -y terraform
else
    echo "❌ Unsupported OS. Exiting."
    exit 1
fi

# Verify installation
echo "✅ Verifying Terraform installation..."
terraform -version
