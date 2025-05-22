#!/bin/bash
set -euo pipefail

echo "🔍 Checking if Apache Ant is already installed..."
if command -v ant &>/dev/null; then
    echo "✅ Apache Ant is already installed."
    ant -version
    exit 0
fi

echo "📦 Installing latest Apache Ant..."

ANT_URL=$(curl -s https://downloads.apache.org/ant/ | grep -oP 'href="ant-[0-9.]+-bin.tar.gz"' | sort -V | tail -n 1 | cut -d'"' -f2)
FULL_URL="https://downloads.apache.org/ant/${ANT_URL}"
INSTALL_DIR="/opt/ant"
TEMP_DIR="/tmp/ant-install"

sudo mkdir -p "$INSTALL_DIR"
mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"
curl -O "$FULL_URL"
tar -xzf "$ANT_URL" --strip-components=1 -C "$INSTALL_DIR"

sudo ln -sf "$INSTALL_DIR/bin/ant" /usr/local/bin/ant

echo "✅ Apache Ant installed at $INSTALL_DIR"
ant -version

# Jenkins tool registration via REST API
echo "📡 Registering Ant in Jenkins..."
ANT_VERSION=$(ant -version | grep -oP '[0-9]+\.[0-9]+(\.[0-9]+)?')

# Requires: JENKINS_URL, JENKINS_CREDS_ID in env
if [[ -n "${JENKINS_URL:-}" && -n "${JENKINS_CREDS_ID:-}" ]]; then
    echo "🔐 Fetching Jenkins credentials from environment..."

    USERNAME=$(printenv "${JENKINS_CREDS_ID}_USERNAME")
    PASSWORD=$(printenv "${JENKINS_CREDS_ID}_PASSWORD")

    if [[ -n "$USERNAME" && -n "$PASSWORD" ]]; then
        echo "🔧 Updating Jenkins Ant tool via REST API..."
        CRUMB=$(curl -s --user "$USERNAME:$PASSWORD" "$JENKINS_URL/crumbIssuer/api/xml?xpath=concat(//crumbRequestField,\":\",//crumb)")
        curl -s -X POST "$JENKINS_URL/tool/ant/ANT-${ANT_VERSION}" \
            --user "$USERNAME:$PASSWORD" \
            -H "$CRUMB" \
            -H "Content-Type: application/json" \
            -d "{\"name\": \"ANT-${ANT_VERSION}\", \"home\": \"$INSTALL_DIR\"}"
        echo "✅ Apache Ant registered in Jenkins as ANT-${ANT_VERSION}"
    else
        echo "❌ Jenkins credentials not set in environment."
    fi
else
    echo "⚠️ Jenkins environment not fully configured for registration. Skipping registration."
fi
