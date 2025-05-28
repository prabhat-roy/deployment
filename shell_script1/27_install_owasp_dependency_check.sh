#!/bin/bash
set -euo pipefail

# --- Configuration ---
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin"
COOKIE_JAR="/tmp/jenkins_cookies.txt"
TOOL_NAME="OWASP-DependencyCheck"
DC_CLI_DIR="/opt/dependency-check"
NVD_DIR="/opt/dependency-check-data"
MAX_RETRIES=3

# --- Logging helpers ---
log_info() {
    echo -e "🟩 $*"
}

log_error() {
    echo -e "🟥 $*" >&2
}

log_step() {
    echo -e "\n🔧 STEP: $*"
}

# --- Step 1: Wait for Jenkins API ---
log_step "Waiting for Jenkins API to become available..."
until curl -sf -u "$JENKINS_USER:$JENKINS_PASSWORD" "$JENKINS_URL/crumbIssuer/api/json" > /dev/null 2>&1; do
    echo -n "."
    sleep 5
done
echo ""
log_info "Jenkins API is ready."

# --- Step 2: Download Dependency-Check CLI ---
log_step "Downloading OWASP Dependency-Check CLI..."
VERSION=$(curl -s https://dependency-check.github.io/DependencyCheck/current.txt)
curl -Ls "https://github.com/dependency-check/DependencyCheck/releases/download/v$VERSION/dependency-check-$VERSION-release.zip" -o /tmp/dependency-check.zip

log_info "Extracting to $DC_CLI_DIR"
sudo rm -rf "$DC_CLI_DIR"
sudo mkdir -p "$DC_CLI_DIR"
sudo unzip -q /tmp/dependency-check.zip -d "$DC_CLI_DIR"
sudo chown -R jenkins:jenkins "$DC_CLI_DIR"

# --- Step 3: Download NVD database ---
log_step "Downloading NVD database into $NVD_DIR..."
sudo mkdir -p "$NVD_DIR"
sudo chown -R jenkins:jenkins "$NVD_DIR"

ATTEMPT=1
SUCCESS=0
while [[ $ATTEMPT -le $MAX_RETRIES ]]; do
    log_info "Attempt $ATTEMPT of $MAX_RETRIES..."
    if "$DC_CLI_DIR"/dependency-check/bin/dependency-check.sh --updateonly --data "$NVD_DIR"; then
        log_info "NVD data downloaded successfully."
        SUCCESS=1
        break
    else
        log_error "Update failed. Retrying..."
    fi
    ATTEMPT=$((ATTEMPT + 1))
    sleep 10
done

if [[ $SUCCESS -ne 1 ]]; then
    log_error "Failed to download NVD data after $MAX_RETRIES attempts."
    exit 1
fi

# --- Step 4: Fetch Jenkins crumb ---
log_step "Fetching Jenkins crumb..."
CRUMB_JSON=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" -c "$COOKIE_JAR" "$JENKINS_URL/crumbIssuer/api/json")
CRUMB_FIELD=$(echo "$CRUMB_JSON" | jq -r '.crumbRequestField')
CRUMB_VALUE=$(echo "$CRUMB_JSON" | jq -r '.crumb')

if [[ -z "$CRUMB_FIELD" || -z "$CRUMB_VALUE" || "$CRUMB_FIELD" == "null" || "$CRUMB_VALUE" == "null" ]]; then
    log_error "Failed to fetch Jenkins crumb."
    exit 1
fi

log_info "Crumb acquired: $CRUMB_FIELD"

# --- Step 5: Register tool in Jenkins ---
log_step "Preparing Groovy script to register Dependency-Check in Jenkins..."
GROOVY_SCRIPT=$(cat <<EOF
import jenkins.model.Jenkins
import org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstallation

def toolName = "$TOOL_NAME"
def toolHome = "$DC_CLI_DIR"

def jenkins = Jenkins.get()
def descriptor = jenkins.getDescriptorByType(org.jenkinsci.plugins.DependencyCheck.tools.DependencyCheckInstallation.DescriptorImpl.class)

def existing = descriptor.getInstallations().find { it.name == toolName }

if (existing) {
    println "✔ Tool '\$toolName' already registered. Updating path..."
    existing.home = toolHome
} else {
    println "➕ Registering new tool '\$toolName' at '\$toolHome'"
    def newTool = new DependencyCheckInstallation(toolName, toolHome, null)
    def allTools = descriptor.getInstallations().toList()
    allTools.add(newTool)
    descriptor.setInstallations(allTools.toArray(new DependencyCheckInstallation[0]))
}

descriptor.save()
jenkins.save()
println "✅ Dependency-Check tool '\$toolName' registered successfully."
EOF
)

log_step "Sending Groovy script to Jenkins..."
RESPONSE=$(curl -s -L -w "\nHTTP_STATUS_CODE:%{http_code}\n" \
    -u "$JENKINS_USER:$JENKINS_PASSWORD" \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    -H "$CRUMB_FIELD: $CRUMB_VALUE" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    --data-urlencode "script=$GROOVY_SCRIPT" \
    "$JENKINS_URL/scriptText")

HTTP_CODE=$(echo "$RESPONSE" | grep "HTTP_STATUS_CODE" | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_STATUS_CODE/d')

if [[ "$HTTP_CODE" == "200" ]]; then
    log_info "Tool registration complete."
    echo "$BODY"
else
    log_error "Tool registration failed with status $HTTP_CODE"
    echo "$BODY"
    exit 1
fi

# --- Step 6: Setup cron job to update NVD database daily ---
log_step "Setting up daily cron job to update NVD database..."

LOG_FILE="/var/log/dependency-check-update.log"
CRON_CMD="$DC_CLI_DIR/dependency-check/bin/dependency-check.sh --updateonly --data $NVD_DIR >> $LOG_FILE 2>&1"
CRON_JOB="0 3 * * * $CRON_CMD"

# Create log file if it doesn't exist and set ownership/permissions
if [ ! -f "$LOG_FILE" ]; then
    sudo touch "$LOG_FILE"
    sudo chown jenkins:jenkins "$LOG_FILE"
    sudo chmod 644 "$LOG_FILE"
    log_info "Created log file $LOG_FILE with ownership jenkins:jenkins and permissions 644."
else
    # Ensure ownership and permissions are correct
    sudo chown jenkins:jenkins "$LOG_FILE"
    sudo chmod 644 "$LOG_FILE"
fi

# Check if the cron job is already installed for jenkins user
if sudo crontab -u jenkins -l 2>/dev/null | grep -Fq "$CRON_CMD"; then
    log_info "Cron job already installed."
else
    (sudo crontab -u jenkins -l 2>/dev/null; echo "$CRON_JOB") | sudo crontab -u jenkins -
    log_info "Cron job added: $CRON_JOB"
fi

log_info "🎉 Dependency-Check CLI setup, Jenkins registration, and cron job configuration complete."
