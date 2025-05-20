#!/bin/bash
set -euo pipefail

ACTION=$1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/jenkins.env"

echo "📁 SCRIPT_DIR     = $SCRIPT_DIR"
echo "📁 PROJECT_ROOT   = $PROJECT_ROOT"
echo "📝 ENV_FILE       = $ENV_FILE"

# Load environment variables
if [[ -f "$ENV_FILE" ]]; then
  set -o allexport
  source "$ENV_FILE"
  set +o allexport
fi

if [[ "${ACTION}" == "create" ]]; then
  echo "🚀 Creating Azure Container Registry..."

  # Check required environment variables
  if [[ -z "${SUBSCRIPTION_ID:-}" ]]; then
    echo "❌ SUBSCRIPTION_ID is not set in env or jenkins.env"
    exit 1
  fi

  if [[ -z "${RESOURCE_GROUP:-}" ]]; then
    echo "❌ RESOURCE_GROUP is not set in env or jenkins.env"
    exit 1
  fi

  if [[ -z "${AZURE_REGION:-}" ]]; then
    echo "❌ AZURE_REGION is not set in env or jenkins.env"
    exit 1
  fi

  # Create a unique ACR name
  ACR_NAME="kubernetes$(openssl rand -hex 4)"

  echo "🔧 ACR_NAME        = $ACR_NAME"
  echo "🔧 RESOURCE_GROUP  = $RESOURCE_GROUP"
  echo "🔧 LOCATION        = $AZURE_REGION"
  echo "🔧 SUBSCRIPTION_ID = $SUBSCRIPTION_ID"

  az acr create \
    --name "$ACR_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --location "$AZURE_REGION" \
    --sku Standard \
    --admin-enabled true \
    --subscription "$SUBSCRIPTION_ID"

  echo "✅ ACR created successfully."

  echo "🔄 Updating jenkins.env..."

  {
    echo "ACR_NAME=$ACR_NAME"
    echo "ACR_RESOURCE_ID=$(az acr show --name "$ACR_NAME" --resource-group "$RESOURCE_GROUP" --subscription "$SUBSCRIPTION_ID" --query id -o tsv)"
  } >> "$ENV_FILE"

  echo "✅ jenkins.env updated with ACR details."
else
  echo "❌ Invalid action: $ACTION"
  echo "Usage: ./acr.sh create"
  exit 1
fi
