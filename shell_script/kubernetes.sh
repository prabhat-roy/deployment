#!/bin/bash
set -euo pipefail

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install kubectl
if ! command_exists kubectl; then
    echo "📦 Installing kubectl..."

    KUBECTL_VERSION="$(curl -L -s https://dl.k8s.io/release/stable.txt)"
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl.sha256"

    echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    rm -f kubectl kubectl.sha256

    echo "✅ kubectl installed successfully."
else
    echo "✅ kubectl is already installed. Version: $(kubectl version --client --short)"
fi

# Install kustomize
if ! command_exists kustomize; then
    echo "📦 Installing kustomize..."
    RAW_TAG=$(curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest | jq -r '.tag_name')
    VERSION=$(basename "$RAW_TAG")
    FILE="kustomize_${VERSION}_linux_amd64.tar.gz"
    URL="https://github.com/kubernetes-sigs/kustomize/releases/download/${RAW_TAG}/${FILE}"

    curl -LO --fail "$URL"

    # Clean up any leftover file or directory
    if [ -e kustomize ]; then
        echo "⚠️ Removing existing kustomize file or directory..."
        sudo rm -rf kustomize
    fi

    # Extract and install
    tar -zxvf "$FILE" --overwrite
    sudo mv kustomize /usr/local/bin/
    rm -f "$FILE"

    echo "✅ kustomize installed successfully."
else
    echo "✅ kustomize is already installed. Version: $(kustomize version)"
fi

# Install helm
if ! command_exists helm; then
    echo "📦 Installing helm..."
    HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | jq -r '.tag_name')
    curl -fsSL "https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz" -o helm.tar.gz

    tar -zxvf helm.tar.gz
    sudo mv linux-amd64/helm /usr/local/bin/helm
    rm -rf linux-amd64 helm.tar.gz

    echo "✅ Helm installed successfully."
else
    echo "✅ Helm is already installed. Version: $(helm version --short)"
fi

# Final version check
echo -e "\n📊 Installed Versions:"
kubectl version --client --short
kustomize version
helm version --short
