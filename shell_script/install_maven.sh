#!/bin/bash
set -euo pipefail

echo "🔍 Checking if Maven is already installed..."
if command -v mvn &>/dev/null; then
    echo "✅ Maven is already installed."
    mvn -version
    exit 0
fi

echo "⚙️ Maven not found. Proceeding with installation..."

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ Unsupported OS: Unable to detect."
    exit 1
fi

# Set variables
INSTALL_DIR="/opt/maven"
PROFILE_SCRIPT="/etc/profile.d/maven.sh"

echo "🌐 Fetching latest Maven version..."
MAVEN_VERSION=$(curl -s https://maven.apache.org/download.cgi | grep -oP 'apache-maven-\K[0-9.]+' | head -1)

if [ -z "$MAVEN_VERSION" ]; then
    echo "❌ Failed to fetch Maven version."
    exit 1
fi

echo "📦 Latest Maven version: $MAVEN_VERSION"
MAVEN_URL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"

# Create install directory
echo "📁 Preparing installation directory at $INSTALL_DIR..."
sudo rm -rf "$INSTALL_DIR"
sudo mkdir -p "$INSTALL_DIR"

# Download and extract
echo "📥 Downloading and extracting Maven..."
curl -fsSL "$MAVEN_URL" | sudo tar -xz -C "$INSTALL_DIR" --strip-components=1

# Set environment variables
echo "🛠️ Configuring environment variables..."
sudo tee "$PROFILE_SCRIPT" > /dev/null <<EOF
export M2_HOME=$INSTALL_DIR
export PATH=\$M2_HOME/bin:\$PATH
EOF

sudo chmod +x "$PROFILE_SCRIPT"
source "$PROFILE_SCRIPT"

# Post-install check
echo "✅ Maven installed successfully."
mvn -version
