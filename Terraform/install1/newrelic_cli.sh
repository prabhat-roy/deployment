#!/bin/bash
set -e
install_newrelic_cli() {
  echo "🔧 Installing New Relic CLI..."

  # Get latest version from GitHub
  local VERSION=$(curl -s https://api.github.com/repos/newrelic/newrelic-cli/releases/latest | grep tag_name | cut -d '"' -f 4)
  echo "📦 Latest New Relic CLI version: $VERSION"

  # Download and install the correct binary (Linux AMD64)
  curl -sL "https://github.com/newrelic/newrelic-cli/releases/download/${VERSION}/newrelic-cli_${VERSION:1}_Linux_x86_64.tar.gz" -o /tmp/newrelic-cli.tar.gz

  echo "📦 Extracting New Relic CLI..."
  mkdir -p /tmp/newrelic-cli
  tar -xzf /tmp/newrelic-cli.tar.gz -C /tmp/newrelic-cli

  echo "🚀 Moving binary to /usr/local/bin..."
  sudo mv /tmp/newrelic-cli/newrelic /usr/local/bin/

  echo -n "✅ New Relic CLI version: "
  newrelic version
}