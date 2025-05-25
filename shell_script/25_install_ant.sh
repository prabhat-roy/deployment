#!/bin/bash
set -euo pipefail

JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin"
COOKIE_JAR="/tmp/jenkins_cookies.txt"
TOOL_NAME="Ant"

echo "🔍 Checking if Ant is already installed..."

if ! command -v ant &>/dev/null; then
    echo "📦 Ant not found. Installing latest version..."

    echo "🔍 Detecting latest Ant version..."
    ANT_MIRROR_URL="https://downloads.apache.org/ant/binaries/"
    ANT_VERSION=$(curl -s "$ANT_MIRROR_URL" | grep -oP 'apache-ant-\K[0-9]+\.[0-9]+\.[0-9]+' | sort -V | tail -n 1)

    if [[ -z "$ANT_VERSION" ]]; then
        echo "❌ Failed to determine latest Ant version."
        exit 1
    fi

    echo "📌 Latest Ant version: $ANT_VERSION"
    ANT_FILENAME="apache-ant-${ANT_VERSION}-bin.zip"
    DOWNLOAD_URL="${ANT_MIRROR_URL}${ANT_FILENAME}"
    INSTALL_DIR="/opt/ant/apache-ant-${ANT_VERSION}"
    PROFILE_SCRIPT="/etc/profile.d/ant.sh"

    if [ -f /etc/debian_version ]; then
        echo "🔧 Detected Debian/Ubuntu system"
        sudo apt-get update -y
        sudo apt-get install -y wget unzip
    elif [ -f /etc/redhat-release ]; then
        echo "🔧 Detected RHEL/CentOS/Fedora system"
        sudo yum install -y wget unzip
    else
        echo "❌ Unsupported OS"
        exit 1
    fi

    echo "⬇ Downloading Ant $ANT_VERSION..."
    wget -q "$DOWNLOAD_URL" -P /tmp

    echo "📦 Installing Ant to $INSTALL_DIR..."
    sudo mkdir -p /opt/ant
    sudo unzip -q -d /opt/ant "/tmp/$ANT_FILENAME"
    sudo ln -sf "$INSTALL_DIR/bin/ant" /usr/bin/ant

    echo "🧹 Cleaning up..."
    rm -f "/tmp/$ANT_FILENAME"

    echo "📍 Setting ANT_HOME in $PROFILE_SCRIPT..."
    sudo tee "$PROFILE_SCRIPT" > /dev/null <<EOF
export ANT_HOME=$INSTALL_DIR
export PATH=\$ANT_HOME/bin:\$PATH
EOF
    sudo chmod +x "$PROFILE_SCRIPT"

    # Export for current session
    export ANT_HOME="$INSTALL_DIR"
    export PATH="$ANT_HOME/bin:$PATH"

else
    echo "✅ Ant is already installed. Version: $(ant -version)"
    ANT_PATH=$(command -v ant)
    ANT_HOME=$(dirname "$(dirname "$ANT_PATH")")
    export ANT_HOME
    export PATH="$ANT_HOME/bin:$PATH"
fi

echo "📦 Ant Binary Path: $(command -v ant)"
echo "📁 Ant Home: $ANT_HOME"

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
import hudson.tasks.Ant.AntInstallation

def name = "$TOOL_NAME"
def home = "$ANT_HOME"

def instance = Jenkins.get()
def descriptor = instance.getDescriptor(AntInstallation.class)
def installations = descriptor.getInstallations().toList()

if (installations.find { it.name == name }) {
    println "✔ Ant tool '\$name' already exists."
} else {
    println "➕ Adding Ant tool: \$name at \$home"
    def antTool = new AntInstallation(name, home, [new InstallSourceProperty([])] as List<ToolProperty>)
    installations.add(antTool)
    descriptor.setInstallations(installations.toArray(new AntInstallation[0]))
    descriptor.save()
    println "✅ Ant tool '\$name' registered successfully."
}
EOF
)

# --- Step 3: Execute Groovy script via Jenkins ---
echo "🚀 Registering Ant in Jenkins via Groovy script..."
RESPONSE=$(curl -s -L -w "\nHTTP_STATUS_CODE:%{http_code}\n" \
    -u "$JENKINS_USER:$JENKINS_PASSWORD" \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -H "$CRUMB_FIELD: $CRUMB_VALUE" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "script=$GROOVY_SCRIPT" \
    "$JENKINS_URL/scriptText")

echo "📡 Response from Jenkins script API:"
echo -e "$RESPONSE"

echo "🎉 Apache Ant installation and Jenkins tool registration complete."
