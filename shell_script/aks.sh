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
else
  echo "❌ $ENV_FILE not found."
  exit 1
fi

# Validate required variables
if [[ -z "${SUBSCRIPTION_ID:-}" ]]; then
  echo "❌ SUBSCRIPTION_ID is not set"
  exit 1
fi

if [[ -z "${RESOURCE_GROUP:-}" ]]; then
  echo "❌ RESOURCE_GROUP is not set"
  exit 1
fi

if [[ -z "${AZURE_REGION:-}" ]]; then
  echo "❌ AZURE_REGION is not set"
  exit 1
fi

if [[ "$ACTION" == "create" ]]; then
  echo "🚀 Creating Azure Kubernetes Service (AKS) Cluster..."

  # Generate a unique name
  AKS_NAME="akscluster$(openssl rand -hex 3)"

  echo "🔧 AKS_NAME        = $AKS_NAME"
  echo "🔧 RESOURCE_GROUP  = $RESOURCE_GROUP"
  echo "🔧 LOCATION        = $AZURE_REGION"
  echo "🔧 SUBSCRIPTION_ID = $SUBSCRIPTION_ID"

  # Ensure resource group exists
  az group create \
    --name "$RESOURCE_GROUP" \
    --location "$AZURE_REGION" \
    --subscription "$SUBSCRIPTION_ID"

  # Create AKS cluster
  az aks create \
    --resource-group "$RESOURCE_GROUP" \
    --name "$AKS_NAME" \
    --location "$AZURE_REGION" \
    --enable-managed-identity \
    --node-count 2 \
    --generate-ssh-keys \
    --subscription "$SUBSCRIPTION_ID"

  echo "✅ AKS cluster created."

  echo "🔄 Updating jenkins.env..."
  {
    echo "AKS_NAME=$AKS_NAME"
    echo "AKS_RESOURCE_ID=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" --subscription "$SUBSCRIPTION_ID" --query id -o tsv)"
  } >> "$ENV_FILE"

  echo "✅ jenkins.env updated with AKS details."

elif [[ "$ACTION" == "destroy" ]]; then
  echo "🔥 Destroying AKS Cluster..."

  if [[ -z "${AKS_NAME:-}" ]]; then
    echo "❌ AKS_NAME is not set in env. Cannot delete."
    exit 1
  fi

  az aks delete \
    --name "$AKS_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --yes \
    --subscription "$SUBSCRIPTION_ID"

  echo "✅ AKS cluster deleted."

  echo "🧹 Cleaning up jenkins.env..."
  sed -i.bak '/^AKS_NAME=/d;/^AKS_RESOURCE_ID=/d' "$ENV_FILE"

  echo "✅ AKS-related lines removed from jenkins.env."

else
  echo "❌ Invalid action: $ACTION"
  echo "Usage: ./aks.sh create|destroy"
  exit 1
fi
