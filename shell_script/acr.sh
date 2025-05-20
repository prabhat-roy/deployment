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

echo "📜 Converting ACR_REPOS to Terraform list..."
IFS=',' read -r -a repos_array <<< "$DOCKER_SERVICES"
terraform_list=$(printf '"%s", ' "${repos_array[@]}")
terraform_list="[${terraform_list%, }]"

echo "🛠️ Writing terraform.tfvars..."
cat > Terraform/Azure/ACR/terraform.tfvars <<EOF
acr_repo_names = ${terraform_list}
azure_region   = "${LOCATION}"
resource_group = "${RESOURCE_GROUP_NAME}"
EOF

echo "🚀 Running Terraform (${ACTION^^})..."
cd Terraform/Azure/ACR

terraform init -input=false
terraform plan

if [[ "$ACTION" == "create" ]]; then
  terraform apply -auto-approve

  # After creation, grab Terraform outputs
  ACR_NAME=$(terraform output -raw acr_name)
  ACR_LOGIN_SERVER=$(terraform output -raw acr_login_server)

  echo "📝 Updating Jenkins.env with ACR info..."

  # Update or add ACR_NAME
  if grep -q "^ACR_NAME=" ../../Jenkins.env; then
    sed -i "s/^ACR_NAME=.*/ACR_NAME=${ACR_NAME}/" ../../Jenkins.env
  else
    echo "ACR_NAME=${ACR_NAME}" >> ../../Jenkins.env
  fi

  # Update or add ACR_LOGIN_SERVER
  if grep -q "^ACR_LOGIN_SERVER=" ../../Jenkins.env; then
    sed -i "s/^ACR_LOGIN_SERVER=.*/ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER}/" ../../Jenkins.env
  else
    echo "ACR_LOGIN_SERVER=${ACR_LOGIN_SERVER}" >> ../../Jenkins.env
  fi

  echo "✅ Jenkins.env updated with ACR_NAME and ACR_LOGIN_SERVER."
  
elif [[ "$ACTION" == "destroy" ]]; then
  terraform destroy -auto-approve
fi
