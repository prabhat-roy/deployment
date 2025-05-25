#!/bin/bash
set -euo pipefail

JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin"
PLUGINS_FILE="/tmp/jenkins_plugin.txt"

if [ ! -f "$PLUGINS_FILE" ]; then
    echo "❌ Plugin list file not found at $PLUGINS_FILE"
    exit 1
fi

# Step 1: Fetch crumb AND cookie
echo "🔐 Fetching CSRF crumb and session cookie..."
CRUMB_JSON=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" -c /tmp/jenkins_cookies.txt "$JENKINS_URL/crumbIssuer/api/json")

CRUMB_FIELD=$(echo "$CRUMB_JSON" | jq -r '.crumbRequestField')
CRUMB_VALUE=$(echo "$CRUMB_JSON" | jq -r '.crumb')

if [[ -z "$CRUMB_FIELD" || -z "$CRUMB_VALUE" || "$CRUMB_FIELD" == "null" || "$CRUMB_VALUE" == "null" ]]; then
    echo "❌ Failed to fetch crumb. Response was: $CRUMB_JSON"
    exit 1
fi

echo "✅ Crumb fetched: $CRUMB_FIELD: $CRUMB_VALUE"

# Read plugin list into variable (one plugin id per line)
PLUGIN_LIST=$(paste -sd '\n' "$PLUGINS_FILE")

INSTALL_SCRIPT=$(cat <<EOF
import jenkins.model.*
def instance = Jenkins.getInstance()
def pluginManager = instance.getPluginManager()
def updateCenter = instance.getUpdateCenter()

def plugins = """$PLUGIN_LIST""".readLines().collect { it.trim() }.findAll { it }

println("📦 Installing plugins: " + plugins)

plugins.each { pluginId ->
    if (!pluginManager.getPlugin(pluginId)) {
        def plugin = updateCenter.getPlugin(pluginId)
        if (plugin) {
            println("🔄 Installing: \$pluginId")
            plugin.deploy().get()
            println("✅ Installed: \$pluginId")
        } else {
            println("⚠️ Plugin not found: \$pluginId")
        }
    } else {
        println("✔ Already installed: \$pluginId")
    }
}

instance.save()
println("✅ Plugin installation complete.")
EOF
)

echo "🚀 Installing plugins..."
curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
    -b /tmp/jenkins_cookies.txt -c /tmp/jenkins_cookies.txt \
    -H "$CRUMB_FIELD: $CRUMB_VALUE" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "script=$INSTALL_SCRIPT" \
    "$JENKINS_URL/scriptText"

echo "♻️ Triggering safe restart..."
curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
    -b /tmp/jenkins_cookies.txt -c /tmp/jenkins_cookies.txt \
    -H "$CRUMB_FIELD: $CRUMB_VALUE" \
    -X POST "$JENKINS_URL/safeRestart"

echo "✅ Plugin install and restart initiated."
