#!/bin/bash
set -e

install_zaproxy() {
  echo "🔧 Installing OWASP ZAP (Zed Attack Proxy)..."

  # Fetch the latest release info from GitHub and extract the tar.gz URL
  local RELEASE_INFO=$(curl -s https://api.github.com/repos/zaproxy/zaproxy/releases/latest)
  local VERSION=$(echo "$RELEASE_INFO" | jq -r .tag_name)
  echo "📦 Latest ZAP version: $VERSION"

  # Find the correct .tar.gz file URL in the assets array
  local URL=$(echo "$RELEASE_INFO" | jq -r '.assets[] | select(.name | test(".*Linux.*tar.gz")) | .browser_download_url')

  # Check if URL is empty (no tar.gz file found)
  if [ -z "$URL" ]; then
    echo "❌ Error: No valid .tar.gz file found for Linux in the release assets."
    exit 1
  fi

  local TMP_DIR="/tmp/zaproxy"
  local INSTALL_DIR="/opt/zaproxy"

  echo "⬇️ Downloading ZAP from: $URL"
  mkdir -p "$TMP_DIR"

  # Download the ZAP tar.gz file
  curl -sL "$URL" -o "$TMP_DIR/zap.tar.gz"

  # Check if the file exists and is a valid .tar.gz
  if file "$TMP_DIR/zap.tar.gz" | grep -q "gzip compressed data"; then
    echo "📦 Extracting ZAP..."
    sudo rm -rf "$INSTALL_DIR"
    sudo mkdir -p "$INSTALL_DIR"
    sudo tar -xzf "$TMP_DIR/zap.tar.gz" -C "$INSTALL_DIR" --strip-components=1
  else
    echo "❌ Error: The downloaded file is not a valid .tar.gz archive. Please check the URL or version."
    exit 1
  fi

  echo "🔗 Linking zap.sh to /usr/local/bin/zap..."
  sudo ln -sf "$INSTALL_DIR/zap.sh" /usr/local/bin/zap

  # Verify installation
  echo -n "✅ ZAP installed. Version: "
  zap -version
}