#!/bin/bash
set -euo pipefail

# Define Go install path
GOROOT=/usr/local/go
GOPATH=$HOME/go
GO_BIN=$GOROOT/bin/go

# Check if Go is already installed
if command -v go &>/dev/null || [ -x "$GO_BIN" ]; then
    echo "Go is already installed."
    $GO_BIN version
    exit 0
fi

echo "Go is not installed, proceeding with installation..."

# Fetch latest Go version
LATEST_GO_URL=$(curl -s https://go.dev/dl/ | grep -oP 'https://go.dev/dl/go[0-9.]+\.linux-amd64.tar.gz' | head -n 1)

# Validate URL
if [[ -z "$LATEST_GO_URL" ]]; then
    echo "❌ Failed to fetch Go download URL"
    exit 1
fi

# Download and install
echo "Downloading Go from: $LATEST_GO_URL"
wget -q "$LATEST_GO_URL" -O /tmp/go.tar.gz
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf /tmp/go.tar.gz

# Set environment vars for current session
export GOROOT=$GOROOT
export GOPATH=$GOPATH
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin

# Persist environment for future sessions
{
  echo 'export GOROOT=/usr/local/go'
  echo 'export GOPATH=$HOME/go'
  echo 'export PATH=$PATH:$GOROOT/bin:$GOPATH/bin'
} >> ~/.bashrc

# Verify installation
echo "✅ Verifying Go installation..."
go version || $GO_BIN version
