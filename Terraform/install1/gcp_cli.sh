#!/bin/bash
set -e

install_gcp_cli() {
  echo "🔧 Installing Google Cloud CLI (excluding Kubernetes)..."

  # Add the Cloud SDK distribution URI as a package source
  echo "🌐 Adding GCP APT repository..."
  echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | \
    sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list > /dev/null

  # Import the public key
  echo "🔑 Importing GCP public key..."
  curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

  # Update and install CLI
  echo "📦 Installing google-cloud-cli..."
  sudo apt-get update -y
  sudo apt-get install -y google-cloud-cli

  echo -n "✅ Google Cloud CLI installed. Version: "
  gcloud version
}