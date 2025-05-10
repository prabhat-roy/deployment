#!/bin/bash
set -euo pipefail

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install kubectl
if ! command_exists kubectl; then
    echo "📦 Installing kubectl..."
    # Fetch the latest stable release version of kubectl dynamically
    KUBECTL_VERSION=$(curl -s https://dl.k8s.io/release/stable.txt)
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    
    # Make it executable
    chmod +x kubectl
    
    # Move to a directory in PATH
    sudo mv kubectl /usr/local/bin/
    echo "✅ kubectl installed successfully."
else
    echo "✅ kubectl is already installed. Version: $(kubectl version --client --short)"
fi

# Install kustomize
if ! command_exists kustomize; then
    echo "📦 Installing kustomize..."
    # Fetch the latest release of kustomize dynamically
    KUSTOMIZE_VERSION=$(curl -s "https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest" | jq -r '.tag_name')
    curl -LO "https://github.com/kubernetes-sigs/kustomize/releases/download/${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz"
    
    # Extract kustomize binary
    tar -zxvf "kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz"
    
    # Move to a directory in PATH
    sudo mv kustomize /usr/local/bin/
    rm -rf "kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz"
    echo "✅ kustomize installed successfully."
else
    echo "✅ kustomize is already installed. Version: $(kustomize version)"
fi

# Install helm
if ! command_exists helm; then
    echo "📦 Installing helm..."
    # Fetch the latest release of helm dynamically
    HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | jq -r '.tag_name')
    curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" -o helm.tar.gz
    
    # Extract the tarball
    tar -zxvf helm.tar.gz
    
    # Move the helm binary to a directory in PATH
    sudo mv linux-amd64/helm /usr/local/bin/helm
    rm -rf linux-amd64 helm.tar.gz
    
    echo "✅ Helm installed successfully."
else
    echo "✅ Helm is already installed. Version: $(helm version --short)"
fi

# Verify installation of all tools
echo "📊 Installed Versions:"
kubectl version --client --short
kustomize version
helm version --short
