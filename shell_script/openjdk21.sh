#!/bin/bash

# Exit on any error
set -e

openjdk21() {
    echo "📦 Installing OpenJDK 21..."

    # Detect Linux distribution
    if [ -f /etc/redhat-release ]; then
        echo "🔧 Detected RHEL/CentOS-based system"
        sudo yum install -y java-21-openjdk java-21-openjdk-devel
        JAVA_BIN_PATH=$(dirname "$(readlink -f "$(which java)")")
        JAVA_PATH=$(dirname "$JAVA_BIN_PATH")
    elif [ -f /etc/debian_version ]; then
        echo "🔧 Detected Debian/Ubuntu-based system"
        sudo apt-get update -qq
        sudo apt-get install -y openjdk-21-jdk
        JAVA_PATH=$(update-alternatives --query java | grep 'Value: ' | cut -d' ' -f2 | sed 's|/bin/java||')
    else
        echo "❌ Unsupported OS. Please install OpenJDK manually."
        exit 1
    fi

    echo "✅ OpenJDK installation completed!"
    java -version

    echo "📍 Setting JAVA_HOME and updating PATH..."

    # Set JAVA_HOME
    echo "export JAVA_HOME=$JAVA_PATH" | sudo tee /etc/profile.d/java.sh
    echo 'export PATH=$JAVA_HOME/bin:$PATH' | sudo tee -a /etc/profile.d/java.sh

    # Make script executable and apply changes
    sudo chmod +x /etc/profile.d/java.sh
    source /etc/profile.d/java.sh

    echo "✅ JAVA_HOME set to: $JAVA_HOME"
}

openjdk21
echo "✅ OpenJDK 21 installation and configuration completed!"