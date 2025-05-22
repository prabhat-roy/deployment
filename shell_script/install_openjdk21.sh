#!/bin/bash

set -euo pipefail

echo "📦 Checking for Java installation..."

# Check if Java is installed
if command -v java >/dev/null 2>&1; then
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    echo "✅ Java version detected: $JAVA_VERSION"
    if [[ "$JAVA_VERSION" == 21* ]]; then
        echo "✅ OpenJDK 21 is already installed."
        exit 0
    else
        echo "⚠️ Java is installed but not version 21. Proceeding with installation..."
    fi
else
    echo "❌ Java is not installed. Installing OpenJDK 21..."
fi

# Detect OS and install OpenJDK 21
if [ -f /etc/redhat-release ]; then
    echo "🔧 Detected RHEL/CentOS-based system"
    sudo yum install -y java-21-openjdk java-21-openjdk-devel
    JAVA_PATH=$(dirname "$(dirname "$(readlink -f "$(which java)")")")
elif [ -f /etc/debian_version ]; then
    echo "🔧 Detected Debian/Ubuntu-based system"
    sudo apt-get update -qq
    sudo apt-get install -y openjdk-21-jdk
    JAVA_PATH=$(dirname "$(dirname "$(readlink -f "$(which java)")")")
else
    echo "❌ Unsupported OS. Exiting."
    exit 1
fi

echo "✅ OpenJDK 21 installed successfully."
java -version

# Set JAVA_HOME and update PATH
echo "📍 Setting JAVA_HOME in /etc/profile.d/java.sh..."
echo "export JAVA_HOME=$JAVA_PATH" | sudo tee /etc/profile.d/java.sh
echo 'export PATH=$JAVA_HOME/bin:$PATH' | sudo tee -a /etc/profile.d/java.sh
sudo chmod +x /etc/profile.d/java.sh

# Export for current session
export JAVA_HOME="$JAVA_PATH"
export PATH="$JAVA_HOME/bin:$PATH"

echo "✅ JAVA_HOME is set to: $JAVA_HOME"
echo "✅ OpenJDK 21 installation and configuration complete!"