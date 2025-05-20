#!/bin/bash
set -euo pipefail

ACTION=$1

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/jenkins.env"
TF_DIR="${PROJECT_ROOT}/Terraform/Azure/ACR"

echo "📁 SCRIPT_DIR     = $SCRIPT_DIR"
echo "📁 PROJECT_ROOT   = $PROJECT_ROOT"
echo "📁 TF_DIR         = $TF_DIR"
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

# Ensure required variables are present
for var in SUBSCRIPTION_ID RESOURCE_GROUP AZURE_REGION; do
  if [[ -z "${!var:-}" ]]; then
    echo "❌ $var is not set"
    exit 1
  fi
done

# Terraform commands
cd "$TF_DIR"

echo "🧹 Running terraform fmt..."
terraform fmt

echo "🔍 Running terraform validate..."
terraform validate

echo "🚀 Running terraform init..."
terraform init -upgrade

echo "💡 Terraform action: $ACTION"

if [[ "$ACTION" == "create" ]]; then
  echo "🚀 Creating ACR with Terraform..."

  terraform apply -auto-approve \
    -var "subscription_id=$SUBSCRIPTION_ID" \
    -var "resource_group=$RESOURCE_GROUP" \
    -var "location=$AZURE_REGION"

  # Get outputs
  ACR_NAME=$(terraform output -raw acr_name)
  ACR_RESOURCE_ID=$(terraform output -raw acr_resource_id)

  echo "🔄 Updating jenkins.env..."
  {
    echo "ACR_NAME=$ACR_NAME"
    echo "ACR_RESOURCE_ID=$ACR_RESOURCE_ID"
  } >> "$ENV_FILE"

  echo "✅ ACR created and jenkins.env updated."

elif [[ "$ACTION" == "destroy" ]]; then
  echo "🔥 Destroying ACR with Terraform..."

  terraform destroy -auto-approve \
    -var "subscription_id=$SUBSCRIPTION_ID" \
    -var "resource_group=$RESOURCE_GROUP" \
    -var "location=$AZURE_REGION"

  echo "🧹 Cleaning up jenkins.env..."
  sed -i.bak '/^ACR_NAME=/d;/^ACR_RESOURCE_ID=/d' "$ENV_FILE"
  echo "✅ ACR-related lines removed from jenkins.env."

else
  echo "❌ Invalid action: $ACTION"
  echo "Usage: ./acr.sh create|destroy"
  exit 1
fi
