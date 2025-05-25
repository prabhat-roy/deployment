#!/bin/bash

set -euo pipefail

echo "🌐 Installing all supported cloud CLIs (AWS, GCP, Azure)..."

# Function to check if the command is already installed
check_installed() {
  if command -v "$1" &> /dev/null; then
    echo "✅ $1 is already installed."
    $1 --version || true
    return 0
  else
    return 1
  fi
}

# --- Install AWS CLI ---
if ! check_installed "aws"; then
  echo "📦 Installing AWS CLI..."
  curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  unzip -q awscliv2.zip
  sudo ./aws/install
  rm -rf aws awscliv2.zip
  aws --version
fi

# --- Install GCP CLI ---
if ! check_installed "gcloud"; then
  echo "📦 Installing Google Cloud SDK (gcloud)..."
  curl -sSL https://sdk.cloud.google.com | bash -s -- --quiet
  source "$HOME/google-cloud-sdk/path.bash.inc"
  gcloud --version
fi

# --- Install Azure CLI ---
if ! check_installed "az"; then
  echo "📦 Installing Azure CLI..."
  if [ -f /etc/debian_version ]; then
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
  elif [ -f /etc/redhat-release ]; then
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo dnf install -y https://packages.microsoft.com/config/rhel/8/packages-microsoft-prod.rpm
    sudo dnf install -y azure-cli
  else
    echo "⚠️ Unsupported OS for automatic Azure CLI installation"
  fi
  az version
fi

echo "✅ All cloud CLIs are installed and ready to use."
