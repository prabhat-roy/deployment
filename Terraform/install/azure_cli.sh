#!/bin/bash
set -e

install_azure_cli() {
  echo "🔧 Installing Azure CLI..."

  local TMP_DIR="/tmp/azure-cli"
  sudo rm -rf "$TMP_DIR"
  mkdir -p "$TMP_DIR"
  cd "$TMP_DIR"

  echo "🌐 Downloading Microsoft Azure CLI install script..."
  curl -sL https://aka.ms/InstallAzureCLIDeb | bash

  echo "🔗 Linking az CLI to /usr/local/bin..."
  sudo ln -sf /usr/bin/az /usr/local/bin/az

  echo -n "✅ Azure CLI installed. Version: "
  az version

  echo "📦 Installing common Azure CLI extensions (excluding Kubernetes)..."
  EXTENSIONS=$(az extension list-available --output tsv --query "[?name!='aks'].[name]" | awk '{print $1}')
  for EXT in $EXTENSIONS; do
    echo "🔌 Installing extension: $EXT"
    az extension add --name "$EXT" || echo "⚠️ Failed to install $EXT"
  done

  echo "✅ Azure CLI and extensions installation complete."
}
