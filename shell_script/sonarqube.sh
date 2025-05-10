#!/bin/bash
set -euo pipefail

# --- CONFIGURATION ---
SONARQUBE_CONTAINER_NAME="sonarqube"
SONARQUBE_PORT=9000
SONARQUBE_ADMIN_USER="admin"
SONARQUBE_ADMIN_PASS="admin"
SONARQUBE_NEW_PASS="sonar"
SONARQUBE_TOKEN_NAME="jenkins-token"
JENKINS_CRED_ID="jenkins-cred"
CLI_JAR="/tmp/jenkins-cli.jar"

# Fetch Jenkins credentials from Jenkins credentials store (jenkins-cred)
: "${JENKINS_URL:?Missing JENKINS_URL}"
: "${JENKINS_CRED_ID:?Missing JENKINS_CRED_ID}"

echo "📡 Fetching Jenkins credentials from Jenkins..."
JENKINS_USER=$(java -jar "$CLI_JAR" -s "$JENKINS_URL" get-credentials --credential-id "$JENKINS_CRED_ID" | jq -r '.username')
JENKINS_PASS=$(java -jar "$CLI_JAR" -s "$JENKINS_URL" get-credentials --credential-id "$JENKINS_CRED_ID" | jq -r '.password')

# --- START SONARQUBE ---
echo "📦 Pulling SonarQube..."
docker pull sonarqube:latest

echo "🚀 Running SonarQube container in background..."
docker run -dt --rm --name "$SONARQUBE_CONTAINER_NAME" -p ${SONARQUBE_PORT}:9000 -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true sonarqube:latest

# --- WAIT FOR SONARQUBE TO BE READY ---
echo "⏳ Waiting for SonarQube to become healthy..."
until curl -s "http://localhost:${SONARQUBE_PORT}/api/system/health" | grep -q '"status":"GREEN"'; do
  sleep 5
done

# --- CHANGE INITIAL PASSWORD ---
echo "🔐 Changing default password..."
curl -s -u "${SONARQUBE_ADMIN_USER}:${SONARQUBE_ADMIN_PASS}" \
  -X POST "http://localhost:${SONARQUBE_PORT}/api/users/change_password" \
  -d "login=${SONARQUBE_ADMIN_USER}&previousPassword=${SONARQUBE_ADMIN_PASS}&password=${SONARQUBE_NEW_PASS}" || true

# --- GENERATE TOKEN ---
echo "🔑 Generating SonarQube token..."
SONARQUBE_TOKEN=$(curl -s -u "${SONARQUBE_ADMIN_USER}:${SONARQUBE_NEW_PASS}" \
  -X POST "http://localhost:${SONARQUBE_PORT}/api/user_tokens/generate" \
  -d "name=${SONARQUBE_TOKEN_NAME}" | jq -r '.token')

echo "✅ Token: $SONARQUBE_TOKEN"

# --- DOWNLOAD JENKINS CLI ---
if [[ ! -f "$CLI_JAR" ]]; then
  echo "⬇️  Downloading Jenkins CLI..."
  wget -q "$JENKINS_URL/jnlpJars/jenkins-cli.jar" -O "$CLI_JAR"
fi

# --- CHECK IF JENKINS CREDENTIAL EXISTS ---
echo "🔍 Checking if Jenkins credential '${JENKINS_CRED_ID}' exists..."
CRED_EXISTS=$(java -jar "$CLI_JAR" -s "$JENKINS_URL" --auth "$JENKINS_USER:$JENKINS_PASS" list-credentials --credential-id "$JENKINS_CRED_ID" | grep -c "$JENKINS_CRED_ID")

if [ "$CRED_EXISTS" -eq 0 ]; then
  # --- CREATE SECRET TEXT CREDENTIAL IN JENKINS ---
  echo "🔧 Creating secret text credential in Jenkins..."

  cat <<EOF > /tmp/sonar-secret.xml
<com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>${JENKINS_CRED_ID}</id>
  <description>SonarQube Token</description>
  <secret>${SONARQUBE_TOKEN}</secret>
</com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
EOF

  java -jar "$CLI_JAR" -s "$JENKINS_URL" --auth "$JENKINS_USER:$JENKINS_PASS" \
    create-credentials-by-xml system::system::jenkins _ < /tmp/sonar-secret.xml

  echo "✅ Jenkins credential '${JENKINS_CRED_ID}' created."
else
  echo "✅ Jenkins credential '${JENKINS_CRED_ID}' already exists, skipping creation."
fi
