#!/bin/bash
set -euo pipefail

echo "🔍 Checking if OpenJDK 21 is already installed..."

if command -v java &>/dev/null; then
    JAVA_VER=$(java -version 2>&1 | head -n 1 | grep '21')
    if [[ -n "$JAVA_VER" ]]; then
        echo "✅ OpenJDK 21 is already installed:"
        java -version
        exit 0
    else
        echo "⚠️ Java installed, but not version 21."
    fi
fi

echo "📦 Installing OpenJDK 21..."

INSTALL_DIR="/opt/openjdk21"
TEMP_DIR="/tmp/openjdk21-install"

# Download latest OpenJDK 21 binaries from official AdoptOpenJDK or Temurin
# Using Temurin GitHub releases API to find latest openjdk 21

API_URL="https://api.adoptium.net/v3/assets/latest/21/hotspot"
DOWNLOAD_URL=$(curl -s $API_URL | grep -oP '"package":{"link":"\K[^"]*linux-x64.tar.gz')

if [[ -z "$DOWNLOAD_URL" ]]; then
    echo "❌ Could not find OpenJDK 21 download URL."
    exit 1
fi

mkdir -p "$TEMP_DIR"
mkdir -p "$INSTALL_DIR"

cd "$TEMP_DIR"
curl -LO "$DOWNLOAD_URL"

tarball=$(basename "$DOWNLOAD_URL")

tar -xzf "$tarball" --strip-components=1 -C "$INSTALL_DIR"

# Symlink java binaries for easy access
sudo ln -sf "$INSTALL_DIR/bin/java" /usr/local/bin/java
sudo ln -sf "$INSTALL_DIR/bin/javac" /usr/local/bin/javac

echo "✅ OpenJDK 21 installed at $INSTALL_DIR"
java -version

# Register OpenJDK 21 as Jenkins JDK tool using Jenkins REST API

echo "📡 Registering OpenJDK 21 in Jenkins..."

# Required environment variables
if [[ -z "${JENKINS_URL:-}" || -z "${JENKINS_CREDS_ID:-}" ]]; then
    echo "⚠️ Jenkins URL or credentials ID not set. Skipping Jenkins registration."
    exit 0
fi

# Retrieve Jenkins credentials (expecting env vars like jenkins-creds_USERNAME and jenkins-creds_PASSWORD)
USER_VAR="${JENKINS_CREDS_ID}_USERNAME"
PASS_VAR="${JENKINS_CREDS_ID}_PASSWORD"

USERNAME="${!USER_VAR}"
PASSWORD="${!PASS_VAR}"

if [[ -z "$USERNAME" || -z "$PASSWORD" ]]; then
    echo "❌ Jenkins credentials environment variables not set properly."
    exit 1
fi

CRUMB=$(curl -s --user "$USERNAME:$PASSWORD" "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")

# Prepare JSON for JDK tool configuration
JDK_NAME="OpenJDK21"
JSON_PAYLOAD=$(cat <<EOF
{
  "name": "$JDK_NAME",
  "home": "$INSTALL_DIR"
}
EOF
)

# Jenkins API URL for JDK tools (adjust if needed)
TOOL_API_URL="$JENKINS_URL/tool/jdk/installations"

echo "🔧 Sending Jenkins API request to register JDK..."

curl -s -X POST "$TOOL_API_URL" \
     --user "$USERNAME:$PASSWORD" \
     -H "$CRUMB" \
     -H "Content-Type: application/json" \
     -d "$JSON_PAYLOAD"

echo "✅ OpenJDK 21 registered in Jenkins as $JDK_NAME"
