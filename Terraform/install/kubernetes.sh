#!/bin/bash
# Update and upgrade the OS
set -e
install_kubernetes() {
#  ### Install kubectl
  echo "🔧 Installing kubectl..."
  sudo curl -LO https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl
  sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

  ### Install Helm
  echo "🔧 Installing Helm..."
  curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
  chmod 700 get_helm.sh
  ./get_helm.sh
  ### Install Kustomize
  echo "🔧 Installing Kustomize..."
  curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh"  | bash
}