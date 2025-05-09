#!/bin/bash
set -euo pipefail

CLI_JAR="/tmp/jenkins-cli.jar"
PLUGIN_FILE="Jenkinsfile/jenkins_plugin.txt"

# Check required env vars
if [[ -z "${JENKINS_URL:-}" || -z "${JENKINS_USER:-}" || -z "${JENKINS_PASS:-}" ]]; then
    echo "❌ Missing one or more required environment variables: JENKINS_URL, JENKINS_USER, JENKINS_PASS."
    exit 1
fi

# Download CLI if needed
if [[ ! -f "$CLI_JAR" ]]; then
    echo "🔽 Downloading Jenkins CLI..."
    wget -q "${JENKINS_URL}/jnlpJars/jenkins-cli.jar" -O "$CLI_JAR"
fi

echo -e "\n📦 Installing plugins from: $PLUGIN_FILE"
printf "\n%-30s | %-20s\n" "PLUGIN" "STATUS"
printf "%s\n" "--------------------------------+----------------------"

INSTALL_FLAG=false
TOTAL=0
INSTALLED=0
FAILED=0
SKIPPED=0

while IFS= read -r line || [[ -n "$line" ]]; do
    plugin=$(echo "$line" | sed 's/#.*//' | xargs)
    [[ -z "$plugin" ]] && continue

    ((TOTAL++))

    if java -jar "$CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASS" list-plugins | grep -E "^${plugin} " >/dev/null; then
        printf "%-30s | %-20s\n" "$plugin" "Already Installed"
        ((SKIPPED++))
    else
        if java -jar "$CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASS" install-plugin "$plugin"; then
            printf "%-30s | %-20s\n" "$plugin" "✅ Installed"
            INSTALL_FLAG=true
            ((INSTALLED++))
        else
            printf "%-30s | %-20s\n" "$plugin" "❌ Failed"
            ((FAILED++))
        fi
    fi
done < "$PLUGIN_FILE"

echo -e "\n📊 Summary:"
echo "➡️  Total plugins processed : $TOTAL"
echo "✅ Installed               : $INSTALLED"
echo "⚠️  Already Installed       : $SKIPPED"
echo "❌ Failed                  : $FAILED"

if [[ "$INSTALL_FLAG" == true ]]; then
    echo -e "\n🔄 Restarting Jenkins to apply plugin changes..."
    java -jar "$CLI_JAR" -s "$JENKINS_URL" -auth "$JENKINS_USER:$JENKINS_PASS" safe-restart
else
    echo -e "\n✅ No new plugins installed. Jenkins restart not required."
fi
