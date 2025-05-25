#!/bin/bash
set -euo pipefail

echo "🔍 Checking if Vault CLI is already installed..."

if command -v vault &>/dev/null; then
    echo "✅ Vault CLI is already installed:"
    vault version
    exit 0
fi

echo "📦 Installing Vault CLI..."

INSTALL_DIR="/usr/local/bin"

# Get latest Vault CLI version from HashiCorp releases API
LATEST_VERSION=$(curl -s https://releases.hashicorp.com/vault/index.json | \
    grep -Po '"version":\s*"\K[0-9.]+' | sort -V | tail -1)

if [[ -z "$LATEST_VERSION" ]]; then
    echo "❌ Could not determine latest Vault CLI version."
    exit 1
fi

echo "Latest Vault CLI version: $LATEST_VERSION"

ARCHIVE_NAME="vault_${LATEST_VERSION}_linux_amd64.zip"
DOWNLOAD_URL="https://releases.hashicorp.com/vault/${LATEST_VERSION}/${ARCHIVE_NAME}"

TMP_DIR=$(mktemp -d)
cd "$TMP_DIR"

curl -LO "$DOWNLOAD_URL"

unzip "$ARCHIVE_NAME"
chmod +x vault
sudo mv vault "$INSTALL_DIR/"

echo "✅ Vault CLI installed at $INSTALL_DIR/vault"
vault version
