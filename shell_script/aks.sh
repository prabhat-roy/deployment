#!/bin/bash
set -euo pipefail

ACTION=$1  # allowed: apply or destroy

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="${PROJECT_ROOT}/jenkins.env"
TF_DIR="${PROJECT_ROOT}/Terraform/Azure/AKS"

echo "📁 SCRIPT_DIR     = $SCRIPT_DIR"
echo "📁 PROJECT_ROOT   = $PROJECT_ROOT"
echo "📁 TERRAFORM_DIR  = $TF_DIR"
echo "📝 ENV_FILE       = $ENV_FILE"

# Load environment variables
if [[ -f "$ENV_FILE" ]]; then
  set -o allexport
  source "$ENV_FILE"
  set +o allexport
else
  echo "❌ Environment file not found: $ENV_FILE"
  exit 1
fi

# Check required environment variables
: "${SUBSCRIPTION_ID:?❌ SUBSCRIPTION_ID is not set in env}"
: "${AZURE_REGION:?❌ AZURE_REGION is not set in env}"
: "${RESOURCE_GROUP:?❌ RESOURCE_GROUP is not set in env}"

# Validate action
if [[ "$ACTION" != "apply" && "$ACTION" != "destroy" ]]; then
  echo "❌ Invalid action: $ACTION"
  echo "Usage: $0 apply|destroy"
  exit 1
fi

cd "$TF_DIR"

# Format and validate
echo "🧹 Running terraform fmt..."
terraform fmt -recursive

echo "🔍 Running terraform validate..."
terraform validate

# Initialize Terraform
echo "🔧 Running terraform init..."
terraform init -upgrade

if [[ "$ACTION" == "apply" ]]; then
  echo "🚀 Creating AKS cluster and custom node pool..."

  terraform apply -auto-approve \
    -var="subscription_id=${SUBSCRIPTION_ID}" \
    -var="resource_group=${RESOURCE_GROUP}" \
    -var="azure_region=${AZURE_REGION}" \
    -var="remove_default_pool=false"

  echo "🧵 Deleting default node pool..."
  terraform apply -auto-approve \
    -var="subscription_id=${SUBSCRIPTION_ID}" \
    -var="resource_group=${RESOURCE_GROUP}" \
    -var="azure_region=${AZURE_REGION}" \
    -var="remove_default_pool=true"

  echo "✅ Cluster ready with custom node pool only."
elif [[ "$ACTION" == "destroy" ]]; then
  echo "🔥 Destroying AKS cluster and node pools..."
  terraform destroy -auto-approve \
    -var="subscription_id=${SUBSCRIPTION_ID}" \
    -var="resource_group=${RESOURCE_GROUP}" \
    -var="azure_region=${AZURE_REGION}" \
    -var="remove_default_pool=false"
  echo "✅ Cluster destroyed."
fi
