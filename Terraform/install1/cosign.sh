#!/bin/bash
# Update and upgrade the OS
set -e
install_cosign() {
  echo "🔐 Installing Cosign (container signing tool)..."

  # Detect latest version
  COSIGN_VERSION=$(curl -s https://api.github.com/repos/sigstore/cosign/releases/latest | grep '"tag_name":' | cut -d '"' -f 4)
  echo "📦 Latest Cosign version: $COSIGN_VERSION"

  if [[ -z "$COSIGN_VERSION" ]]; then
    echo "❌ Failed to fetch latest Cosign version from GitHub."
    return 1
  fi

  # Construct download URL
  COSIGN_URL="https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-amd64"
  echo "📥 Downloading from: $COSIGN_URL"

  # Download and install
  curl -fL "$COSIGN_URL" -o /tmp/cosign || {
    echo "❌ Failed to download Cosign binary."
    return 1
  }

  chmod +x /tmp/cosign
  sudo mv /tmp/cosign /usr/local/bin/cosign

  # Verify installation
  if command -v cosign >/dev/null 2>&1; then
    echo -n "✅ Cosign successfully installed. Version: "
    cosign version
  else
    echo "❌ Cosign installation failed."
    return 1
  fi
}