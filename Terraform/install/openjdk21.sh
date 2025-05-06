#!/bin/bash
# Update and upgrade the OS
set -e
install_openjdk21() {
# Install OpenJDK
set -e
echo "📦 Installing OpenJDK..."
sudo apt install openjdk-21-jdk -y
echo "✅ OpenJDK installation completed!"
java -version
echo "📍 Setting JAVA_HOME and updating PATH..."

JAVA_PATH=$(update-alternatives --query java | grep 'Value: ' | cut -d' ' -f2 | sed 's/\/bin\/java//')

echo "export JAVA_HOME=$JAVA_PATH" | sudo tee -a /etc/profile.d/java.sh
echo "export PATH=\$JAVA_HOME/bin:\$PATH" | sudo tee -a /etc/profile.d/java.sh

sudo chmod +x /etc/profile.d/java.sh
source /etc/profile.d/java.sh

echo "✅ JAVA_HOME set to: $JAVA_HOME"
}