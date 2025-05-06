#!/bin/bash
# Update and upgrade the OS
set -e
install_syft() {
  echo "🔧 Installing Syft (SBOM generator)..."
  curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sudo bash -s -- -b /usr/local/bin
  echo -n "✅ Syft version: "
  syft version
}