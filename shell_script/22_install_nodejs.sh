#!/bin/bash
set -euo pipefail

JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin"
COOKIE_JAR="/tmp/jenkins_cookies.txt"
TOOL_NAME="NodeJS"

echo "🔍 Checking if Node.js is already installed..."

if ! command -v node &>/dev/null; then
    echo "📦 Installing Node.js LTS..."
    if [ -f /etc/debian_version ]; then
        echo "🔧 Detected Debian/Ubuntu system"
        sudo apt-get update -y
        curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
        sudo apt-get install -y nodejs
    elif [ -f /etc/redhat-release ]; then
        echo "🔧 Detected RHEL/CentOS/Fedora system"
        curl -fsSL https://rpm.nodesource.com/setup_lts.x | sudo -E bash -
        sudo yum install -y nodejs
    else
        echo "❌ Unsupported OS"
        exit 1
    fi
else
    echo "✅ Node.js is already installed. Version: $(node -v)"
fi

NODE_PATH=$(command -v node)
NODE_HOME=$(dirname "$NODE_PATH")

echo "📦 Node.js Binary Path: $NODE_PATH"
echo "📁 Node.js Home: $NODE_HOME"

# --- Step 1: Fetch CSRF crumb ---
echo "🔐 Fetching CSRF crumb and session cookie..."
CRUMB_JSON=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" -c "$COOKIE_JAR" "$JENKINS_URL/crumbIssuer/api/json")

CRUMB_FIELD=$(echo "$CRUMB_JSON" | jq -r '.crumbRequestField')
CRUMB_VALUE=$(echo "$CRUMB_JSON" | jq -r '.crumb')

if [[ -z "$CRUMB_FIELD" || -z "$CRUMB_VALUE" || "$CRUMB_FIELD" == "null" || "$CRUMB_VALUE" == "null" ]]; then
    echo "❌ Failed to fetch crumb. Response was: $CRUMB_JSON"
    exit 1
fi

echo "✅ Crumb fetched: $CRUMB_FIELD: $CRUMB_VALUE"

# --- Step 2: Generate Groovy script ---
GROOVY_SCRIPT=$(cat <<EOF
import jenkins.model.*
import hudson.tools.*
import jenkins.plugins.nodejs.tools.*

def name = "$TOOL_NAME"
def home = "$NODE_HOME"

def instance = Jenkins.get()
def descriptor = instance.getDescriptor(NodeJSInstallation.class)
def installations = descriptor.getInstallations().toList()

if (installations.find { it.name == name }) {
    println "✔ Node.js tool '\$name' already exists."
} else {
    println "➕ Adding Node.js tool: \$name at \$home"
    def nodeTool = new NodeJSInstallation(name, home, [new InstallSourceProperty([])] as List<ToolProperty>)
    installations.add(nodeTool)
    descriptor.setInstallations(installations as NodeJSInstallation[])
    descriptor.save()
    println "✅ Node.js tool '\$name' registered successfully."
}
EOF
)

# --- Step 3: Execute Groovy script via Jenkins ---
echo "🚀 Registering Node.js in Jenkins via Groovy script..."
RESPONSE=$(curl -s -L -w "\nHTTP_STATUS_CODE:%{http_code}\n" \
    -u "$JENKINS_USER:$JENKINS_PASSWORD" \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -H "$CRUMB_FIELD: $CRUMB_VALUE" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "script=$GROOVY_SCRIPT" \
    "$JENKINS_URL/scriptText")

echo "📡 Response from Jenkins script API:"
echo -e "$RESPONSE"

echo "🎉 Node.js installation and Jenkins tool registration complete."
