#!/bin/bash
set -euo pipefail

# Find this script's location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${PROJECT_ROOT}/jenkins.env"

echo "📁 SCRIPT_DIR     = $SCRIPT_DIR"
echo "📁 PROJECT_ROOT   = $PROJECT_ROOT"
echo "📝 ENV_FILE       = $ENV_FILE"

# Required variables
: "${ACR_NAME:?Environment variable ACR_NAME not set}"
: "${SUBSCRIPTION_ID:?Environment variable SUBSCRIPTION_ID not set}"

# Get ACR login server from Azure CLI
ACR_LOGIN_SERVER=$(az acr show \
  --name "$ACR_NAME" \
  --subscription "$SUBSCRIPTION_ID" \
  --query "loginServer" \
  --output tsv)

echo "✅ ACR login server: $ACR_LOGIN_SERVER"

# Ensure env file exists
if [[ ! -f "$ENV_FILE" ]]; then
  echo "⚠️  jenkins.env not found. Creating it at $ENV_FILE"
  touch "$ENV_FILE"
fi

# Clean previous values
sed -i '/^ACR_LOGIN_SERVER=/d' "$ENV_FILE"
sed -i '/^ACR_NAME=/d' "$ENV_FILE"

# Append new values
{
  echo "ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER"
  echo "ACR_NAME=$ACR_NAME"
} >> "$ENV_FILE"

echo "✅ jenkins.env updated successfully."
