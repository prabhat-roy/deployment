#!/bin/bash
set -euo pipefail

echo "🔍 Checking if Apache Ant is already installed..."
if command -v ant &>/dev/null; then
    echo "✅ Apache Ant is already installed."
    ant -version
    exit 0
fi

echo "📦 Installing latest Apache Ant..."

BINARY_BASE_URL="https://downloads.apache.org/ant/binaries"
INSTALL_DIR="/opt/ant"
TEMP_DIR="/tmp/ant-install"

echo "🌐 Downloading Apache Ant binaries directory listing..."
HTML=$(curl -s "$BINARY_BASE_URL/")

echo "🔍 Parsing available Ant versions..."
# Extract filenames like apache-ant-1.10.15-bin.tar.gz from the HTML and get the highest version
LATEST_ANT=$(echo "$HTML" | grep -o 'apache-ant-[0-9.]\+-bin.tar.gz' | \
    sed 's/apache-ant-\(.*\)-bin.tar.gz/\1/' | sort -V | tail -n 1)

if [[ -z "$LATEST_ANT" ]]; then
    echo "❌ Could not find latest Apache Ant version."
    exit 1
fi

ARCHIVE="apache-ant-${LATEST_ANT}-bin.tar.gz"
FULL_URL="${BINARY_BASE_URL}/${ARCHIVE}"

echo "📥 Downloading Apache Ant version: $LATEST_ANT"
echo "🌐 URL: $FULL_URL"

sudo mkdir -p "$INSTALL_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

curl -O "$FULL_URL"
sudo tar -xzf "$ARCHIVE" -C "$INSTALL_DIR" --strip-components=1

echo "🔗 Creating symlink for ant binary..."
sudo ln -sf "$INSTALL_DIR/bin/ant" /usr/local/bin/ant

echo "✅ Apache Ant installed successfully!"
ant -version
