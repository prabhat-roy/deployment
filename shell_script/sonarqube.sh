#!/bin/bash
set -euo pipefail

# --- CONFIGURATION ---
SONARQUBE_CONTAINER_NAME="sonarqube"
SONARQUBE_PORT=9000
SONARQUBE_ADMIN_USER="admin"
SONARQUBE_ADMIN_PASS="admin"
SONARQUBE_NEW_PASS="sonar"
SONARQUBE_TOKEN_NAME="jenkins-token"
JENKINS_SONAR_CRED_ID="jenkins-cred"
CLI_JAR="/tmp/jenkins-cli.jar"

# Required ENV
: "${JENKINS_URL:?Missing JENKINS_URL}"
: "${JENKINS_CRED_USER:?Missing JENKINS_CRED_USER}"
: "${JENKINS_CRED_PASS:?Missing JENKINS_CRED_PASS}"

# --- DOWNLOAD JENKINS CLI ---
if [[ ! -f "$CLI_JAR" ]]; then
  echo "⬇️  Downloading Jenkins CLI..."
  wget -q "$JENKINS_URL/jnlpJars/jenkins-cli.jar" -O "$CLI_JAR"
fi

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

# --- CHECK IF CREDENTIAL EXISTS ---
echo "🔍 Checking if Jenkins credential '${JENKINS_SONAR_CRED_ID}' exists..."
CRED_LIST=$(java -jar "$CLI_JAR" -s "$JENKINS_URL" --auth "$JENKINS_CRED_USER:$JENKINS_CRED_PASS" list-credentials system::system::jenkins _)

if echo "$CRED_LIST" | grep -q "$JENKINS_SONAR_CRED_ID"; then
  echo "✅ Credential '${JENKINS_SONAR_CRED_ID}' already exists. Skipping creation."
else
  # --- CREATE SECRET TEXT CREDENTIAL IN JENKINS ---
  echo "🔧 Creating secret text credential '${JENKINS_SONAR_CRED_ID}' in Jenkins..."
  cat <<EOF > /tmp/sonar-secret.xml
<com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
  <scope>GLOBAL</scope>
  <id>${JENKINS_SONAR_CRED_ID}</id>
  <description>SonarQube Token</description>
  <secret>${SONARQUBE_TOKEN}</secret>
</com.cloudbees.plugins.credentials.impl.StringCredentialsImpl>
EOF

  java -jar "$CLI_JAR" -s "$JENKINS_URL" --auth "$JENKINS_CRED_USER:$JENKINS_CRED_PASS" \
    create-credentials-by-xml system::system::jenkins _ < /tmp/sonar-secret.xml

  echo "✅ Jenkins credential '${JENKINS_SONAR_CRED_ID}' created."
fi
