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
terraform init -input=false

if [[ "$ACTION" == "apply" ]]; then
  echo "🚀 Applying Terraform with 1 default node..."
  terraform apply -auto-approve -var="default_node_count=1"

  echo "🧵 Scaling default node pool to 0 nodes..."
  terraform apply -auto-approve -var="default_node_count=0"

  echo "✅ Cluster created and scaled to 0 nodes."
elif [[ "$ACTION" == "destroy" ]]; then
  echo "🔥 Destroying AKS cluster..."
  terraform destroy -auto-approve
  echo "✅ Cluster destroyed."
fi
