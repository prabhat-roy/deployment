#!/bin/bash

set -e

PROVIDER=$(echo "$1" | tr '[:lower:]' '[:upper:]')

echo "Installing CLI for cloud provider: $PROVIDER"

case "$PROVIDER" in
  AWS)
    curl -s "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip -q awscliv2.zip
    sudo ./aws/install
    aws --version
    ;;
  GCP)
    curl -sSL https://sdk.cloud.google.com | bash
    source "$HOME/google-cloud-sdk/path.bash.inc"
    gcloud --version
    ;;
  AZURE)
    curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
    az version
    ;;
  *)
    echo "Unknown provider: $PROVIDER"
    exit 1
    ;;
esac
