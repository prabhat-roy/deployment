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

# Export Terraform variables
export TF_VAR_subscription_id="$SUBSCRIPTION_ID"
export TF_VAR_location="$AZURE_REGION"
export TF_VAR_resource_group="$RESOURCE_GROUP"

# Move to Terraform directory
cd "$TF_DIR"

# Format and validate
echo "🧹 Running terraform fmt..."
terraform fmt -check

echo "🔍 Running terraform validate..."
terraform validate

# Initialize Terraform
echo "🔧 Running terraform init..."
terraform init -input=false

# Run the Terraform action
echo "🚀 Running terraform $ACTION..."
terraform "$ACTION" -auto-approve

echo "✅ Terraform $ACTION completed successfully."
