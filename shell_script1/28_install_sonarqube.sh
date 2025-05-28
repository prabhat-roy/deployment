#!/bin/bash
set -euo pipefail

# --- Configuration ---
SONAR_CONTAINER_NAME="sonarqube"
SONAR_IMAGE="sonarqube:lts"
SONAR_PORT=9000
SONARQUBE_URL="http://localhost:$SONAR_PORT"
SONAR_ADMIN="admin"
SONAR_PASS="admin"
NEW_SONAR_PASS="admin123Secure!"
SONAR_TOKEN_NAME="jenkins-token"
SONAR_TOKEN_FILE="sonar_token.txt"

JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin"
JENKINS_CRED_ID="sonarqube-token"
COOKIE_JAR="/tmp/jenkins_cookies.txt"

TOOLS_DIR="/opt/jenkins-tools"
SONAR_CLI_DIR="$TOOLS_DIR/sonar-scanner"
SONAR_MSBUILD_DIR="$TOOLS_DIR/sonar-msbuild"

# --- Functions ---

start_sonarqube() {
    echo "🚀 Starting SonarQube container..."
    docker rm -f "$SONAR_CONTAINER_NAME" 2>/dev/null || true
    docker run -d --name "$SONAR_CONTAINER_NAME" -p "$SONAR_PORT:9000" "$SONAR_IMAGE" > /dev/null

    echo "⏳ Waiting for SonarQube to be ready..."
    until curl -sf "$SONARQUBE_URL/api/system/status" | grep -q '"status":"UP"'; do
        echo -n "."
        sleep 5
    done
    echo -e "\n✅ SonarQube is up and running."
}

change_sonar_password() {
    echo "🔐 Changing SonarQube default password..."
    curl -sf -u "$SONAR_ADMIN:$SONAR_PASS" \
        -X POST "$SONARQUBE_URL/api/users/change_password" \
        -d "login=$SONAR_ADMIN&previousPassword=$SONAR_PASS&password=$NEW_SONAR_PASS"
    echo "✅ SonarQube password changed."
}

generate_sonar_token() {
    echo "🔑 Generating SonarQube token..."
    local response
    response=$(curl -s -u "$SONAR_ADMIN:$NEW_SONAR_PASS" \
        -X POST "$SONARQUBE_URL/api/user_tokens/generate" \
        -d "name=$SONAR_TOKEN_NAME")

    SONAR_TOKEN=$(echo "$response" | jq -r '.token')
    if [[ -z "$SONAR_TOKEN" || "$SONAR_TOKEN" == "null" ]]; then
        echo "❌ Failed to generate SonarQube token. Response: $response"
        exit 1
    fi

    echo "$SONAR_TOKEN" > "$SONAR_TOKEN_FILE"
    echo "📝 SonarQube token saved to $SONAR_TOKEN_FILE"
}

wait_for_jenkins_ready() {
    echo "⏳ Waiting for Jenkins to be fully ready..."
    until curl -sf -u "$JENKINS_USER:$JENKINS_PASSWORD" "$JENKINS_URL/crumbIssuer/api/json" > /dev/null 2>&1; do
        echo -n "."
        sleep 5
    done
    echo -e "\n✅ Jenkins API is ready."
}

fetch_jenkins_crumb() {
    echo "🔐 Fetching Jenkins crumb and cookie..."
    CRUMB_JSON=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" -c "$COOKIE_JAR" "$JENKINS_URL/crumbIssuer/api/json")
    CRUMB_FIELD=$(echo "$CRUMB_JSON" | jq -r '.crumbRequestField')
    CRUMB_VALUE=$(echo "$CRUMB_JSON" | jq -r '.crumb')
}

create_jenkins_secret_text_credential() {
    echo "📦 Creating Jenkins secret text credential for SonarQube..."

    # Clean token of newlines and spaces
    TOKEN_CLEAN=$(echo -n "$SONAR_TOKEN" | tr -d '\n' | tr -d ' ')

    JSON_PAYLOAD=$(cat <<EOF
{
  "": "0",
  "credentials": {
    "scope": "GLOBAL",
    "id": "$JENKINS_CRED_ID",
    "secret": "$TOKEN_CLEAN",
    "description": "SonarQube API token",
    "\$class": "org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl"
  }
}
EOF
)

    RESPONSE=$(curl -s -w "\nHTTP_STATUS_CODE:%{http_code}\n" -u "$JENKINS_USER:$JENKINS_PASSWORD" \
      -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
      -H "$CRUMB_FIELD: $CRUMB_VALUE" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      --data-urlencode "json=$JSON_PAYLOAD" \
      "$JENKINS_URL/credentials/store/system/domain/_/createCredentials")

    HTTP_CODE=$(echo "$RESPONSE" | grep HTTP_STATUS_CODE | cut -d: -f2 | tr -d '[:space:]')

    if [[ "$HTTP_CODE" != "200" ]]; then
        echo "❌ Failed to create Jenkins credential. Response:"
        echo "$RESPONSE"
        exit 1
    fi
    echo "✅ Jenkins credential created: $JENKINS_CRED_ID"
}

register_sonar_tools_server() {
    echo "🛠️ Registering SonarScanner tools and SonarQube server in Jenkins..."

    local groovy_script
    groovy_script=$(cat <<EOF
import jenkins.model.*
import hudson.plugins.sonar.*
import org.sonarsource.scanner.msbuild.SonarQubeMSBuildInstallation
import hudson.tools.ToolProperty

def instance = Jenkins.getInstance()

def sonarCLI = new SonarRunnerInstallation(
    "SonarScanner CLI",
    "$SONAR_CLI_DIR",
    [] as List<ToolProperty<?>>
)
instance.getDescriptorByType(SonarRunnerInstallation.DescriptorImpl).setInstallations(sonarCLI)

def msbuild = new SonarQubeMSBuildInstallation(
    "SonarScanner for MSBuild",
    "$SONAR_MSBUILD_DIR",
    [] as List<ToolProperty<?>>
)
instance.getDescriptorByType(SonarQubeMSBuildInstallation.DescriptorImpl).setInstallations(msbuild)

def sonarServer = new SonarInstallation(
    "SonarQube",
    "$SONARQUBE_URL",
    "$JENKINS_CRED_ID",
    "", "", ""
)
instance.getDescriptorByType(SonarGlobalConfiguration.class).setInstallations(sonarServer)

instance.save()
println("✅ SonarScanner tools and SonarQube server registered.")
EOF
)

    curl -s -X POST "$JENKINS_URL/scriptText" \
         -u "$JENKINS_USER:$JENKINS_PASSWORD" \
         -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
         -H "$CRUMB_FIELD: $CRUMB_VALUE" \
         -H "Content-Type: application/x-www-form-urlencoded" \
         --data-urlencode "script=$groovy_script"
}

# --- Main Execution ---

start_sonarqube
change_sonar_password
generate_sonar_token

wait_for_jenkins_ready
fetch_jenkins_crumb
create_jenkins_secret_text_credential
register_sonar_tools_server

echo "🎉 All done!"
