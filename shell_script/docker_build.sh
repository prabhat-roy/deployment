#!/bin/bash
set -euo pipefail

# Ensure BUILD_NUMBER is available
BUILD_NUMBER="${1:-}"
if [[ -z "$BUILD_NUMBER" ]]; then
  echo "❌ Error: BUILD_NUMBER not provided!"
  echo "Usage: $0 <build-number>"
  exit 1
fi

# Ensure SERVICES is available
if [[ -z "${SERVICES:-}" ]]; then
  echo "❌ Error: SERVICES environment variable not set!"
  exit 1
fi

# Split SERVICES into array
IFS=',' read -r -a SERVICE_LIST <<< "$SERVICES"

# Loop through services and build Docker images
for SERVICE in "${SERVICE_LIST[@]}"; do
  echo "🐳 Processing service: $SERVICE"

  SERVICE_DIR="src/$SERVICE"
  DOCKERFILE_PATH="$SERVICE_DIR/Dockerfile"

  if [[ ! -d "$SERVICE_DIR" ]]; then
    echo "⚠️  Skipping: Directory '$SERVICE_DIR' not found."
    continue
  fi

  if [[ ! -f "$DOCKERFILE_PATH" ]]; then
    echo "⚠️  Skipping: No Dockerfile found in '$SERVICE_DIR'."
    continue
  fi

  IMAGE_TAG="${SERVICE}:${BUILD_NUMBER}"
  echo "📦 Building Docker image: ${IMAGE_TAG}"

  # Run docker build with --no-cache option if you want to avoid using cache
  docker build --no-cache -t "${IMAGE_TAG}" "$SERVICE_DIR"
  
  echo "✅ Built ${IMAGE_TAG}"
done

echo "🚀 All Docker builds complete."
