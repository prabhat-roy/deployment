#!/bin/bash
set -euo pipefail

if command -v go &>/dev/null; then
    echo "Go is already installed."
    go version
    exit 0
else
    echo "Go is not installed, proceeding with installation..."
fi

LATEST_GO_URL=$(curl -s https://go.dev/dl/ | grep -oP 'https://go.dev/dl/go[0-9.]+\.linux-amd64.tar.gz' | head -n 1)
GO_VERSION=$(echo "$LATEST_GO_URL" | grep -oP 'go[0-9.]+' | head -1)

echo "Downloading $GO_VERSION..."
wget -q "$LATEST_GO_URL" -O /tmp/go.tar.gz

# Optional: Install to user dir if sudo fails
INSTALL_DIR="/usr/local"
if ! sudo -v &>/dev/null; then
    INSTALL_DIR="$HOME/.go"
    mkdir -p "$INSTALL_DIR"
else
    sudo rm -rf /usr/local/go
fi

# Extract Go
sudo tar -C "$INSTALL_DIR" -xzf /tmp/go.tar.gz

# Set env vars for this session
export GOROOT="$INSTALL_DIR/go"
export GOPATH="$HOME/go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

echo "Go installed at $GOROOT"
go version
