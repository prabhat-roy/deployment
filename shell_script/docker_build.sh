#!/bin/bash

set -e

SERVICE=$1
BUILD_NUMBER=$2

if [ -z "$SERVICE" ] || [ -z "$BUILD_NUMBER" ]; then
  echo "❌ SERVICE or BUILD_NUMBER is not provided!"
  exit 1
fi

echo "🐳 Starting Docker image build for service: $SERVICE with build number: $BUILD_NUMBER"

# Path to the service's directory inside the src folder
SERVICE_DIR="src/$SERVICE"

# Ensure the service directory exists
if [ ! -d "$SERVICE_DIR" ]; then
  echo "❌ Service directory '$SERVICE_DIR' does not exist!"
  exit 1
fi

# Build the Docker image
echo "🔧 Building Docker image for $SERVICE"
docker build -t "$SERVICE:$BUILD_NUMBER" "$SERVICE_DIR"

echo "🔖 Tagging Docker image $SERVICE:$BUILD_NUMBER"
# Here, you can push the image to a registry if necessary
# For example, to push it to AWS ECR, Azure ACR, or GCP GAR, you can add the relevant push commands

echo "🚀 Docker image for $SERVICE built and tagged as $SERVICE:$BUILD_NUMBER."
