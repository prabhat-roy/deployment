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

# Optional: Register Vault CLI in Jenkins as a custom tool (example)

echo "📡 Registering Vault CLI in Jenkins..."

if [[ -z "${JENKINS_URL:-}" || -z "${JENKINS_CREDS_ID:-}" ]]; then
    echo "⚠️ Jenkins URL or credentials ID not set. Skipping Jenkins registration."
    exit 0
fi

USER_VAR="${JENKINS_CREDS_ID}_USERNAME"
PASS_VAR="${JENKINS_CREDS_ID}_PASSWORD"

USERNAME="${!USER_VAR}"
PASSWORD="${!PASS_VAR}"

if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
    echo "❌ Jenkins credentials environment variables not set properly."
    exit 1
fi

CRUMB=$(curl -s --user "$USERNAME:$PASSWORD" "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

TOOL_NAME="VaultCLI"

JSON_PAYLOAD=$(cat <<EOF
{
  "name": "$TOOL_NAME",
  "home": "$INSTALL_DIR"
}
EOF
)

TOOL_API_URL="$JENKINS_URL/tool/vault/installations"  # Adjust API path if needed

curl -s -X POST "$TOOL_API_URL" \
     --user "$USERNAME:$PASSWORD" \
     -H "$CRUMB" \
     -H "Content-Type: application/json" \
     -d "$JSON_PAYLOAD"

echo "✅ Vault CLI registered in Jenkins as $TOOL_NAME"

# Cleanup
rm -rf "$TMP_DIR"

echo "Vault CLI installation complete!"
