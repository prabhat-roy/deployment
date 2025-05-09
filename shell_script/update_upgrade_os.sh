#!/bin/bash

set -e

update_and_upgrade() {
    # Detect Linux distribution
    if [ -f /etc/redhat-release ]; then
        # RHEL/CentOS-based system
        echo "🔧 Detected RHEL/CentOS-based system"
        sudo yum update -y
        sudo yum upgrade -y
    elif [ -f /etc/debian_version ]; then
        # Debian/Ubuntu-based system
        echo "🔧 Detected Debian/Ubuntu-based system"
        sudo apt-get update -qq
        sudo apt-get upgrade -y
    else
        echo "❌ Unsupported OS. Only RHEL/CentOS and Debian/Ubuntu are supported."
        exit 1
    fi
}

# Run the update and upgrade function
update_and_upgrade

echo "✅ OS update and upgrade complete."
