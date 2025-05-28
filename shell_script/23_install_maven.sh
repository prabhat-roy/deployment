#!/bin/bash
set -euo pipefail

JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin"
COOKIE_JAR="/tmp/jenkins_cookies.txt"
TOOL_NAME="Maven"
INSTALL_DIR="/opt/maven"
PROFILE_SCRIPT="/etc/profile.d/maven.sh"
TMP_ARCHIVE="/tmp/apache-maven-latest.tar.gz"

echo "🔍 Checking if Maven is already installed..."
if command -v mvn &>/dev/null; then
    echo "✅ Maven is already installed."
    MAVEN_PATH=$(command -v mvn)
    MAVEN_HOME=$(mvn -v | grep "Maven home" | awk '{print $NF}')
    echo "📦 Maven path: $MAVEN_PATH"
    echo "📁 Maven home: $MAVEN_HOME"
else
    # Detect OS
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS=$ID
    else
        echo "❌ Unsupported OS: Unable to detect."
        exit 1
    fi

    echo "🌐 Fetching latest Maven version..."
    MAVEN_VERSION=$(curl -s https://maven.apache.org/download.cgi | grep -oP 'apache-maven-\K[0-9.]+' | head -1)

    if [ -z "$MAVEN_VERSION" ]; then
        echo "❌ Failed to fetch Maven version."
        exit 1
    fi

    echo "📦 Latest Maven version: $MAVEN_VERSION"
    MAVEN_URL="https://dlcdn.apache.org/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"

    # Cleanup any existing Maven installation and temp files
    echo "🧹 Cleaning up old Maven installations and archives..."
    sudo rm -rf "$INSTALL_DIR"
    sudo rm -f "$TMP_ARCHIVE"

    # Install Maven
    echo "📁 Installing Maven to $INSTALL_DIR..."
    curl -fsSL "$MAVEN_URL" -o "$TMP_ARCHIVE"
    sudo mkdir -p "$INSTALL_DIR"
    sudo tar -xzf "$TMP_ARCHIVE" -C "$INSTALL_DIR" --strip-components=1

    # Set environment variables
    echo "🛠️ Setting environment variables..."
    sudo tee "$PROFILE_SCRIPT" > /dev/null <<EOF
export M2_HOME=$INSTALL_DIR
export MAVEN_HOME=$INSTALL_DIR
export PATH=\$M2_HOME/bin:\$PATH
EOF

    sudo chmod +x "$PROFILE_SCRIPT"
    export PATH="$INSTALL_DIR/bin:$PATH"
    export MAVEN_HOME="$INSTALL_DIR"

    # Verify installation
    if command -v mvn &>/dev/null; then
        echo "✅ Maven installed successfully. Version: $(mvn -v | head -n 1)"
    else
        echo "❌ Maven binary not found after installation!"
        exit 1
    fi
fi

# --- Jenkins Tool Registration ---
echo "🔧 Registering tool in Jenkins: $TOOL_NAME"
echo "📍 Maven home: $MAVEN_HOME"

echo "🔐 Fetching Jenkins crumb..."
CRUMB_JSON=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" -c "$COOKIE_JAR" "$JENKINS_URL/crumbIssuer/api/json")
CRUMB_FIELD=$(echo "$CRUMB_JSON" | jq -r '.crumbRequestField')
CRUMB_VALUE=$(echo "$CRUMB_JSON" | jq -r '.crumb')

if [[ -z "$CRUMB_FIELD" || -z "$CRUMB_VALUE" || "$CRUMB_FIELD" == "null" || "$CRUMB_VALUE" == "null" ]]; then
    echo "❌ Failed to fetch Jenkins crumb."
    exit 1
fi

echo "📦 Preparing Groovy script to register Maven..."
GROOVY_SCRIPT=$(cat <<EOF
import hudson.tasks.Maven.MavenInstallation
import hudson.tools.InstallSourceProperty
import hudson.tools.ToolProperty
import jenkins.model.Jenkins

def name = "$TOOL_NAME"
def home = "$MAVEN_HOME"

def descriptor = Jenkins.get().getDescriptor(MavenInstallation.class)
def installations = descriptor.getInstallations().toList()

if (installations.find { it.name == name }) {
    println "✔ Maven tool '\$name' already exists."
} else {
    println "➕ Registering Maven tool: \$name at \$home"
    def tool = new MavenInstallation(name, home, [new InstallSourceProperty([])] as List<ToolProperty>)
    installations.add(tool)
    descriptor.setInstallations(installations as MavenInstallation[])
    descriptor.save()
    println "✅ Maven tool '\$name' registered successfully."
}
EOF
)

echo "🚀 Registering Maven tool in Jenkins..."
RESPONSE=$(curl -s -L -w "\nHTTP_STATUS_CODE:%{http_code}\n" \
    -u "$JENKINS_USER:$JENKINS_PASSWORD" \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -H "$CRUMB_FIELD: $CRUMB_VALUE" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "script=$GROOVY_SCRIPT" \
    "$JENKINS_URL/scriptText")

echo "📡 Jenkins response:"
echo "$RESPONSE"

# Final cleanup
echo "🧹 Removing temporary archive file..."
rm -f "$TMP_ARCHIVE"

echo "🎉 Maven installation and Jenkins registration complete."
