#!/bin/bash
set -e

install_aws_cli() {
  echo "🔧 Installing AWS CLI v2..."

  local INSTALL_DIR="/opt/aws-cli"
  local TMP_DIR="/tmp/aws-cli"
  local CACHE_ZIP="/opt/cache/awscliv2.zip"
  local BIN_LINK="/usr/local/bin/aws"

  mkdir -p "$TMP_DIR" /opt/cache

  echo "🌐 Fetching AWS CLI v2..."

  if [[ -f "$CACHE_ZIP" ]]; then
    echo "📦 Using cached AWS CLI ZIP..."
    cp "$CACHE_ZIP" "$TMP_DIR/awscliv2.zip"
  else
    echo "⬇️ Downloading AWS CLI ZIP..."
    curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "$TMP_DIR/awscliv2.zip"
    if [[ ! -s "$TMP_DIR/awscliv2.zip" ]]; then
      echo "❌ Download failed or file is empty."
      exit 1
    fi
    cp "$TMP_DIR/awscliv2.zip" "$CACHE_ZIP"
  fi

  echo "📦 Extracting AWS CLI..."
  unzip -q -o "$TMP_DIR/awscliv2.zip" -d "$TMP_DIR"

  echo "🧹 Cleaning up old AWS CLI installation..."
  sudo rm -rf "$INSTALL_DIR"

  echo "🚀 Installing AWS CLI to $INSTALL_DIR..."
  sudo "$TMP_DIR/aws/install" --install-dir "$INSTALL_DIR" --bin-dir /usr/local/bin

  echo -n "✅ AWS CLI installed. Version: "
  aws --version
}
