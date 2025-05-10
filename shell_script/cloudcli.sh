#!/bin/bash

set -euo pipefail

PROVIDER=$(echo "$1" | tr '[:lower:]' '[:upper:]')

echo "Installing CLI for cloud provider: $PROVIDER"

# Function to check if the command is already installed
check_installed() {
  if command -v "$1" &> /dev/null; then
    echo "$1 is already installed."
    $1 --version
    return 0
  else
    return 1
  fi
}

case "$PROVIDER" in
  AWS)
    # Check if AWS CLI is installed
    if ! check_installed "aws"; then
      echo "Installing AWS CLI..."
      curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
      unzip -q awscliv2.zip
      sudo ./aws/install
      aws --version
    fi
    ;;

  GCP)
    # Check if Google Cloud SDK is installed
    if ! check_installed "gcloud"; then
      echo "Installing Google Cloud SDK..."
      curl -sSL https://sdk.cloud.google.com | bash
      source "$HOME/google-cloud-sdk/path.bash.inc"
      gcloud --version
    fi
    ;;

  AZURE)
    # Check if Azure CLI is installed
    if ! check_installed "az"; then
      echo "Installing Azure CLI..."
      curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
      az version
    fi
    ;;

  *)
    echo "Unknown provider: $PROVIDER"
    exit 1
    ;;
esac
