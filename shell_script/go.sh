#!/bin/bash
set -euo pipefail

if command -v go &>/dev/null; then
    echo "✅ Go is already installed."
    go version
    exit 0
else
    echo "📦 Go is not installed, proceeding with installation..."
fi

# Fetch latest Go tarball URL and version
LATEST_GO_URL=$(curl -s https://go.dev/dl/ | grep -oP 'https://go.dev/dl/go[0-9.]+\.linux-amd64.tar.gz' | head -n 1)
GO_VERSION=$(echo "$LATEST_GO_URL" | grep -oP 'go[0-9.]+' | head -1)

echo "🌐 Downloading $GO_VERSION from $LATEST_GO_URL ..."
wget -q "$LATEST_GO_URL" -O /tmp/go.tar.gz

# Determine installation directory
INSTALL_DIR="/usr/local"
USE_SUDO=true
if ! sudo -v &>/dev/null; then
    INSTALL_DIR="$HOME/.go"
    USE_SUDO=false
    mkdir -p "$INSTALL_DIR"
    echo "⚠️ No sudo available, installing Go to $INSTALL_DIR"
fi

# Clean old Go install and extract
if $USE_SUDO; then
    sudo rm -rf "$INSTALL_DIR/go"
    sudo tar -C "$INSTALL_DIR" -xzf /tmp/go.tar.gz
else
    rm -rf "$INSTALL_DIR/go"
    tar -C "$INSTALL_DIR" -xzf /tmp/go.tar.gz
fi

# Set environment variables
export GOROOT="$INSTALL_DIR/go"
export GOPATH="$HOME/go"
export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"

# Persist to ~/.bashrc or ~/.profile
PROFILE_FILE="$HOME/.bashrc"
if [ -n "${BASH_VERSION:-}" ]; then
    PROFILE_FILE="$HOME/.bashrc"
elif [ -n "${ZSH_VERSION:-}" ]; then
    PROFILE_FILE="$HOME/.zshrc"
elif [ -f "$HOME/.profile" ]; then
    PROFILE_FILE="$HOME/.profile"
fi

if ! grep -q "export GOROOT=" "$PROFILE_FILE"; then
    {
        echo "# Go environment"
        echo "export GOROOT=\"$INSTALL_DIR/go\""
        echo "export GOPATH=\"\$HOME/go\""
        echo "export PATH=\"\$GOROOT/bin:\$GOPATH/bin:\$PATH\""
    } >> "$PROFILE_FILE"
    echo "✅ Go environment variables added to $PROFILE_FILE"
fi

echo "🎉 Go installed at $GOROOT"
go version
