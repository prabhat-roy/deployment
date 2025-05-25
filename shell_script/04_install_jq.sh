#!/bin/bash
set -euo pipefail

echo "📦 Checking for jq installation..."

if command -v jq >/dev/null 2>&1; then
    JQ_VERSION=$(jq --version)
    JQ_PATH=$(command -v jq)
    echo "✅ jq is already installed."
    echo "🔢 Version: $JQ_VERSION"
    echo "📍 Location: $JQ_PATH"
    exit 0
else
    echo "❌ jq not found. Installing..."
fi

if [ -f /etc/redhat-release ]; then
    echo "🔧 Detected RedHat/CentOS-based system."
    sudo yum install -y jq
elif [ -f /etc/debian_version ]; then
    echo "🔧 Detected Debian/Ubuntu-based system."
    sudo apt-get update -qq
    sudo apt-get install -y jq
else
    echo "❌ Unsupported OS. Cannot install jq."
    exit 1
fi

# Verify installation
if command -v jq >/dev/null 2>&1; then
    JQ_VERSION=$(jq --version)
    JQ_PATH=$(command -v jq)
    echo "✅ jq installed successfully."
    echo "🔢 Version: $JQ_VERSION"
    echo "📍 Location: $JQ_PATH"
else
    echo "❌ Failed to install jq."
    exit 1
fi
