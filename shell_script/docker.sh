#!/bin/bash
set -euo pipefail

# Check if Docker is already installed
if command -v docker &>/dev/null; then
    echo "✅ Docker is already installed."
    docker --version
    exit 0
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "❌ Unsupported OS: Unable to detect."
    exit 1
fi

# Install Docker and Docker Compose
case "$OS" in
    ubuntu|debian)
        echo "📦 Updating apt and installing Docker..."
        sudo apt-get update -y
        sudo apt-get install -y \
            apt-transport-https \
            ca-certificates \
            curl \
            software-properties-common

        curl -fsSL https://get.docker.com | sudo sh
        sudo apt-get install -y docker-compose
        ;;
    rhel|centos|fedora)
        echo "📦 Installing Docker on RHEL/CentOS/Fedora..."
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io
        sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        ;;
    *)
        echo "❌ Unsupported OS: $OS"
        exit 1
        ;;
esac

# Start and enable Docker service
echo "🔄 Starting Docker service..."
sudo systemctl start docker
sudo systemctl enable docker

# Add Jenkins user to Docker group
echo "🔑 Adding Jenkins user to Docker group..."
sudo usermod -aG docker jenkins

# Verify Docker and Docker Compose installation
echo "✅ Docker installed successfully."
docker --version
echo "✅ Docker Compose installed successfully."
docker-compose --version

# Restart Jenkins service to apply group changes
echo "♻️ Restarting Jenkins to apply Docker group membership..."
sudo systemctl restart jenkins

echo "✅ Jenkins restarted. Docker is now fully configured."
