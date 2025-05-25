#!/bin/bash
set -euo pipefail

JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin"
COOKIE_JAR="/tmp/jenkins_cookies.txt"
TOOL_NAME="Gradle"

echo "🔍 Checking if Gradle is already installed..."

if ! command -v gradle &>/dev/null; then
    echo "📦 Gradle not found. Installing latest version..."

    echo "🔍 Fetching latest Gradle version..."
    LATEST_VERSION=$(curl -s https://services.gradle.org/versions/current | jq -r '.version')
    echo "📌 Latest Gradle version: $LATEST_VERSION"

    DOWNLOAD_URL="https://services.gradle.org/distributions/gradle-${LATEST_VERSION}-bin.zip"
    ZIP_PATH="/tmp/gradle-${LATEST_VERSION}-bin.zip"
    INSTALL_DIR="/opt/gradle/gradle-${LATEST_VERSION}"
    PROFILE_SCRIPT="/etc/profile.d/gradle.sh"

    if [ -f /etc/debian_version ]; then
        echo "🔧 Detected Debian/Ubuntu system"
        sudo apt-get update -y
        sudo apt-get install -y wget unzip jq
    elif [ -f /etc/redhat-release ]; then
        echo "🔧 Detected RHEL/CentOS/Fedora system"
        sudo yum install -y wget unzip jq
    else
        echo "❌ Unsupported OS"
        exit 1
    fi

    echo "⬇ Downloading Gradle $LATEST_VERSION..."
    wget "$DOWNLOAD_URL" -O "$ZIP_PATH"

    echo "📦 Installing Gradle to $INSTALL_DIR..."
    sudo mkdir -p /opt/gradle
    sudo unzip -q -d /opt/gradle "$ZIP_PATH"
    sudo ln -sf "$INSTALL_DIR/bin/gradle" /usr/bin/gradle

    echo "🧹 Cleaning up..."
    rm -f "$ZIP_PATH"

    echo "📍 Setting GRADLE_HOME in $PROFILE_SCRIPT..."
    sudo tee "$PROFILE_SCRIPT" > /dev/null <<EOF
export GRADLE_HOME=$INSTALL_DIR
export PATH=\$GRADLE_HOME/bin:\$PATH
EOF
    sudo chmod +x "$PROFILE_SCRIPT"

    # Export for current session
    export GRADLE_HOME="$INSTALL_DIR"
    export PATH="$GRADLE_HOME/bin:$PATH"

else
    echo "✅ Gradle is already installed. Version: $(gradle --version | head -n 1)"
    GRADLE_HOME=$(dirname "$(dirname "$(command -v gradle)")")
    export GRADLE_HOME
fi

GRADLE_PATH=$(command -v gradle)
echo "📦 Gradle Binary Path: $GRADLE_PATH"
echo "📁 Gradle Home: $GRADLE_HOME"

# --- Jenkins Tool Registration ---
echo "🔐 Fetching CSRF crumb and session cookie..."
CRUMB_JSON=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" -c "$COOKIE_JAR" "$JENKINS_URL/crumbIssuer/api/json")
CRUMB_FIELD=$(echo "$CRUMB_JSON" | jq -r '.crumbRequestField')
CRUMB_VALUE=$(echo "$CRUMB_JSON" | jq -r '.crumb')

if [[ -z "$CRUMB_FIELD" || -z "$CRUMB_VALUE" || "$CRUMB_FIELD" == "null" || "$CRUMB_VALUE" == "null" ]]; then
    echo "❌ Failed to fetch crumb. Response was: $CRUMB_JSON"
    exit 1
fi

echo "✅ Crumb fetched: $CRUMB_FIELD: $CRUMB_VALUE"

GROOVY_SCRIPT=$(cat <<EOF
import jenkins.model.*
import hudson.tools.*
import hudson.plugins.gradle.*

def name = "$TOOL_NAME"
def home = "$GRADLE_HOME"

def descriptor = Jenkins.instance.getDescriptor(GradleInstallation)
def installations = descriptor.getInstallations().toList()

if (installations.find { it.name == name }) {
    println "✔ Gradle tool '\$name' already exists."
} else {
    println "➕ Adding Gradle tool: \$name at \$home"
    def gradleTool = new GradleInstallation(name, home, [new InstallSourceProperty([])] as List<ToolProperty>)
    installations.add(gradleTool)
    descriptor.setInstallations(installations as GradleInstallation[])
    descriptor.save()
    println "✅ Gradle tool '\$name' registered successfully."
}
EOF
)

echo "🚀 Registering Gradle in Jenkins via Groovy script..."
RESPONSE=$(curl -s -L -w "\nHTTP_STATUS_CODE:%{http_code}\n" \
    -u "$JENKINS_USER:$JENKINS_PASSWORD" \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -H "$CRUMB_FIELD: $CRUMB_VALUE" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "script=$GROOVY_SCRIPT" \
    "$JENKINS_URL/scriptText")

echo "📡 Response from Jenkins script API:"
echo -e "$RESPONSE"

echo "🎉 Gradle installation and Jenkins tool registration complete."
