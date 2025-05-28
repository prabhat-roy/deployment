#!/bin/bash
set -euo pipefail

# Check if Puppet is already installed
check_installed() {
  if command -v puppet &> /dev/null; then
    echo "✅ Puppet is already in PATH."
    puppet --version
    return 0
  elif [ -x /opt/puppetlabs/bin/puppet ]; then
    echo "✅ Puppet binary found at /opt/puppetlabs/bin/puppet"
    /opt/puppetlabs/bin/puppet --version
    return 0
  else
    return 1
  fi
}

# Install on Debian/Ubuntu
install_debian() {
    echo "📦 Installing Puppet on Debian/Ubuntu..."

    local codename
    codename=$(lsb_release -cs)

    # Fallback for unsupported releases like Ubuntu 24.04 ("oracular")
    if ! wget -q --spider "https://apt.puppetlabs.com/puppet-release-${codename}.deb"; then
        echo "⚠️  No official Puppet release for '${codename}'. Falling back to 'jammy' (22.04)..."
        codename="jammy"
    fi

    DEB_FILE="puppet-release-${codename}.deb"
    wget -nc "https://apt.puppetlabs.com/puppet-release-${codename}.deb" -O "$DEB_FILE"
    sudo dpkg -i "$DEB_FILE"
    sudo apt-get update
    sudo apt-get install -y puppet-agent

    echo "🧹 Cleaning up downloaded .deb file..."
    rm -f "$DEB_FILE"
}

# Install on RHEL/CentOS/Fedora
install_rhel() {
    echo "📦 Installing Puppet on RHEL/CentOS/Fedora..."
    sudo rpm -Uvh "https://yum.puppet.com/puppet-release-el-$(rpm -E %{rhel}).noarch.rpm"
    if command -v yum &> /dev/null; then
        sudo yum install -y puppet-agent
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y puppet-agent
    else
        echo "❌ No supported package manager found (yum/dnf)"
        exit 1
    fi
}

# Main logic
if check_installed; then
    echo "✅ Puppet is already installed."
else
    if [ -f /etc/debian_version ]; then
        install_debian
    elif [ -f /etc/redhat-release ]; then
        install_rhel
    else
        echo "❌ Unsupported Linux distribution!"
        exit 1
    fi
fi

# Set PATH for the current session
export PATH="/opt/puppetlabs/bin:$PATH"

# Verify installation
if command -v puppet &>/dev/null; then
    echo "✅ Puppet installed successfully. Version: $(puppet --version)"
else
    echo "❌ Puppet binary not found after install!"
    exit 1
fi

# Ensure it's available system-wide in future sessions
echo 'export PATH=/opt/puppetlabs/bin:$PATH' | sudo tee /etc/profile.d/puppet.sh

echo "🎉 Puppet installation and setup complete!"
