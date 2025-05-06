#!/bin/bash
set -e

install_puppet() {
  echo "🔧 Installing Puppet..."

  # Detect OS codename
  local CODENAME=$(lsb_release -sc)
  echo "📦 Detected OS codename: $CODENAME"

  # Download and install the official Puppet repository .deb
  local URL="https://apt.puppet.com/puppet7-release-${CODENAME}.deb"
  echo "⬇️ Downloading Puppet release package from: $URL"
  curl -sL "$URL" -o /tmp/puppet-release.deb

  # Check if the file is a valid Debian archive
  if file /tmp/puppet-release.deb | grep -q "Debian binary package"; then
    echo "📦 Installing Puppet repository..."
    sudo dpkg -i /tmp/puppet-release.deb
    sudo apt-get update
    echo "📥 Installing Puppet agent..."
    sudo apt-get install -y puppet-agent
  else
    echo "❌ Error: The downloaded file is not a valid .deb package. Aborting."
    exit 1
  fi

  echo -n "✅ Puppet version: "
  /opt/puppetlabs/bin/puppet --version
}