#!/bin/bash
set -euo pipefail

# Check if Go is already installed
if command -v go &>/dev/null; then
    echo "Go is already installed."
    go version
    exit 0
else
    echo "Go is not installed, proceeding with installation..."
fi

# Fetch the latest Go version dynamically
LATEST_GO_URL=$(curl -s https://golang.org/dl/ | grep -oP 'https://go.dev/dl/go[0-9.]+\.linux-amd64.tar.gz' | head -n 1)

# Extract Go version from the URL
GO_VERSION=$(echo "$LATEST_GO_URL" | grep -oP 'go[0-9.]+' | head -n1)

# Download Go tarball
echo "Downloading $GO_VERSION..."
wget -q "$LATEST_GO_URL" -O /tmp/go.tar.gz

# Remove any old Go installation
sudo rm -rf /usr/local/go

# Extract the tarball to /usr/local
sudo tar -C /usr/local -xzf /tmp/go.tar.gz

# Set Go environment variables in this script session
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export GOROOT=/usr/local/go

# Also persist them for future sessions
{
  echo 'export PATH=$PATH:/usr/local/go/bin'
  echo 'export GOPATH=$HOME/go'
  echo 'export GOROOT=/usr/local/go'
} >> ~/.bashrc

# Verify installation
echo "✅ Go installation complete:"
go version
