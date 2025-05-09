#!/bin/bash
set -e

# Use provided env vars
CLI_JAR="/tmp/jenkins-cli.jar"
PLUGIN_FILE="Jenkinsfile/jenkins_plugin.txt"

# Validate required environment variables
if [ -z "$JENKINS_URL" ] || [ -z "$JENKINS_USER" ] || [ -z "$JENKINS_PASS" ]; then
    echo "❌ Missing one or more required environment variables: JENKINS_URL, JENKINS_USER, JENKINS_PASS."
    exit 1
fi

# Download Jenkins CLI if not already present
if [ ! -f "$CLI_JAR" ]; then
    echo "🔽 Downloading Jenkins CLI..."
    wget -q "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" -O "$CLI_JAR"
fi

echo -e "\n📦 Installing plugins from: $PLUGIN_FILE"

# Extract plugin names (ignoring comments and empty lines)
PLUGINS=$(grep -v '^#' "$PLUGIN_FILE" | xargs)

# Flag to track if plugins were installed
INSTALL_FLAG=false

# If plugins are available, proceed with installation
if [ -n "$PLUGINS" ]; then
    printf "\n%-30s | %-20s\n" "PLUGIN" "STATUS"
    printf "%s\n" "--------------------------------+----------------------"
    
    # Install plugins in bulk
    if java -jar "$CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASS" install-plugin $PLUGINS --username "$JENKINS_USER" --password "$JENKINS_PASS"; then
        INSTALL_FLAG=true
        for plugin in $PLUGINS; do
            printf "%-30s | %-20s\n" "$plugin" "✅ Installed"
        done
    else
        for plugin in $PLUGINS; do
            printf "%-30s | %-20s\n" "$plugin" "❌ Failed"
        done
    fi
else
    echo "❌ No valid plugins found in $PLUGIN_FILE."
fi

# Restart Jenkins only if new plugins were installed
if [ "$INSTALL_FLAG" = true ]; then
    echo -e "\n🔄 Restarting Jenkins to apply plugin changes..."
    java -jar "$CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASS" safe-restart
else
    echo -e "\n✅ No new plugins installed. Jenkins restart not required."
fi
