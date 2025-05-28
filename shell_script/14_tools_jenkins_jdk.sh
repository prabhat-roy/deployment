#!/bin/bash
set -euo pipefail

# --- Configuration ---
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin"
COOKIE_JAR="/tmp/jenkins_cookies.txt"

# --- Step 1: Delay and wait for Jenkins readiness ---

echo "⏳ Waiting for Jenkins API to become available..."
until curl -sf -u "$JENKINS_USER:$JENKINS_PASSWORD" "$JENKINS_URL/crumbIssuer/api/json" > /dev/null 2>&1; do
    echo -n "."
    sleep 5
done
echo ""
echo "✅ Jenkins API is ready."

# --- Step 2: Detect Java ---
JAVA_PATH=$(readlink -f "$(which java)")
JAVA_HOME=$(dirname "$(dirname "$JAVA_PATH")")
JAVA_VERSION=$(java -version 2>&1 | awk -F[\".] '/version/ {print $2}')

if [ -z "$JAVA_PATH" ] || [ -z "$JAVA_VERSION" ]; then
    echo "❌ Java not detected or version not found"
    exit 1
fi

TOOL_NAME="OpenJDK"

echo "🔍 Detected Java:"
echo "  Path: $JAVA_PATH"
echo "  Home: $JAVA_HOME"
echo "  Version: $JAVA_VERSION"
echo "  Will register in Jenkins as tool: $TOOL_NAME"

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

# --- Step 4: Generate Groovy script to register Java tool ---
GROOVY_SCRIPT=$(cat <<EOF
import jenkins.model.*
import hudson.model.*
import hudson.model.JDK

def name = "$TOOL_NAME"
def home = "$JAVA_HOME"

def instance = Jenkins.getInstance()
def desc = instance.getDescriptor("hudson.model.JDK")
def installations = desc.getInstallations().toList()

if (installations.find { it.name == name }) {
    println "✔ Java tool '\$name' already exists."
} else {
    println "➕ Adding Java tool: \$name at \$home"
    def jdk = new JDK(name, home)
    installations.add(jdk)
    desc.setInstallations(installations as JDK[])
    instance.save()
    println "✅ Java tool '\$name' registered successfully."
}
EOF
)

# --- Step 5: Execute script via Jenkins API ---
echo "🚀 Registering Java in Jenkins via Groovy script..."
RESPONSE=$(curl -s -L -w "\nHTTP_STATUS_CODE:%{http_code}\n" \
    -u "$JENKINS_USER:$JENKINS_PASSWORD" \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -H "$CRUMB_FIELD: $CRUMB_VALUE" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "script=$GROOVY_SCRIPT" \
    "$JENKINS_URL/scriptText")

echo "📡 Response from Jenkins script API:"
echo -e "$RESPONSE"