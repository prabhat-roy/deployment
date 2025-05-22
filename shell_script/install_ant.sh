#!/bin/bash
set -euo pipefail

echo "🔍 Checking if Apache Ant is already installed..."
if command -v ant &>/dev/null; then
    echo "✅ Apache Ant is already installed."
    ant -version
    exit 0
fi

echo "📦 Installing latest Apache Ant..."

# Get latest Ant version tarball link
ANT_URL=$(curl -s https://downloads.apache.org/ant/ | grep -oP 'href="ant-[0-9.]+-bin.tar.gz"' | sort -V | tail -n 1 | cut -d'"' -f2)
FULL_URL="https://downloads.apache.org/ant/${ANT_URL}"
INSTALL_DIR="/opt/ant"
TEMP_DIR="/tmp/ant-install"

# Prepare install directories
sudo mkdir -p "$INSTALL_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# Download and extract Ant
echo "📥 Downloading Apache Ant from $FULL_URL"
curl -O "$FULL_URL"
tar -xzf "$ANT_URL" --strip-components=1 -C "$INSTALL_DIR"

# Symlink the ant binary
sudo ln -sf "$INSTALL_DIR/bin/ant" /usr/local/bin/ant

# Final check
echo "✅ Apache Ant installed at $INSTALL_DIR"
ant -version
