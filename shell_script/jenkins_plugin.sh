#!/bin/bash
set -e

# Use provided env vars
CLI_JAR="/tmp/jenkins-cli.jar"
PLUGIN_FILE="Jenkinsfile/jenkins_plugin.txt"

if [ -z "$JENKINS_URL" ] || [ -z "$JENKINS_USER" ] || [ -z "$JENKINS_PASS" ]; then
    echo "❌ Missing JENKINS_URL, JENKINS_USER, or JENKINS_PASS."
    exit 1
fi

# Download CLI
if [ ! -f "$CLI_JAR" ]; then
    echo "🔽 Downloading Jenkins CLI..."
    wget -q "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" -O "$CLI_JAR"
fi

echo "📦 Installing plugins from $PLUGIN_FILE"
INSTALL_FLAG=false
printf "\n%-30s | %-20s\n" "PLUGIN" "STATUS"
printf "%s\n" "--------------------------------+----------------------"

while IFS= read -r plugin || [[ -n "$plugin" ]]; do
    plugin=$(echo "$plugin" | xargs)
    [ -z "$plugin" ] && continue

    if java -jar "$CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASS" list-plugins | grep -E "^${plugin} " >/dev/null; then
        printf "%-30s | %-20s\n" "$plugin" "Already Installed"
    else
        if java -jar "$CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASS" install-plugin "$plugin"; then
            printf "%-30s | %-20s\n" "$plugin" "Installed"
            INSTALL_FLAG=true
        else
            printf "%-30s | %-20s\n" "$plugin" "❌ Failed"
        fi
    fi
done < "$PLUGIN_FILE"

if [ "$INSTALL_FLAG" = true ]; then
    echo -e "\n🔄 Restarting Jenkins to apply plugin changes..."
    java -jar "$CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASS" safe-restart
else
    echo -e "\n✅ No plugins were installed. Jenkins restart not required."
fi
