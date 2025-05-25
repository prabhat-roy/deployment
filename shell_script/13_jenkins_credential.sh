#!/bin/bash
set -euo pipefail

# --- Configuration ---
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin"
TOKEN_NAME="Jenkins-Token"
CRED_ID="jenkins-cred"
COOKIE_JAR="/tmp/jenkins_cookies.txt"

# --- Delay for Jenkins restart completion ---
echo "⏳ Jenkins restart was just triggered. Waiting 30 seconds before checking readiness..."
sleep 30

# --- Function to wait for Jenkins full readiness ---
wait_for_jenkins_ready() {
    echo "⏳ Waiting for Jenkins to be fully ready (API available)..."
    until curl -sf -u "$JENKINS_USER:$JENKINS_PASSWORD" "$JENKINS_URL/crumbIssuer/api/json" > /dev/null 2>&1; do
        echo -n "."
        sleep 5
    done
    echo ""
    echo "✅ Jenkins API is ready."
}

# --- Wait for Jenkins to be ready ---
wait_for_jenkins_ready

# --- Step 1: Fetch crumb using user/password ---
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

# --- Step 2: Create API token ---
echo "🔑 Creating API token for user '$JENKINS_USER'..."
RESPONSE=$(curl -s -u "$JENKINS_USER:$JENKINS_PASSWORD" \
  -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
  -H "$CRUMB_FIELD: $CRUMB_VALUE" \
  -H "Content-Type: application/json" \
  -X POST "$JENKINS_URL/user/$JENKINS_USER/descriptorByName/jenkins.security.ApiTokenProperty/generateNewToken" \
  -d "{\"newTokenName\": \"$TOKEN_NAME\"}")

API_TOKEN=$(echo "$RESPONSE" | grep -oP '(?<="tokenValue":")[^"]+')

if [ -z "$API_TOKEN" ]; then
  echo "❌ Failed to create API token."
  echo "Response was: $RESPONSE"
  exit 1
fi

echo "✅ API token created successfully."

# --- Step 3: Fetch crumb using token auth ---
AUTH_USER="$JENKINS_USER"
AUTH_PASS="$API_TOKEN"

echo "🔐 Fetching CSRF crumb with token auth..."
CRUMB_JSON=$(curl -s -u "$AUTH_USER:$AUTH_PASS" -c "$COOKIE_JAR" -b "$COOKIE_JAR" "$JENKINS_URL/crumbIssuer/api/json")

if ! echo "$CRUMB_JSON" | jq . > /dev/null 2>&1; then
    echo "❌ Crumb response not valid JSON:"
    echo "$CRUMB_JSON"
    exit 1
fi

CRUMB_FIELD=$(echo "$CRUMB_JSON" | jq -r '.crumbRequestField')
CRUMB_VALUE=$(echo "$CRUMB_JSON" | jq -r '.crumb')

if [[ -z "$CRUMB_FIELD" || -z "$CRUMB_VALUE" || "$CRUMB_FIELD" == "null" || "$CRUMB_VALUE" == "null" ]]; then
    echo "❌ Failed to fetch crumb with token auth. Response was: $CRUMB_JSON"
    exit 1
fi

echo "✅ Crumb fetched with token auth: $CRUMB_FIELD: $CRUMB_VALUE"

# --- Step 4: Create global credential ---
echo "📦 Creating global credential ID '$CRED_ID' with username + token..."

JSON_PAYLOAD=$(cat <<EOF
{
  "": "0",
  "credentials": {
    "scope": "GLOBAL",
    "id": "$CRED_ID",
    "username": "$AUTH_USER",
    "password": "$AUTH_PASS",
    "description": "User token credential",
    "\$class": "com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl"
  }
}
EOF
)

RESPONSE=$(curl -s -L -w "\nHTTP_STATUS_CODE:%{http_code}\n" -u "$AUTH_USER:$AUTH_PASS" \
  -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
  -H "$CRUMB_FIELD: $CRUMB_VALUE" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  --data-urlencode "json=$JSON_PAYLOAD" \
  "$JENKINS_URL/credentials/store/system/domain/_/createCredentials")

echo "📡 Response from Jenkins credentials API:"
echo -e "$RESPONSE"

# --- Step 5: Save API token to file ---
echo "$API_TOKEN" > api_token.txt
echo "📝 API token saved to 'api_token.txt'"
