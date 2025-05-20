#!/bin/bash
set -euo pipefail

# Get the absolute path to this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="${SCRIPT_DIR%/*}"  # One level up from shell_script
ENV_FILE="${PROJECT_ROOT}/jenkins.env"

echo "📂 Script Directory : $SCRIPT_DIR"
echo "📁 Project Root     : $PROJECT_ROOT"
echo "📝 Using env file   : $ENV_FILE"

# Check for required variables
: "${ACR_NAME:?Environment variable ACR_NAME not set}"
: "${SUBSCRIPTION_ID:?Environment variable SUBSCRIPTION_ID not set}"

# Get ACR login server
ACR_LOGIN_SERVER=$(az acr show \
  --name "$ACR_NAME" \
  --subscription "$SUBSCRIPTION_ID" \
  --query "loginServer" \
  --output tsv)

echo "✅ ACR Login Server: $ACR_LOGIN_SERVER"

# Create env file if not exists
if [[ ! -f "$ENV_FILE" ]]; then
  echo "⚠️  jenkins.env not found. Creating one at $ENV_FILE"
  touch "$ENV_FILE"
fi

# Remove previous values if present
sed -i '/^ACR_LOGIN_SERVER=/d' "$ENV_FILE"
sed -i '/^ACR_NAME=/d' "$ENV_FILE"

# Append new values
{
  echo "ACR_LOGIN_SERVER=$ACR_LOGIN_SERVER"
  echo "ACR_NAME=$ACR_NAME"
} >> "$ENV_FILE"

echo "✅ jenkins.env updated successfully."
