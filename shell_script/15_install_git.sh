#!/bin/bash
set -euo pipefail

JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin"
COOKIE_JAR="/tmp/jenkins_cookies.txt"
TOOL_NAME="DefaultGit"

echo "🔍 Checking if Git is already installed..."
if command -v git &>/dev/null; then
    echo "✅ Git is already installed."
else
    echo "⚙️ Git not found. Proceeding with installation..."

    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo "❌ Unsupported OS: Unable to detect."
        exit 1
    fi

    # Install Git
    case "$OS" in
        ubuntu|debian)
            echo "📦 Updating apt and installing Git..."
            sudo apt-get update -y
            sudo apt-get install -y git
            ;;
        rhel|centos|fedora)
            echo "📦 Installing Git via yum/dnf..."
            if command -v dnf &>/dev/null; then
                sudo dnf install -y git
            else
                sudo yum install -y git
            fi
            ;;
        *)
            echo "❌ Unsupported OS: $OS"
            exit 1
            ;;
    esac

    echo "✅ Git installed successfully."
fi

GIT_PATH=$(command -v git)
GIT_VERSION=$(git --version)

echo "🔢 Git version: $GIT_VERSION"
echo "📍 Git location: $GIT_PATH"

# --- Step 3: Fetch CSRF crumb ---
echo "🔐 Fetching CSRF crumb and session cookie..."
CRUMB_JSON=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" -c "$COOKIE_JAR" "$JENKINS_URL/crumbIssuer/api/json")

if ! echo "$CRUMB_JSON" | jq . > /dev/null 2>&1; then
    echo "❌ Crumb response not valid JSON:"
    echo "$CRUMB_JSON"
    exit 1
fi

CRUMB_FIELD=$(echo "$CRUMB_JSON" | jq -r '.crumbRequestField')
CRUMB_VALUE=$(echo "$CRUMB_JSON" | jq -r '.crumb')

if [[ -z "$CRUMB_FIELD" || -z "$CRUMB_VALUE" || "$CRUMB_FIELD" == "null" || "$CRUMB_VALUE" == "null" ]]; then
    echo "❌ Failed to fetch crumb. Response was: $CRUMB_JSON"
    exit 1
fi

echo "✅ Crumb fetched: $CRUMB_FIELD: $CRUMB_VALUE"

# --- Step 4: Generate Groovy script to register Git tool ---
GROOVY_SCRIPT=$(cat <<EOF
import jenkins.model.*
import hudson.plugins.git.*
import hudson.tools.*

def name = "$TOOL_NAME"
def home = "$GIT_PATH"

def instance = Jenkins.get()
def descriptor = instance.getDescriptor(GitTool.class)
def installations = descriptor.getInstallations().toList()

if (installations.find { it.name == name }) {
    println "✔ Git tool '\$name' already exists."
} else {
    println "➕ Adding Git tool: \$name at \$home"
    def gitTool = new GitTool(name, home, [new InstallSourceProperty([])] as List<ToolProperty>)
    installations.add(gitTool)
    descriptor.setInstallations(installations as GitTool[])
    descriptor.save()
    println "✅ Git tool '\$name' registered successfully."
}
EOF
)

# --- Step 5: Execute script via Jenkins API ---
echo "🚀 Registering Git in Jenkins via Groovy script..."
RESPONSE=$(curl -s -L -w "\nHTTP_STATUS_CODE:%{http_code}\n" \
    -u "$JENKINS_USER:$JENKINS_PASSWORD" \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -H "$CRUMB_FIELD: $CRUMB_VALUE" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "script=$GROOVY_SCRIPT" \
    "$JENKINS_URL/scriptText")

echo "📡 Response from Jenkins script API:"
#echo -e "$RESPONSE"
