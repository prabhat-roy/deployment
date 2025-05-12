#!/bin/bash
set -euo pipefail

# Load environment variables from Jenkins.env
# ENV_FILE="Jenkins.env"
# if [[ ! -f "$ENV_FILE" ]]; then
#   echo "❌ Environment file '$ENV_FILE' not found!"
#   exit 1
# fi
# # shellcheck source=/dev/null
# source "$ENV_FILE"

# Ensure SERVICES and BUILD_NUMBER are available
BUILD_NUMBER="${1:-}"
if [[ -z "$BUILD_NUMBER" ]]; then
  echo "❌ Error: BUILD_NUMBER not provided!"
  echo "Usage: $0 <build-number>"
  exit 1
fi

if [[ -z "${SERVICES:-}" ]]; then
  echo "❌ Error: SERVICES variable not set in $ENV_FILE"
  exit 1
fi

# Split SERVICES into array
IFS=',' read -r -a SERVICE_LIST <<< "$SERVICES"

# Loop through services and build Docker images
for SERVICE in "${SERVICE_LIST[@]}"; do
  echo "🐳 Building Docker image for service: $SERVICE"
  
  SERVICE_DIR="src/$SERVICE"
  
  if [[ ! -d "$SERVICE_DIR" ]]; then
    echo "⚠️  Skipping: Directory '$SERVICE_DIR' not found."
    continue
  fi

  docker build -t "${SERVICE}:${BUILD_NUMBER}" "$SERVICE_DIR"
  echo "✅ Built ${SERVICE}:${BUILD_NUMBER}"
done

echo "🚀 All Docker builds complete."
