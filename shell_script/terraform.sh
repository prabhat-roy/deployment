#!/bin/bash
set -euo pipefail

# Check if Terraform is already installed
if command -v terraform &>/dev/null; then
    echo "Terraform is already installed."
    terraform -version
    exit 0
else
    echo "Terraform is not installed, proceeding with installation..."
fi

# Check distribution and install Terraform accordingly
if [ -f /etc/debian_version ]; then
    # Debian/Ubuntu based
    echo "Detected Debian/Ubuntu based system"
    
    # Install required dependencies
    sudo apt-get update -y
    sudo apt-get install -y gnupg software-properties-common curl unzip

    # Add HashiCorp's GPG key and repository
    curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    sudo apt-add-repository "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main"

    # Update package list and install Terraform
    sudo apt-get update -y
    sudo apt-get install -y terraform

elif [ -f /etc/redhat-release ]; then
    # RHEL/CentOS/Fedora based
    echo "Detected RHEL/CentOS/Fedora based system"
    
    # Install required dependencies
    sudo yum install -y gnupg curl unzip

    # Add HashiCorp's GPG key and repository
    sudo curl -fsSL https://rpm.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /etc/pki/rpm-gpg/hashicorp-archive-keyring.gpg
    sudo dnf repo-add https://rpm.releases.hashicorp.com/rhel/hashicorp.repo

    # Install Terraform
    sudo dnf install -y terraform

else
    echo "Unsupported OS. Exiting."
    exit 1
fi

# Verify installation
terraform -version
