#!/bin/bash
set -euo pipefail

# Function to install Go
install_go() {
    echo "🚀 Installing Go..."

    # Detect OS (Debian or RedHat)
    if [[ -f /etc/debian_version ]]; then
        OS_TYPE="debian"
    elif [[ -f /etc/redhat-release ]]; then
        OS_TYPE="redhat"
    else
        echo "❌ Unsupported OS"
        exit 1
    fi

    # Install dependencies for Debian/RedHat
    echo "🌐 Installing dependencies for ${OS_TYPE}..."

    if [[ "$OS_TYPE" == "debian" ]]; then
        sudo apt update && sudo apt install -y wget curl tar
    elif [[ "$OS_TYPE" == "redhat" ]]; then
        sudo yum install -y wget curl tar
    fi

    # Download the latest Go tarball
    LATEST_GO_URL=$(curl -s https://go.dev/dl/ | grep -oP 'https://go.dev/dl/go[0-9.]+\.linux-amd64.tar.gz' | head -n 1)
    GO_VERSION=$(echo "$LATEST_GO_URL" | grep -oP 'go[0-9.]+' | head -1)

    echo "🌐 Downloading $GO_VERSION..."
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

    # Set environment variables for this session
    echo "🌍 Setting up Go environment variables..."
    echo "export GOROOT=$INSTALL_DIR/go" >> ~/.bashrc
    echo "export GOPATH=$HOME/go" >> ~/.bashrc
    echo "export PATH=\$GOROOT/bin:\$GOPATH/bin:\$PATH" >> ~/.bashrc

    # Reload the shell configuration
    echo "🔄 Reloading shell configuration..."
    source ~/.bashrc

    # Verify Go installation
    echo "🧪 Verifying Go installation..."
    go version
}

# Check if Go is installed
check_go_installed() {
    if command -v go &>/dev/null; then
        echo "✅ Go is already installed."
        go version
    else
        install_go
    fi
}

# Run the check
check_go_installed
