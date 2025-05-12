#!/bin/bash

set -euo pipefail

SERVICE="${1:-}"
BUILD_NUMBER="${2:-}"

if [[ -z "$SERVICE" || -z "$BUILD_NUMBER" ]]; then
  echo "❌ Error: SERVICE or BUILD_NUMBER not provided."
  echo "Usage: $0 <service-name> <build-number>"
  exit 1
fi

echo "🐳 Starting Docker image build..."
echo "📦 Service: $SERVICE"
echo "🏷️  Build Number: $BUILD_NUMBER"

SERVICE_DIR="src/$SERVICE"

if [[ ! -d "$SERVICE_DIR" ]]; then
  echo "❌ Error: Directory '$SERVICE_DIR' does not exist!"
  exit 1
fi

echo "🔧 Building Docker image..."
docker build -t "${SERVICE}:${BUILD_NUMBER}" "$SERVICE_DIR"

echo "🏷️  Tagging Docker image as ${SERVICE}:${BUILD_NUMBER}"
# Add image push logic here if needed (e.g., Docker Hub, ECR, ACR, etc.)

echo "✅ Docker image for '$SERVICE' built and tagged successfully."
