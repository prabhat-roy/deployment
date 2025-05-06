#!/bin/bash
set -e
install_calicoctl() {
  echo "🔧 Installing calicoctl on Ubuntu..."

  # Determine the latest version
  echo "📦 Fetching latest calicoctl version..."
  LATEST_VERSION=$(curl -s https://api.github.com/repos/projectcalico/calico/releases/latest | grep tag_name | cut -d '"' -f 4)

  if [[ -z "$LATEST_VERSION" ]]; then
    echo "❌ Failed to fetch the latest version of calicoctl."
    return 1
  fi

  echo "⬇️  Downloading calicoctl $LATEST_VERSION..."
  curl -L -o /usr/local/bin/calicoctl "https://github.com/projectcalico/calico/releases/download/${LATEST_VERSION}/calicoctl-linux-amd64"

  # Make it executable
  chmod +x /usr/local/bin/calicoctl

  # Verify installation
  if command -v calicoctl &>/dev/null; then
    echo -n "✅ calicoctl installed successfully. Version: "
    calicoctl version
  else
    echo "❌ calicoctl installation failed."
    return 1
  fi
}