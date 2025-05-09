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
INSTALL_FLAG=false
printf "\n%-30s | %-20s\n" "PLUGIN" "STATUS"
printf "%s\n" "--------------------------------+----------------------"

while IFS= read -r line || [[ -n "$line" ]]; do
    # Strip whitespace and ignore comments or empty lines
    plugin=$(echo "$line" | sed 's/#.*//' | xargs)
    [[ -z "$plugin" ]] && continue

    # Check if plugin is already installed
    if java -jar "$CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASS" list-plugins | grep -E "^${plugin} " >/dev/null; then
        printf "%-30s | %-20s\n" "$plugin" "Already Installed"
    else
        if java -jar "$CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASS" install-plugin "$plugin"; then
            printf "%-30s | %-20s\n" "$plugin" "✅ Installed"
            INSTALL_FLAG=true
        else
            printf "%-30s | %-20s\n" "$plugin" "❌ Failed"
        fi
    fi
done < "$PLUGIN_FILE"

# Restart Jenkins only if new plugins were installed
if [ "$INSTALL_FLAG" = true ]; then
    echo -e "\n🔄 Restarting Jenkins to apply plugin changes..."
    java -jar "$CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASS" safe-restart
else
    echo -e "\n✅ No new plugins installed. Jenkins restart not required."
fi
