#!/bin/bash
set -euo pipefail

echo "🚀 Checking for existing Go installation..."
if command -v go >/dev/null 2>&1; then
    echo "✅ Go is already installed: $(go version)"
    exit 0
fi

# Ensure jq is available
if ! command -v jq >/dev/null 2>&1; then
    echo "🔧 jq not found, downloading jq..."
    curl -sLo "$HOME/jq" https://github.com/stedolan/jq/releases/latest/download/jq-linux64
    chmod +x "$HOME/jq"
    export PATH="$HOME:$PATH"
fi

# Fetch the latest Go version info directly from the go.dev URL
echo "🌐 Fetching latest Go version information..."
LATEST_VERSION=$(curl -s https://go.dev/dl/ | grep -oP 'go[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
if [[ -z "$LATEST_VERSION" ]]; then
    echo "❌ Failed to retrieve the latest Go version."
    exit 1
fi

# Construct the tarball URL
TARBALL_URL="https://go.dev/dl/${LATEST_VERSION}.linux-amd64.tar.gz"
TARBALL="/tmp/go.tar.gz"
INSTALL_DIR="$HOME/.go"

echo "📦 Downloading $LATEST_VERSION from $TARBALL_URL..."
curl -sSL "$TARBALL_URL" -o "$TARBALL"

echo "🧹 Cleaning previous installation at $INSTALL_DIR..."
rm -rf "$INSTALL_DIR"
mkdir -p "$INSTALL_DIR"

echo "📂 Extracting Go to $INSTALL_DIR..."
tar -C "$INSTALL_DIR" --strip-components=1 -xzf "$TARBALL"

echo "🔧 Updating environment variables..."
GO_ENV_SCRIPT="$HOME/.go_env.sh"
cat > "$GO_ENV_SCRIPT" <<EOF
export GOROOT=$INSTALL_DIR
export GOPATH=\$HOME/go
export PATH=\$GOROOT/bin:\$GOPATH/bin:\$PATH
EOF

# Source the new environment immediately in the current shell session
source "$GO_ENV_SCRIPT"

# Add to .bashrc if not already present
if ! grep -q "source \$HOME/.go_env.sh" "$HOME/.bashrc" 2>/dev/null; then
    echo "source \$HOME/.go_env.sh" >> "$HOME/.bashrc"
fi

echo "✅ Go successfully installed: $(go version)"
