#!/bin/bash
# Update and upgrade the OS
set -e
install_grype() {
  echo "🔧 Installing Grype (vulnerability scanner)..."
  curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sudo bash -s -- -b /usr/local/bin
  echo -n "✅ Grype version: "
  grype version
}