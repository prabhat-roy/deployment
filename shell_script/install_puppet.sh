#!/bin/bash
set -euo pipefail

# Function to check if Puppet is already installed
check_installed() {
  if command -v puppet &> /dev/null; then
    echo "✅ Puppet is already installed."
    puppet --version
    return 0
  else
    return 1
  fi
}

# Function to install Puppet on Debian/Ubuntu-based systems
install_debian() {
    echo "📦 Installing Puppet on Debian/Ubuntu..."
    wget https://apt.puppetlabs.com/puppet-release-$(lsb_release -cs).deb -O puppet-release.deb
    sudo dpkg -i puppet-release.deb
    sudo apt-get update
    sudo apt-get install -y puppet-agent
    export PATH=/opt/puppetlabs/bin:$PATH
    puppet --version
}

# Function to install Puppet on RHEL/CentOS/Fedora-based systems
install_rhel() {
    echo "📦 Installing Puppet on RHEL/CentOS/Fedora..."
    sudo rpm -Uvh https://yum.puppet.com/puppet-release-el-$(rpm -E %{rhel}).noarch.rpm
    sudo yum install -y puppet-agent || sudo dnf install -y puppet-agent
    export PATH=/opt/puppetlabs/bin:$PATH
    puppet --version
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

echo "✅ Puppet installation complete!"
