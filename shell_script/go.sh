#!/bin/bash
set -euo pipefail

# Check if Go is installed
if command -v go &>/dev/null; then
    echo "Go is already installed."
    go version
    exit 0
else
    echo "Go is not installed, proceeding with installation..."
fi

# Fetch the latest Go version dynamically
LATEST_GO_URL=$(curl -s https://golang.org/dl/ | grep -oP 'https://golang.org/dl/go[0-9.]+\.linux-amd64.tar.gz' | head -n 1)

# Extract Go version from the URL
GO_VERSION=$(echo "$LATEST_GO_URL" | grep -oP 'go[0-9.]+')

# Download Go tarball
echo "Downloading $GO_VERSION..."
wget -q "$LATEST_GO_URL" -O /tmp/go.tar.gz

# Remove any old Go installation
sudo rm -rf /usr/local/go

# Extract the tarball to /usr/local
sudo tar -C /usr/local -xzf /tmp/go.tar.gz

# Set Go environment variables
echo "Setting up Go environment variables..."
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
echo 'export GOPATH=$HOME/go' >> ~/.bashrc
echo 'export GOROOT=/usr/local/go' >> ~/.bashrc

# Apply changes to the environment
source ~/.bashrc

# Verify installation
go version
