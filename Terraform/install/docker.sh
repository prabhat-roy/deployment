#!/bin/bash
set -e

install_docker() {
    echo "🔧 Installing dependencies..."
    sudo apt install -y ca-certificates lsb-release apt-transport-https software-properties-common

    echo "🔑 Adding Docker’s official GPG key..."
    sudo install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
        | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    sudo chmod a+r /etc/apt/keyrings/docker.gpg

    echo "➕ Setting up Docker stable repository..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" \
      | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    echo "📥 Installing Docker Engine, CLI, Compose, and containerd..."
    sudo apt update -y
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    echo "👥 Adding user '$USER' to the 'docker' group..."
    sudo usermod -aG docker $USER

    echo "🔁 Enabling and starting Docker service..."
    sudo systemctl enable docker
    sudo systemctl start docker

    # Verify Docker and Compose installation
    echo "🔍 Verifying Docker and Compose installation..."
    docker --version
    docker compose version

    # Ensure Docker service is running
    sudo systemctl is-active --quiet docker || sudo systemctl start docker

    # Prompt the user to log out and log back in
    echo "📝 Docker installation completed successfully!"
    echo "👉 For Docker to work correctly, please log out and log back in or run the following command to apply changes:"
    echo "  newgrp docker"

    echo "✅ Docker Engine + Compose v2 installed successfully!"
}
