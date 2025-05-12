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

echo "📜 Converting GAR_REPOS to Terraform list..."
IFS=',' read -r -a repos_array <<< "$SERVICES"
terraform_list=$(printf '"%s", ' "${repos_array[@]}")
terraform_list="[${terraform_list%, }]"

echo "🛠️ Writing terraform.tfvars..."
cat > Terraform/GCP/GAR/terraform.tfvars <<EOF
gar_repo_names = ${terraform_list}
gcp_region     = "${GCP_REGION}"
project_id     = "${GCP_PROJECT_ID}"
EOF

echo "🚀 Running Terraform (${ACTION^^})..."
cd Terraform/GCP/GAR

terraform init -input=false
terraform plan

if [[ "$ACTION" == "create" ]]; then
  terraform apply -auto-approve
elif [[ "$ACTION" == "destroy" ]]; then
  terraform destroy -auto-approve
fi
