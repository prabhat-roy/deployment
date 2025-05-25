#!/bin/bash

set -euo pipefail

echo "🔍 Detecting Linux distribution..."

# Detect Linux distribution and perform update/upgrade
if [ -f /etc/redhat-release ]; then
    echo "🔧 Detected RHEL/CentOS-based system"
    sudo yum -y update && sudo yum -y upgrade
elif [ -f /etc/debian_version ]; then
    echo "🔧 Detected Debian/Ubuntu-based system"
    export DEBIAN_FRONTEND=noninteractive
    sudo apt-get -qq update
    sudo apt-get -y upgrade
else
    echo "❌ Unsupported OS. Only RHEL/CentOS and Debian/Ubuntu are supported."
    exit 1
fi

echo "✅ OS update and upgrade complete."
