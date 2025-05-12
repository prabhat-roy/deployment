#!/bin/bash
set -euo pipefail

# Ensure BUILD_NUMBER is provided
BUILD_NUMBER="${1:-}"
if [[ -z "$BUILD_NUMBER" ]]; then
  echo "❌ Error: BUILD_NUMBER not provided!"
  echo "Usage: $0 <build-number>"
  exit 1
fi

# Ensure DOCKER_SERVICES is set
if [[ -z "${DOCKER_SERVICES:-}" ]]; then
  echo "❌ Error: DOCKER_SERVICES environment variable not set!"
  exit 1
fi

# Split DOCKER_SERVICES into an array
IFS=',' read -r -a SERVICE_LIST <<< "$DOCKER_SERVICES"

# Loop through services and build Docker images
for SERVICE in "${SERVICE_LIST[@]}"; do
  echo "🐳 Processing service: $SERVICE"

  SERVICE_DIR="src/$SERVICE"

  if [[ ! -d "$SERVICE_DIR" ]]; then
    echo "⚠️  Skipping: Directory '$SERVICE_DIR' not found."
    continue
  fi

  IMAGE_TAG="${SERVICE}:${BUILD_NUMBER}"
  echo "📦 Building Docker image: ${IMAGE_TAG}"

  docker build --no-cache -t "${IMAGE_TAG}" "$SERVICE_DIR"
  
  echo "✅ Built ${IMAGE_TAG}"
done

echo "🚀 All Docker builds complete."
