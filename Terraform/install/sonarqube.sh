#!/bin/bash

set -e

echo "[INFO] 🔄 Pulling SonarQube image..."
docker pull sonarqube:lts

echo "[INFO] 🧼 Cleaning up old SonarQube container..."
docker rm -f sonarqube || true

echo "[INFO] 🗂️ Creating SonarQube required directories with correct permissions..."
mkdir -p /opt/sonarqube/{conf,data,logs,extensions}
chown -R 1000:1000 /opt/sonarqube

echo "[INFO] 🚀 Starting SonarQube container..."
docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  -v /opt/sonarqube/conf:/opt/sonarqube/conf \
  -v /opt/sonarqube/data:/opt/sonarqube/data \
  -v /opt/sonarqube/logs:/opt/sonarqube/logs \
  -v /opt/sonarqube/extensions:/opt/sonarqube/extensions \
  sonarqube:lts

echo "[INFO] ⏳ Waiting for SonarQube to become healthy..."
until curl -s http://localhost:9000/api/system/status | grep -q '"status":"UP"'; do
  echo "⌛ Still waiting for SonarQube..."
  sleep 5
done

echo "[INFO] ✅ SonarQube is up at http://localhost:9000"

echo "[INFO] 🔐 Attempting to change admin password..."
NEW_ADMIN_PASSWORD="YourNewSecurePassword"
COOKIE_JAR=$(mktemp)

# Login and store session
LOGIN_OUTPUT=$(curl -s -X POST http://localhost:9000/api/authentication/login \
  -c "$COOKIE_JAR" \
  -d "login=admin&password=admin")

# Change password
CHANGE_OUTPUT=$(curl -s -X POST http://localhost:9000/api/users/change_password \
  -b "$COOKIE_JAR" \
  -d "login=admin&previousPassword=admin&password=${NEW_ADMIN_PASSWORD}")

if echo "$CHANGE_OUTPUT" | grep -q '"errors"'; then
  echo "[WARNING] ❌ Failed to change admin password: $CHANGE_OUTPUT"
else
  echo "[INFO] ✅ Admin password changed to: $NEW_ADMIN_PASSWORD"
fi

rm -f "$COOKIE_JAR"

echo "[SUCCESS] 🟢 SonarQube is running and ready at http://localhost:9000"
