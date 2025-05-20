#!/bin/bash

set -euo pipefail

ACTION="${1:-}"

if [[ -z "$ACTION" ]]; then
  echo "❌ ERROR: Action (create/destroy) not provided."
  echo "Usage: $0 <create|destroy>"
  exit 1
fi

if [[ "$ACTION" != "create" && "$ACTION" != "destroy" ]]; then
  echo "❌ ERROR: Invalid action '$ACTION'. Allowed: create, destroy."
  exit 1
fi

echo "📦 Loading environment variables..."
set -o allexport
source Jenkins.env
set +o allexport

echo "🔐 Logging into Azure CLI..."

if [[ -n "${AZURE_CLIENT_ID:-}" && -n "${AZURE_CLIENT_SECRET:-}" && -n "${AZURE_TENANT_ID:-}" ]]; then
  echo "Using Service Principal authentication"
  az login --service-principal -u "$AZURE_CLIENT_ID" -p "$AZURE_CLIENT_SECRET" --tenant "$AZURE_TENANT_ID"
else
  echo "Service Principal credentials not found, trying Managed Identity..."
  az login --identity
fi

echo "Setting subscription to $SUBSCRIPTION_ID"
az account set --subscription "$SUBSCRIPTION_ID"

echo "📜 Converting ACR_REPOS to Terraform list..."
IFS=',' read -r -a repos_array <<< "$DOCKER_SERVICES"
terraform_list=$(printf '"%s", ' "${repos_array[@]}")
terraform_list="[${terraform_list%, }]"

echo "🛠️ Writing terraform.tfvars..."
cat > Terraform/Azure/ACR/terraform.tfvars <<EOF
acr_repo_names = ${terraform_list}
azure_region   = "${LOCATION}"
resource_group = "${RESOURCE_GROUP_NAME}"
subscription_id = "${SUBSCRIPTION_ID}"
EOF

echo "🚀 Running Terraform (${ACTION^^})..."
cd Terraform/Azure/ACR

terraform init -input=false
terraform plan

if [[ "$ACTION" == "create" ]]; then
  terraform apply -auto-approve
elif [[ "$ACTION" == "destroy" ]]; then
  terraform destroy -auto-approve
fi

# Only update Jenkins.env if action is create
if [[ "$ACTION" == "create" ]]; then
  echo "🔄 Updating Jenkins.env with ACR info..."

  # Get ACR name from Terraform output
  ACR_NAME=$(terraform output -raw acr_name)
  # Get ACR login server from Azure CLI
  ACR_LOGIN_SERVER=$(az acr show --name "$ACR_NAME" --query "loginServer" --output tsv)

  # Backup Jenkins.env before editing
  cp ../Jenkins.env ../Jenkins.env.bak

  # Update or append ACR_NAME
  if grep -q "^ACR_NAME=" ../Jenkins.env; then
    sed -i "s/^ACR_NAME=.*/ACR_NAME=${ACR_NAME}/" ../Jenkins.env
  else
    echo "ACR_NAME=${ACR_NAME}" >> ../Jenkins.env
  fi

  # Update or append ACR_LOGIN_SERVER
  if grep -q "^ACR_LOGIN_SERVER=" ../Jenkins.env; then
    sed -i "s|^ACR_LOGIN_SERVER=.*|ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER}|" ../Jenkins.env
  else
    echo "ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER}" >> ../Jenkins.env
  fi

  echo "✅ Jenkins.env updated with ACR_NAME=${ACR_NAME} and ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER}"
fi
