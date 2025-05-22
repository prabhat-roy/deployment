#!/bin/bash
set -euo pipefail

# Require env vars
: "${JENKINS_URL:?Environment variable JENKINS_URL is required}"
: "${JENKINS_USER:?Environment variable JENKINS_USER is required}"
: "${JENKINS_PASS:?Environment variable JENKINS_PASS is required}"

NODEJS_INSTALL_DIR="/usr"  # Since nodejs installed via package manager, typically in /usr/bin
NODEJS_TOOL_NAME="NodeJS_LTS"  # Change as needed

echo "Using Jenkins URL: $JENKINS_URL"
echo "Using Jenkins User: $JENKINS_USER"

# Check if Node.js is installed
if command -v node &>/dev/null; then
    echo "Node.js is already installed."
    node --version
else
    echo "Node.js is not installed, proceeding with installation..."

    if [ -f /etc/debian_version ]; then
        echo "Detected Debian/Ubuntu based system"
        sudo apt-get update -y
        sudo apt-get install -y curl
        curl -sL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs

    elif [ -f /etc/redhat-release ]; then
        echo "Detected RHEL/CentOS/Fedora based system"
        sudo yum install -y curl
        curl -sL https://rpm.nodesource.com/setup_lts.x | sudo -E bash -
        sudo yum install -y nodejs

    else
        echo "Unsupported OS. Exiting."
        exit 1
    fi

    # Verify installation
    node --version
fi

echo "Registering Node.js installation in Jenkins..."

# Get Jenkins crumb for CSRF protection
CRUMB=$(curl -s -u "${JENKINS_USER}:${JENKINS_PASS}" \
    "${JENKINS_URL}/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

if [[ -z "$CRUMB" ]]; then
    echo "❌ Failed to get Jenkins crumb for CSRF protection."
    exit 1
fi

# Prepare XML payload for Jenkins NodeJS tool installation configuration
# Note: Jenkins NodeJS plugin must be installed for this to work
TOOL_PAYLOAD=$(cat <<EOF
<jenkins>
  <installations>
    <org.jenkinsci.plugins.nodejs.tools.NodeJSInstallation>
      <name>${NODEJS_TOOL_NAME}</name>
      <home>${NODEJS_INSTALL_DIR}</home>
      <properties/>
    </org.jenkinsci.plugins.nodejs.tools.NodeJSInstallation>
  </installations>
</jenkins>
EOF
)

# Post the configuration to Jenkins
if ! curl -X POST "${JENKINS_URL}/descriptorByName/org.jenkinsci.plugins.nodejs.tools.NodeJSInstallation/configure" \
     -H "Content-Type: text/xml" \
     -H "$CRUMB" \
     -u "${JENKINS_USER}:${JENKINS_PASS}" \
     --data-binary "${TOOL_PAYLOAD}"; then
    echo "❌ Failed to register Node.js tool in Jenkins."
    exit 1
fi

echo "✅ Node.js tool '${NODEJS_TOOL_NAME}' registered in Jenkins with home '${NODEJS_INSTALL_DIR}'."
echo "Node.js installation and Jenkins registration complete."
