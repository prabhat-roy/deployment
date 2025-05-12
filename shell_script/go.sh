#!/bin/bash
set -euo pipefail

echo "🚀 Checking for existing Go installation..."

# Check if Go is already installed
if command -v go >/dev/null 2>&1; then
    echo "✅ Go is already installed: $(go version)"
    exit 0
fi

# Fetch the latest Go version
echo "🌐 Fetching latest Go version information..."
LATEST_VERSION=$(curl -s https://go.dev/dl/ | grep -oP 'go[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)

if [[ -z "$LATEST_VERSION" ]]; then
    echo "❌ Failed to retrieve the latest Go version."
    exit 1
fi

echo "Latest Go version found: $LATEST_VERSION"

# Construct the tarball URL
TARBALL_URL="https://go.dev/dl/${LATEST_VERSION}.linux-amd64.tar.gz"
TARBALL="/tmp/go.tar.gz"
INSTALL_DIR="$HOME/.go"

# Download the latest Go version
echo "📦 Downloading $LATEST_VERSION from $TARBALL_URL..."
curl -sSL "$TARBALL_URL" -o "$TARBALL"

# Clean up any previous installation
echo "🧹 Cleaning previous Go installation at $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

# Extract Go
echo "📂 Extracting Go to $INSTALL_DIR..."
tar -C "$INSTALL_DIR" --strip-components=1 -xzf "$TARBALL"

# Set environment variables for this session
echo "🔧 Setting environment variables for Go..."
GO_ENV_SCRIPT="$HOME/.go_env.sh"
cat > "$GO_ENV_SCRIPT" <<EOF
export GOROOT=$INSTALL_DIR
export GOPATH=\$HOME/go
export PATH=\$GOROOT/bin:\$GOPATH/bin:\$PATH
EOF

# Source the environment script to update current session
source "$GO_ENV_SCRIPT"

# Add to .bashrc if not already present
if ! grep -q "source \$HOME/.go_env.sh" "$HOME/.bashrc" 2>/dev/null; then
    echo "source \$HOME/.go_env.sh" >> "$HOME/.bashrc"
fi

# Verify Go installation
echo "✅ Verifying Go installation..."
go version || { echo "❌ Go installation failed"; exit 1; }

echo "✅ Go successfully installed: $(go version)"
