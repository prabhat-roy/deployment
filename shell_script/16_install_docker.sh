#!/bin/bash
set -euo pipefail

JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin"
COOKIE_JAR="/tmp/jenkins_cookies.txt"
TOOL_NAME="Docker"

echo "🔍 Checking if Docker is already installed..."
if command -v docker &>/dev/null; then
    echo "✅ Docker is already installed."
else
    echo "🔧 Docker not found. Installing Docker..."

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        OS_ID=$ID
    else
        echo "❌ Cannot detect OS. Aborting."
        exit 1
    fi

    case "$OS_ID" in
        ubuntu|debian)
            echo "📦 Detected Debian-based system: $OS_ID"
            apt-get update -qq
            apt-get install -y -qq ca-certificates curl gnupg lsb-release >/dev/null

            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/${ID}/gpg -o /etc/apt/keyrings/docker.asc
            chmod a+r /etc/apt/keyrings/docker.asc

            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID} $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list

            apt-get update -qq
            apt-get install -y -qq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null
            ;;
        rhel|centos|rocky|almalinux|amzn)
            echo "📦 Detected Red Hat-based system: $OS_ID"
            yum install -y -q yum-utils ca-certificates curl >/dev/null
            yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >/dev/null

            if [[ "$OS_ID" == "amzn" ]]; then
                yum install -y -q docker >/dev/null
            else
                yum install -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >/dev/null
            fi

            systemctl enable docker
            systemctl start docker
            ;;
        *)
            echo "❌ Unsupported OS: $OS_ID"
            exit 1
            ;;
    esac

    echo "✅ Docker installation complete."
fi

DOCKER_PATH=$(command -v docker)
DOCKER_VERSION=$(docker --version)
echo "📦 Docker Binary Path: $DOCKER_PATH"
echo "🔢 Docker Version: $DOCKER_VERSION"

# Add jenkins user to docker group
echo "🔑 Adding 'jenkins' user to docker group..."
if id jenkins &>/dev/null; then
    usermod -aG docker jenkins
    echo "✅ 'jenkins' added to docker group."
else
    echo "⚠️  'jenkins' user does not exist. Skipping group addition."
fi

# --- Step 1: Fetch CSRF crumb ---
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

# --- Step 2: Check if Docker plugin is installed ---
echo "🔍 Verifying if Docker plugin is installed in Jenkins..."
PLUGIN_LIST=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" "$JENKINS_URL/pluginManager/api/json?depth=1" | jq -r '.plugins[].shortName')

if echo "$PLUGIN_LIST" | grep -q "^docker-commons$"; then
    echo "✅ Required 'docker-commons' plugin is installed."
else
    echo "❌ 'docker-commons' plugin is not installed. Please install it via the Jenkins Plugin Manager before continuing."
    exit 1
fi

# --- Step 3: Generate Groovy script to register Docker tool ---
GROOVY_SCRIPT=$(cat <<EOF
import jenkins.model.*
import org.jenkinsci.plugins.docker.commons.tools.*
import hudson.tools.*

def name = "$TOOL_NAME"
def home = new File("$DOCKER_PATH").getParent()

def instance = Jenkins.get()
def descriptor = instance.getDescriptor(DockerTool.class)
def installations = descriptor.getInstallations().toList()

if (installations.find { it.name == name }) {
    println "✔ Docker tool '\$name' already exists."
} else {
    println "➕ Adding Docker tool: \$name at \$home"
    def dockerTool = new DockerTool(name, home, [new InstallSourceProperty([])] as List<ToolProperty>)
    installations.add(dockerTool)
    descriptor.setInstallations(installations as DockerTool[])
    descriptor.save()
    println "✅ Docker tool '\$name' registered successfully."
}
EOF
)

# --- Step 4: Execute script via Jenkins API ---
echo "🚀 Registering Docker in Jenkins via Groovy script..."
RESPONSE=$(curl -s -L -w "\nHTTP_STATUS_CODE:%{http_code}\n" \
    -u "$JENKINS_USER:$JENKINS_PASSWORD" \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -H "$CRUMB_FIELD: $CRUMB_VALUE" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "script=$GROOVY_SCRIPT" \
    "$JENKINS_URL/scriptText")

echo "📡 Response from Jenkins script API:"
echo -e "$RESPONSE"

# --- Final Step: Restart Jenkins ---
echo "🔁 Restarting Jenkins service to ensure all configurations are applied..."
if systemctl is-active --quiet jenkins; then
    systemctl restart jenkins
    echo "✅ Jenkins restarted successfully."
else
    echo "⚠️  Jenkins is not currently running. Skipping restart."
fi

echo "🎉 Docker installation and Jenkins tool registration complete."
