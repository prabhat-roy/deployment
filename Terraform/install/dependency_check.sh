#!/bin/bash
set -e

install_dependency_check() {
  INSTALL_DIR="/opt/dependency-check"
  CACHE_DIR="/opt/dependency-check/data"
  BIN_LINK="/usr/local/bin/dependency-check"
  ZIP_CACHE="/opt/cache/dependency-check.zip"

  # Create cache directory if not exists
  mkdir -p /opt/cache

  if [ -f "$BIN_LINK" ]; then
    echo "[*] Dependency-Check already installed."
    return
  fi

  echo "[*] Fetching latest Dependency-Check release URL..."
  DOWNLOAD_URL=$(curl -s https://api.github.com/repos/dependency-check/DependencyCheck/releases/latest \
    | jq -r '.assets[] | select(.name | test("^dependency-check-[0-9.]+-release.zip$")) | .browser_download_url' | head -n 1)

  if [ -z "$DOWNLOAD_URL" ]; then
    echo "[!] Could not find a valid download URL for Dependency-Check."
    exit 1
  fi

  if [ ! -f "$ZIP_CACHE" ]; then
    echo "[*] Downloading Dependency-Check from $DOWNLOAD_URL..."
    curl -L "$DOWNLOAD_URL" -o "$ZIP_CACHE"
  else
    echo "[*] Using cached Dependency-Check ZIP from $ZIP_CACHE"
  fi

  echo "[*] Extracting to /opt..."
  unzip -q "$ZIP_CACHE" -d /opt/

  # We need to ensure the correct directory is installed
  EXTRACTED_DIR=$(ls -d /opt/dependency-check*/ | head -n 1)

  if [ -z "$EXTRACTED_DIR" ]; then
    echo "[!] Failed to find extracted Dependency-Check directory."
    exit 1
  fi

  # Link the correct executable to /usr/local/bin
  ln -sf "$EXTRACTED_DIR/bin/dependency-check.sh" "$BIN_LINK"

  echo "[*] Running initial NVD update..."
  mkdir -p "$CACHE_DIR"
  "$BIN_LINK" --data "$CACHE_DIR" --updateonly || true

  echo "[✔] OWASP Dependency-Check installed successfully with persistent NVD cache at $CACHE_DIR."
}