#!/bin/bash
# Update and upgrade the OS
set -e
install_trivy() {
  echo "🔧 Installing Trivy vulnerability scanner..."
  # Add Trivy APT repository
  wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
  echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
  # Install Trivy
  sudo apt-get update -y
  sudo apt-get install -y trivy

  # Verify installation
  echo -n "✅ Trivy version: "
  trivy --version
}
